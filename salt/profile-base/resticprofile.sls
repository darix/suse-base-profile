#!py

import os.path
from salt.exceptions import SaltConfigurationError

def is_local_repository(section_data):
  return 'repository' in section_data and (section_data['repository'].startswith('/') or section_data['repository'].startswith('local:/'))

# TODO: this should have a check if we have all parameters to actually schedule the job
def has_schedule(section_data):
  if 'backup' in section_data and 'schedule' in section_data['backup']:
    return True
  elif 'inherit' in section_data:
    return has_schedule(__pillar__['resticprofile']['config'][section_data['inherit']])
  else:
    return False

def requires_for_key_section_for_profile(section_name, section_data):
  if 'password-file' in section_data:
    return 'resticprofile_generate_key_{section_name}'
  elif 'inherit' in section_data:
    return requires_for_key_section_for_profile(section_data['inherit'], __pillar__['resticprofile']['config'][section_data['inherit']])
  else:
    raise SaltConfigurationError(f'Can not find password-file for section "{section_name}"')

def run():
  config={}

  config_filename = '/etc/resticprofile/profiles.yaml'

  if 'resticprofile' in __pillar__:

    scheduled_profiles      = __pillar__['resticprofile'].get('scheduled_profiles', [])
    initial_backup_profiles = __pillar__['resticprofile'].get('initial_backup_profiles', [])

    key_size = __pillar__['resticprofile'].get('key_size', 4096)

    pkgs = ['resticprofile', 'rclone']
    if 'SUSE' == __grains__['os']:
      pkgs.append('resticprofile-helpers')

      if 'config' in __pillar__['resticprofile'] and 'zypp' in __pillar__['resticprofile']['config']:
        pkgs.append('resticprofile-zypp-plugin')

    config['resticprofile_packages'] = {
      'pkg.installed': [
        {'pkgs': pkgs }
      ]
    }

    if 'config' in __pillar__['resticprofile']:
      requires = ['resticprofile_packages']
      config['resticprofile_config'] = {
        'file.serialize': [
          {'name': config_filename},
          {'user': 'root'},
          {'group': 'root'},
          {'mode': '0600'},
          {'require': requires },
          {'dataset': __pillar__['resticprofile']['config']},
          {'serializer': 'yaml'},
          {'serializer_opts': {'indent': 2}}
        ]
      }

      for section_name, section_data in __pillar__['resticprofile']['config'].items():
        cmdrun_genkey = 'resticprofile_generate_key_{section_name}'
        cmdrun_init_repository = f'resticprofile_init_repository_{section_name}'
        cmdrun_initial_backup = f'resticprofile_initial_backup_{section_name}'
        cmdrun_schedule = f'resticprofile_schedule_{section_name}'
        cmdrun_unschedule = f'resticprofile_unschedule_{section_name}'

        if 'password-file' in section_data:
          password_file = section_data['password-file']
          requires = ['resticprofile_config']

          config[cmdrun_genkey] = {
            'cmd.run': [
              {'name': f'resticprofile generate --random-key {key_size} > {password_file}'},
              {'creates': password_file},
              {'runas': 'root'},
              {'umask': '077'},
              {'require': requires },
            ]
          }

        if is_local_repository(section_data):

          repository = section_data['repository']
          if repository.startswith('local:'):
            repository = repository[6:]

          requires = [requires_for_key_section_for_profile(section_name, section_data)]

          config[cmdrun_init_repository] = {
            'cmd.run': [
              {'name': f'resticprofile {section_name}.init'},
              {'creates': f'{repository}/config' },
              {'runas': 'root'},
              {'umask': '077'},
              {'require': requires },
            ]
          }

        if section_name in scheduled_profiles and has_schedule(section_data):
          requires = [cmdrun_genkey]

          created_units = [
            f'/etc/systemd/system/resticprofile-backup@profile-{section_name}.timer',
            f'/etc/systemd/system/resticprofile-backup@profile-{section_name}.service',
          ]

          if is_local_repository(section_data):
            requires = [cmdrun_init_repository]

          if os.path.exists(created_units[0]) or os.path.exists(created_units[1]):
            config[cmdrun_unschedule] = {
              'cmd.run': [
                {'name': f'resticprofile {section_name}.unschedule'},
                {'runas': 'root'},
                {'umask': '077'},
                {'require': requires },
                {'onchanges': ['resticprofile_config']}
              ]
          }

          config[cmdrun_schedule] = {
            'cmd.run': [
              {'name': f'resticprofile {section_name}.schedule'},
              {'creates': created_units},
              {'runas': 'root'},
              {'umask': '077'},
              {'require': requires },
              {'onchanges': ['resticprofile_config']}
            ]
          }
        # TODO: does not work as expected - it always runs the backup
        # if section_name in initial_backup_profiles:
        #   requires = [cmdrun_genkey]

        #   if is_local_repository(section_data):
        #     requires = [cmdrun_init_repository]

        #   config[cmdrun_initial_backup] = {
        #     'cmd.run': [
        #       {'name': f'resticprofile {section_name}.backup'},
        #       {'runas': 'root'},
        #       {'umask': '077'},
        #       {'require': requires },
        #     ]
        #   }

  return config