#!py
#
# suse-base-profile
#
# Copyright (C) 2025   darix
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

import os
import pwd
import grp
from salt.exceptions import SaltConfigurationError

def run():
  config = {}
  if 'dotfiles' in __pillar__:
    dotfiles_pillar = __pillar__['dotfiles']
    for username, user_configs in dotfiles_pillar.get('users', {}).items():
      for relative_path, config_data in user_configs.items():
        try:
          primary_group = grp.getgrgid(pwd.getpwnam(username).pw_gid).gr_name
          absolute_path = os.path.expanduser(f'~{username}/{relative_path}')
          absolute_dir  = os.path.dirname(absolute_path)
          cleaned_relative_path = relative_path.replace('/', '_').replace('.', '_')
          state_name = f'dotfile_{username}_{cleaned_relative_path}'

          mode =    dotfiles_pillar.get('filemode', '0640')
          dirmode = dotfiles_pillar.get('dirmode', '0750')

          state_config = [
              {'name': absolute_path },
              {'makedirs': True},
            ]

          if isinstance(config_data, str):
            state_config.append({'user':     username})
            state_config.append({'group':    primary_group})
            state_config.append({'mode':     mode})
            state_config.append({'dirmode':  dirmode})
            state_config.append({'contents': config_data})
          elif isinstance(config_data, dict):
            handled_keys = []
            for k, v in config_data.items():
              handled_keys.append(k)
              state_config.append({k: v})
            if not('user' in handled_keys):
              state_config.append({'user':     username})
            if not('group' in handled_keys):
              state_config.append({'group':    primary_group})
            if not('mode' in handled_keys):
              state_config.append({'mode':     mode})
            if not('dirmode' in handled_keys):
              state_config.append({'dirmode':  dirmode})
          else:
            raise SaltConfigurationError(f"Do not know how to handle type {type(config_data)} for config_data")

          config[state_name] = { 'file.managed': state_config }
        except KeyError:
          pass

  return config