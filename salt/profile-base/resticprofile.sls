#!py
from salt.utils.yamldumper import safe_dump

def run():
  config={}

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
          {'name': '/etc/resticprofile/profile.yaml'},
          {'user': 'root'},
          {'group': 'root'},
          {'mode': '0600'},
          {'require': requires },
          {'contents': safe_dump(__pillar__['resticprofile']['config'])},
        ]
      }

      for section_name, section_data in __pillar__['resticprofile']['config'].items():
        if 'password-file' in section_data:
          cmdrun_section = 'resticprofile_generate_key_' + section_name
          password_file = section_data['password-file']
          requires = ['resticprofile_config']

          config[cmdrun_section] = {
            'cmd.run': [
              {'name': 'resticprofile generate --random-key 4096 > ' + password_file},
              {'creates': password_file},
              {'runas': 'root'},
              {'umask': '077'},
              {'require': requires },
            ]
          }

  return config