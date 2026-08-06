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


def run():
  config = {}
  check_script_lines = __salt__['pillar.get']('healthcheck_script', [])
  filename = '/root/bin/ishappy'

  if len(check_script_lines) > 0:
    if isinstance(check_script_lines):
      check_script_lines = "\n".join(check_script_lines)

    config[f'healthcheck_script'] = {
      'file.managed': [
        {'name': filename},
        {'user': 'root'},
        {'group': 'root'},
        {'mode': '0755'},
        {'contents': check_script_lines}
      ]
    }
  else:
    config[f'healthcheck_script'] = {
      'file.absent': [
        {'name': filename},
      ]
    }

  return config
