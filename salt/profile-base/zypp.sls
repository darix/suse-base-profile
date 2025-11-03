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
import logging
log = logging.getLogger("zyppify")

def repository_config(repo_id, repo_name, repo_url, refresh, gpgcheck, gpgkey=None):
  if gpgkey is None:
    gpgkey = __salt__['zypp_helper.repomd_key_url'](repo_url)

  ret = {
    "pkgrepo.managed": [
      {'name':      repo_id},
      {'humanname': repo_name},
      {'baseurl':   repo_url},
      {'gpgcheck':  1},
      {'refresh':   True},
    ]
  }

  if gpgkey:
    ret["pkgrepo.managed"].append({'gpgkey': gpgkey})

  return ret

def run():
  config = {}

  repository_states = []
  repositories = []

  baseurl = __salt__['pillar.get']('zypp:baseurl', f"https://download.{__salt__['grains.get']('domain')}")
  always_use_obs_instance = __salt__['pillar.get']('zypp:always_use_obs_instance', False)

  for filename, file_settings in __salt__["pillar.get"]("zypp:config", {}).items():
    cleaned_filename = filename.replace('.', '_')

    for setting, value in file_settings.items():
      cleaned_setting = setting.replace('.', '_')

      config_section = f"{cleaned_filename}_{cleaned_setting}"

      config[config_section] = {
        "file.replace": [
          {"name": f"/etc/zypp/{filename}"},
          {"pattern": f"^(# +)?{setting} =.*"},
          {"repl": f"{setting} = {value}"},
        ]
      }

  if __salt__["pillar.get"]("zypp:products_enable_openh264", True):
    repo_id = "repo-openh264"
    project_name = "Open H.264 Codec"
    codecs_baseurl = "https://codecs.opensuse.org/openh264"
    codecs_url = None

    if 'openSUSE Tumbleweed' == __salt__['grains.get']('osfullname'):
      codecs_url = f"{codecs_baseurl}/openSUSE_Tumbleweed/"

    elif __salt__['grains.get']('osfullname') in ["Leap", "SLES" ]:
      if __salt__['grains.get']('osmajorrelease', 0) >= 16:
        codecs_url = f"{codecs_baseurl}/openSUSE_Leap_16/"
      else:
        codecs_url = f"{codecs_baseurl}/openSUSE_Leap/"

    if codecs_url:
      repository_states.append(repo_id)
      repositories.append(repo_id)

      config[repo_id] = repository_config(repo_id, project_name, codecs_url, refresh=True, gpgcheck=1)

  for obs_instance, repositories_list in __salt__['pillar.get']('zypp:repositories',{}).items():
    if always_use_obs_instance:
      baseurl = f"{baseurl}/{obs_instance}"

    if "obs" == obs_instance:
      baseurl = f"{baseurl}/repositories"

    for repo_id, project_name in repositories_list.items():

      cleaned_repo_id = repo_id.replace(':','_')
      repository_states.append(cleaned_repo_id)
      repositories.append(repo_id)

      project_name_for_url = project_name.replace(':', ':/')
      repo_base_url        = f"{baseurl}/{project_name_for_url}/"
      repo_url             = __salt__['zypp_helper.guess_repository'](repo_base_url)

      config[cleaned_repo_id] = repository_config(repo_id, project_name, repo_url, refresh=True, gpgcheck=1)

  for repo_id, repodata in __salt__['pillar.get']('zypp:isv',{}).items():
    repository_states.append(repo_id)
    repositories.append(repo_id)
    config[repo_id] = repository_config(
      repo_id, repodata['name'], repodata['baseurl'],
      refresh=repodata.get('refresh', True),
      gpgcheck=repodata.get('gpgcheck', 1),
      gpgkey=repodata.get('gpgkey', None)
    )

  locked_packages = __salt__['pillar.get']('zypp:locks',[])
  if len(locked_packages) > 0:
    config_section = "zypp_lock_pkgs"
    repository_states.append(config_section)

    config[config_section] = {
      "pkg.held": [
        {'replace': True},
        {'pkgs': locked_packages }
      ]
    }

  config["zypper_refresh"] = {
    "cmd.run": [
      {'name': f"/usr/bin/zypper --non-interactive --gpg-auto-import-keys ref {' '.join(repositories)}"},
      {'onchanges': repository_states},
      {'require':   repository_states},
    ]
  }

  check_zypper_filename = ['/etc/monitoring-plugins/check_zypper-ignores.txt', '/etc/nagios/check_zypper-ignores.txt']
  if 'check_zypper' in __salt__['pillar.get']('zypp', {}):
    config["monitoring_check_zypper_dirs"] = {
      "file.directory": [
        {'user':  'root'},
        {'group': 'root'},
        {'mode':  '0755'},
        {'names': [os.path.dirname(f) for f in check_zypper_filename]},
      ]
    }

    check_zypper_template = [{'source': 'salt://profile-base/files/etc/monitoring-plugins/check_zypper-ignores.txt.j2'}]

    config["zypper_check_ignores"] = {
      'file.managed': [
        {'user': 'root'},
        {'group': 'root'},
        {'mode':  '0644'},
        {'template': 'jinja'},
        {'require': ["monitoring_check_zypper_dirs"]},
        {'names': [{f: check_zypper_template} for f in check_zypper_filename]},
      ]
    }
  else:
    for filename in check_zypper_filename:
      config[filename] = { "file.absent": []}

    for dirname in [os.path.dirname(f) for f in check_zypper_filename]:
      config[dirname] = {"file.absent": []}

  return config