#!py
import salt.utils  as su
import salt.config as sc
from salt.exceptions import SaltRenderError

def run():
  config = {}

  # tgt      = 'I@roles:patroni'
  tgt = __salt__['pillar.get']('matches', None)
  tgt_type = 'compound'
  tgt_type_post_resolve = 'glob'

  state_up_wait_timeout = __salt__['pillar.get']('state_up_wait_timeout', 300)

  if tgt is None:
    raise SaltRenderError(f"the matches entry in the pillar can not be None")

  if isinstance(tgt, list):
    hosts = tgt
  else:
    opts  = sc.client_config('/etc/salt/master')
    check_hosts = su.minions.CkMinions(opts).check_minions(tgt, tgt_type)
    if 'minions' in check_hosts:
      hosts = check_hosts['minions']
    else:
      raise SaltRenderError(f"Could not match anything with tgt:{tgt} tgt_type:{tgt_type} => {check_hosts}")

  previous_host = None

  for host in hosts:
    reboot_state      = f"reboot_minion_{host}"
    wait_up_state     = f"wait_for_up_{host}"
    wait_health_state = f"wait_for_healthy_{host}"

    reboot_deps = []

    if not(previous_host is None):
      reboot_deps = [f"wait_for_healthy_{previous_host}"]

    previous_host = host

    reboot_condition = '/usr/bin/needs-restarting --reboothint'

    config[reboot_state] = {
      'salt.function': [
        {'name': 'system.reboot'},
        {'tgt_type': tgt_type_post_resolve},
        {'tgt': host},
        {'require': reboot_deps},
        {'require_in': [wait_up_state]},
        # {'onlyif': reboot_condition},
      ]
    }

    config[wait_up_state] = {
      'salt.wait_for_event': [
        {'name': 'salt/minion/*/start'},
        {'timeout': state_up_wait_timeout},
        {'id_list': [host]},
        # {'onlyif': reboot_condition},
        # {'require': [reboot_state]},
        {'require_in': [wait_health_state]},
      ]
    }

    commands = [
      '/root/bin/ishappy',
    ]
    config[wait_health_state] = {
      'salt.function': [
        {'name': 'cmd.run'},
        {'arg':  commands},
        {'tgt': host},
        {'tgt_type': tgt_type_post_resolve},
      ]
    }

    # config[wait_health_state] = {
    #   'salt.wait_for_event': [
    #     {'name': 'salt/minion/*/healthy'},
    #     {'timeout': 30},
    #     {'id_list': [host]},
    #     {'require': [reboot_state]},
    #   ]
    # }

  return config
