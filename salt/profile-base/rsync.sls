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

def instance_service_state_name(instance_name):
  return f'rsyncd_service_{instance_name}'

def run():
  config = {}
  rsyncd_defaults  = __salt__['pillar.get']('rsync:defaults', {})
  rsyncd_modules   = __salt__['pillar.get']('rsync:modules', {})
  rsyncd_instances = __salt__['pillar.get']('rsync:instances', {})
  rsyncd_users     = __salt__['pillar.get']('rsync:users', {})
  rsyncd_use_service = __salt__['pillar.get']('rsync:use_service', True)

  rsyncd_has_modules   = len(rsyncd_modules) > 0
  rsyncd_has_instances = len(rsyncd_instances) > 0
  rsyncd_is_enabled    = __salt__['pillar.get']('rsync:enable', True) and (rsyncd_has_modules or rsyncd_has_instances)

  if rsyncd_is_enabled:
    config['rsyncd_packages'] = {
      'pkg.installed': [
        {'pkgs': ['rsync']},
      ]
    }

    config_names = []
    secret_names = []

    if rsyncd_has_modules:
      config_names.append({
        '/etc/rsyncd.conf': [
          { 'context': {
              'rsync_pillar_defaults': rsyncd_defaults,
              'rsync_pillar_modules': rsyncd_modules,
            }
          },
          {'require_in': ['rsyncd_service']},
          {'watch_in':   ['rsyncd_service']},
        ]
      })

    if len(rsyncd_users) > 0:
      secret_names.append({
        '/etc/rsyncd.secrets': [
          { 'context': {
              'rsync_pillar_users': rsyncd_users,
            }
          },
          {'require_in': ['rsyncd_service']},
          {'watch_in':   ['rsyncd_service']},
        ]
      })

    for instance_name, instance_config in rsyncd_instances.items():
      config_filename = f"/etc/rsyncd-{instance_name}.conf"
      secrets_filename = f"/etc/rsyncd-{instance_name}.secrets"
      instance_defaults = instance_config.get('defaults', rsyncd_defaults)
      instance_modules  = instance_config.get('modules', {})
      instance_users    = instance_config.get('users', {})

      instance_service_state = instance_service_state_name(instance_name)

      if len(instance_modules) > 0:
        config_names.append({
          config_filename: [
            {'context': {
                'rsync_pillar_defaults': instance_defaults,
                'rsync_pillar_modules': instance_modules,
              },
            },
            {'require_in': [instance_service_state]},
            {'watch_in':   [instance_service_state]},
          ]
        })

      if len(instance_users) > 0:
        secret_names.append({
         secrets_filename: [
            {'context': {
                'rsync_pillar_users': instance_users,
              },
            },
            {'require_in': [instance_service_state]},
            {'watch_in':   [instance_service_state]},
          ]
        })

    if len(config_names) > 0:
      config['rsyncd_config'] = {
        'file.managed': [
          {'user': 'root'},
          {'group': 'root'},
          {'mode': '0644'},
          {'template': 'jinja'},
          {'requires': ['rsyncd_packages']},
          {'source': 'salt://profile-base/files/etc/rsyncd.conf.j2'},
          {'names': config_names},
        ]
      }

    if len(secret_names) > 0:
      config['rsyncd_secrets'] = {
        'file.managed': [
          {'user': 'root'},
          {'group': 'root'},
          {'mode': '0600'},
          {'template': 'jinja'},
          {'requires': ['rsyncd_packages']},
          {'source': 'salt://profile-base/files/etc/rsyncd.secrets.j2'},
          {'names': secret_names},
        ]
      }

    if rsyncd_use_service:
      config['rsyncd_service'] = {
        'service.running': [
          {'name': 'rsyncd.service'},
          {'enable': True},
        ]
      }

      for instance_name, instance_config in rsyncd_instances.items():
        instance_service_state = instance_service_state_name(instance_name)
        if instance_config.get('use_service', rsyncd_use_service):
          config[instance_service_state] = {
            'service.running': [
              {'name': f'rsyncd@{instance_name}.service'},
              {'enable': True},
            ]
          }
        else:
          config[instance_service_state] = {
            'service.dead': [
              {'name': f'rsyncd@{instance_name}.service'},
              {'enable': False},
            ]
          }
    else:
      config['rsyncd_service'] = {
        'service.dead': [
          {'name': 'rsyncd.service'},
          {'enable': False},
        ]
      }
      config['rsyncd_socket'] = {
        'service.dead': [
          {'name': 'rsyncd.socket'},
          {'enable': False},
        ]
      }
      for instance_name, instance_config in rsyncd_instances.items():
        instance_service_state = instance_service_state_name(instance_name)
        config[instance_service_state] = {
          'service.dead': [
            {'name': f'rsyncd@{instance_name}.service'},
            {'enable': False},
          ]
        }

  return config
