#!py
#
# suse-base-profile
#
# Copyright (C) 2026   darix
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
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
  health_check_command  = __salt__['pillar.get']('health_check_command', ['/root/bin/ishappy'])

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

  config[wait_health_state] = {
    'salt.function': [
      {'name': 'cmd.run'},
      {'arg':  health_check_command},
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
