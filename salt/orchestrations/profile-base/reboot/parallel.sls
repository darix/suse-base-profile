#!py
import salt.utils  as su
import salt.config as sc
from salt.exceptions import SaltRenderError

def run():
  config = {}

  # tgt      = 'I@roles:patroni'
  tgt = __salt__['pillar.get']('matches', None)
  tgt_type = 'compound'
  tgt_type_post_resolve = "list"

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

  reboot_state      = f"reboot_minion_all"
  wait_up_state     = f"wait_for_up_all"
  wait_health_state = f"wait_for_healthy_all"

  config[reboot_state] = {
    'salt.function': [
      {'name': 'system.reboot'},
      {'tgt_type': tgt_type_post_resolve},
      {'tgt': hosts},
      {'require_in': [wait_up_state]},
    ]
  }

  config[wait_up_state] = {
    'salt.wait_for_event': [
      {'name': 'salt/minion/*/start'},
      {'timeout': state_up_wait_timeout},
      {'id_list': hosts},
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
      {'tgt': hosts},
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
