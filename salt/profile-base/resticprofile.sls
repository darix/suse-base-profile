#!py
from salt.utils.yamldumper import safe_dump

def run():
  config={}

  config_filename = '/etc/resticprofile/profile.yaml'

  if 'resticprofile' in __pillar__:
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
        'file.managed': [
          {'name': config_filename},
          {'user': 'root'},
          {'group': 'root'},
          {'mode': '0600'},
          {'require': requires },
          {'contents': safe_dump(__pillar__['resticprofile']['config'])},
        ]
      }

      for section_name, section_data in __pillar__['resticprofile']['config'].items():
        cmdrun_genkey = 'resticprofile_generate_key_{section_name}'

        if 'password-file' in section_data:
          password_file = section_data['password-file']
          requires = ['resticprofile_config']

          config[cmdrun_genkey] = {
            'cmd.run': [
              {'name': f'resticprofile generate --random-key 4096 > {password_file}'},
              {'creates': password_file},
              {'runas': 'root'},
              {'umask': '077'},
              {'require': requires },
            ]
          }

        if 'repository' in section_data and (section_data['repository'].startswith('/') or section_data['repository'].startswith('local:/')):

          cmdrun_init_repository = f'resticprofile_init_repository_{section_name}'
          repository = section_data['repository']
          if repository.startswith('local:'):
            repository = repository[6:]

          requires = [cmdrun_genkey]

          config[cmdrun_init_repository] = {
            'cmd.run': [
              {'name': f'resticprofile --config={config_filename} {section_name}.init'},
              {'creates': f'{repository}/config' },
              {'runas': 'root'},
              {'umask': '077'},
              {'require': requires },
            ]
          }


  return config