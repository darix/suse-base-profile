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
# modules:
#   modprobe:
#   - "install algif_aead /bin/false"
#   - "install af_alg     /bin/false"
#   modules_blocked:
#   - algif_aead
#   modules_load:
#   - ntsync
#

def list_or_string(dataset):
  if isinstance(dataset, list):
    return "\n".join(dataset)
  return dataset

def remove_module(config, module_name):
  config[f"remove_module_{module_name}"] = {
    "cmd.run": [
      {'name':   f"rmmod {module_name}"},
      {'onlyif': f"lsmod | grep -q '^{module_name}'"},
    ]
  }

def run():
  config = {}
  modprobe_filename     = '/etc/modprobe.d/99-salt.conf'
  modules_load_filename = '/etc/modules-load.d/99-salt.conf'

  modprobe_config        = __salt__['pillar.get']('modules:modprobe',     [])
  modules_load_config    = __salt__['pillar.get']('modules:modules_load', [])
  modules_blocked_config = __salt__['pillar.get']('modules:modules_blocked', [])
  shared_settings = [
      {'user':  'root'},
      {'group': 'root'},
      {'mode':  '0644'},
  ]

  names_list = []

  if len(modules_blocked_config) > 0:
    if isinstance(modprobe_config, str):
      modprobe_config = modprobe_config.split("\n")

    for module in modules_blocked_config:
      modprobe_config.append(f"install {module} /bin/false")
      remove_module(config, module)

  if len(modprobe_config) > 0:
    names_list.append({modprobe_filename: [{'contents': list_or_string(modprobe_config)}]})
  else:
    config["cleanup_modprobe"] = {
      "file.absent": [
        {'name': modprobe_filename}
      ]
    }

  if len(modules_load_config) > 0:
    names_list.append({modules_load_filename: [{'contents': list_or_string(modules_load_config)}]})
  else:
    config["cleanup_modules_load"] = {
      "file.absent": [
        {'name': modules_load_filename}
      ]
    }

  if len(names_list) > 0:
    shared_settings.append({'names': names_list})
    config["modules_config"] = {
      'file.managed': shared_settings
    }

  return config