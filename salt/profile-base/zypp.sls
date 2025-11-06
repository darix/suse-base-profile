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


from salt.exceptions import SaltRenderError
import os
import requests
import logging

log = logging.getLogger("zyppify")

class ZyppConfigurator:
  def __init__(self):
    self.config = {}

    self.repo_tracker = {}

    self.baseurl                 = __salt__['pillar.get']('zypp:baseurl', f"https://download.{__salt__['grains.get']('domain')}")
    self.always_use_obs_instance = __salt__['pillar.get']('zypp:always_use_obs_instance', False)
    self.enable_non_oss          = __salt__['pillar.get']('zypp:enable_non_oss', False)
    self.enable_debug            = __salt__['pillar.get']('zypp:enable_debug', False)
    self.enable_source           = __salt__['pillar.get']('zypp:enable_source', False)
    self.purge_untracked         = __salt__['pillar.get']('zypp:purge_untracked_repositories', True)
    self.enable_openh264         = __salt__["pillar.get"]("zypp:products_enable_openh264", False)

    for filename, file_settings in __salt__["pillar.get"]("zypp:config", {}).items():
      cleaned_filename = filename.replace('.', '_')

      for setting, value in file_settings.items():
        cleaned_setting = setting.replace('.', '_')

        config_section = f"{cleaned_filename}_{cleaned_setting}"

        self.config[config_section] = {
          "file.replace": [
            {"name": f"/etc/zypp/{filename}"},
            {"pattern": f"^(# +)?{setting} =.*"},
            {"repl": f"{setting} = {value}"},
          ]
        }

    match __salt__['grains.get']('osfullname'):
      case 'openSUSE Tumbleweed':
        if self.always_use_obs_instance:
          baseurl = f"{self.baseurl}/obs"
        else:
          baseurl = self.baseurl

        dist_repositories     = ['oss']
        dist_only_has_updates = []

        if self.enable_non_oss:
          dist_repositories.append('non-oss')

        distro_basedir = 'tumbleweed'
        update_basedir = 'tumbleweed'
        update_for_baserepo = True

        for dist_repo in dist_repositories:
          repo_id        = f"repo-{dist_repo}"
          update_repo_id = f"{repo_id}-update"
          debug_repo_id  = f"{repo_id}-debug"
          source_repo_id = f"{repo_id}-source"
          update_dir     = update_basedir

          if dist_repo == "non-oss":
            update_dir     = f"{update_basedir}-{dist_repo}"
          self.configure_repository(state_name=repo_id, repo_id=repo_id, repo_name=repo_id, repo_url=f"{baseurl}/{distro_basedir}/repo/{dist_repo}/")
          self.configure_repository(state_name=update_repo_id, repo_id=update_repo_id, repo_name=repo_id, repo_url=f"{baseurl}/update/{update_dir}/")

          if 'oss' == dist_repo and self.enable_debug:
            self.configure_repository(state_name=debug_repo_id, repo_id=debug_repo_id, repo_name=repo_id, repo_url=f"{baseurl}/debug/{distro_basedir}/repo/{dist_repo}/")
          else:
            self.purge_repository(state_name=debug_repo_id, repo_id=debug_repo_id)

          if 'oss' == dist_repo and self.enable_source:
            self.configure_repository(state_name=source_repo_id, repo_id=source_repo_id, repo_name=repo_id, repo_url=f"{baseurl}/source/{distro_basedir}/repo/{dist_repo}/")
          else:
            self.purge_repository(state_name=source_repo_id, repo_id=source_repo_id)


      case 'SLES':
        products_enable_debug     = __salt__['pillar.get']('zypp:products_enable_debug', False)
        products_enable_backports = __salt__['pillar.get']('zypp:products_enable_backports', False)

        if self.always_use_obs_instance:
          baseurl = f"{self.baseurl}/ibs"
        else:
          baseurl = self.baseurl

        osrelease_info = __salt__['grains.get']('osrelease_info', 0)
        osmajorrelease = __salt__['grains.get']('osmajorrelease', 0)
        osarch         = __salt__['grains.get']('osarch')
        osrelease      = __salt__['grains.get']('osrelease', 0)

        if len(osrelease_info) > 1:
          product_release =     f"{osrelease_info[0]}-SP{osrelease_info[1]}"
          repo_name       = f"SLE_{osrelease_info[0]}_SP{osrelease_info[1]}"
        else:
          product_release =     f"{osrelease_info[0]}"
          repo_name       = f"SLE_{osrelease_info[0]}"



        match __salt__['grains.get']('osmajorrelease', 0):
          case 16:
            for product_name in __salt__['grains.get'](f"zypp:products:{osmajorrelease}", ["SLE-Product-SLES"]):
              repo_baseurl = f"{baseurl}/SUSE/Products/{product_name}/{osrelease}/{osarch}/product"
              self.configure_repository(state_name=product_name, repo_id=product_name, repo_name=product_name, repo_url=f"{repo_baseurl}/")

              if self.enable_debug:
                debug_repo_id = f"{repo_id}-debug"
                self.configure_repository(state_name=debug_repo_id, repo_id=debug_repo_id, repo_name=debug_repo_id, repo_url=f"{repo_baseurl}_debug/")
              if self.enable_source:
                source_repo_id = f"{repo_id}-source"
                self.configure_repository(state_name=source_repo_id, repo_id=source_repo_id, repo_name=source_repo_id, repo_url=f"{repo_baseurl}_source/")

            if products_enable_backports:
              backports_repo_id =  "Backports"
              backports_repo_baseurl = f"{baseurl}/SUSE/Backports/SLE-{osrelease}_{osarch}/standard"
              self.configure_repository(state_name=backports_repo_id, repo_id=backports_repo_id, repo_name=backports_repo_id, repo_url=f"{backports_repo_baseurl}/")

              packageup_repo_id = "PackageHub"
              packagehub_repo_baseurl = f"{baseurl}/SUSE/Products/PackageHub/{osrelease}/{osarch}/product"
              self.configure_repository(state_name=packageup_repo_id, repo_id=packageup_repo_id, repo_name=packageup_repo_id, repo_url=f"{packagehub_repo_baseurl}/")

              if self.enable_debug:
                backports_debug_repo_id = f"{backports_repo_id}-debug"
                self.configure_repository(state_name=backports_debug_repo_id, repo_id=backports_debug_repo_id, repo_name=backports_debug_repo_id, repo_url=f"{backports_repo_baseurl}_debug/")

                packagehub_debug_repo_id = f"{packagehub_repo_id}-debug"
                self.configure_repository(state_name=packagehub_debug_repo_id, repo_id=packagehub_debug_repo_id, repo_name=packagehub_debug_repo_id, repo_url=f"{packagehub_repo_baseurl}_debug/")

              if self.enable_source:
                backport_source_repo_id = f"{backports_repo_id}-source"
                self.configure_repository(state_name=backport_source_repo_id, repo_id=backport_source_repo_id, repo_name=backport_source_repo_id, repo_url=f"{backports_repo_baseurl}_source/")

                packagehub_source_repo_id = f"{packagehub_repo_id}-source"
                self.configure_repository(state_name=packagehub_source_repo_id, repo_id=packagehub_source_repo_id, repo_name=packagehub_source_repo_id, repo_url=f"{packagehub_repo_baseurl}_source/")
          case 15:
            repo_types = [ 'Product', 'Update' ]
            for product_name in __salt__['pillar.get'](f"zypp:products:{osmajorrelease}", ["SLE-Product-SLES", "SLE-Module-Basesystem"]):
              for repo_type in repo_types:
                do_refresh = (repo_type == "Update")
                repo_id = f"{product_name}-{repo_type}"
                self.configure_repository(state_name=repo_id, repo_id=repo_id, repo_name=repo_id, repo_url=f"{baseurl}/SUSE/{repo_type}s/{product_name}/{product_release}/{osarch}/{repo_type.lower()}/", refresh=do_refresh)
                if products_enable_debug:
                  debug_repo_id = f"{repo_id}_debug"
                  self.configure_repository(state_name=repo_id, repo_id=repo_id, repo_name=repo_id, repo_url=f"{baseurl}/SUSE/{repo_type}s/{product_name}/{product_release}/{osarch}/{repo_type.lower()}_debug/", refresh=do_refresh)
            if products_enable_backports:
              repo_id =  "Packagehub"
              self.configure_repository(state_name=repo_id, repo_id=repo_id, repo_name=repo_id, repo_url=f"{baseurl}/SUSE/Backports/SLE-{product_release}_{grains.osarch}/standard/")
          case _:
            raise SaltRenderError(f"No handling yet for {__salt__['grains.get']('osfullname')} {__salt__['grains.get']('osmajorrelease', 0)}")

      case 'Leap':
        if self.always_use_obs_instance:
          baseurl = f"{self.baseurl}/obs"
        else:
          baseurl = self.baseurl

        dist_repositories     = ['oss']

        if self.enable_non_oss:
          dist_repositories.append('non-oss')

        distro_basedir = f"distribution/leap/{__salt__['grains.get']('osrelease')}"
        update_basedir = f"leap/{__salt__['grains.get']('osrelease')}"

        match __salt__['grains.get']('osmajorrelease', 0):
          case 16:
            for dist_repo in dist_repositories:
              repo_id        = f"repo-{dist_repo}"
              debug_repo_id  = f"{repo_id}-debug"
              source_repo_id = f"{repo_id}-source"

              self.configure_repository(state_name=repo_id, repo_id=repo_id, repo_name=repo_id, repo_url=f"{baseurl}/{distro_basedir}/repo/{dist_repo}/")

              if dist_repo in ["oss", "non-oss"] and self.enable_debug:
                self.configure_repository(state_name=debug_repo_id, repo_id=debug_repo_id, repo_name=debug_repo_id, repo_url=f"{baseurl}/debug/{distro_basedir}/repo/{dist_repo}/", refresh=False)
              else:
                self.purge_repository(state_name=debug_repo_id, repo_id=debug_repo_id)

              if dist_repo == "oss" and self.enable_source:
                self.configure_repository(state_name=source_repo_id, repo_id=source_repo_id, repo_name=repo_id, repo_url=f"{baseurl}/source/{distro_basedir}/repo/{dist_repo}/")
              else:
                self.purge_repository(state_name=source_repo_id, repo_id=source_repo_id)
          case 15:
            dist_only_has_updates = ['backports', 'sle']
            dist_repositories.extend(dist_only_has_updates)

            for dist_repo in dist_repositories:
              repo_id        = f"repo-{dist_repo}"
              update_repo_id = f"{repo_id}-update"
              debug_repo_id  = f"{repo_id}-debug"
              debug_update_repo_id = f"{repo_id}-update-debug"
              source_repo_id = f"{repo_id}-source"
              update_dir     = update_basedir

              if dist_repo == "non-oss":
                update_dir     = f"{update_basedir}-{dist_repo}"

              if not(dist_repo in dist_only_has_updates):
                self.configure_repository(state_name=repo_id, repo_id=repo_id, repo_name=repo_id, repo_url=f"{baseurl}/{distro_basedir}/repo/{dist_repo}/", refresh=False)
              self.configure_repository(state_name=update_repo_id, repo_id=update_repo_id, repo_name=update_repo_id, repo_url=f"{baseurl}/update/{update_dir}/{dist_repo}/")

              if dist_repo in ["oss", "non-oss"] and self.enable_debug:
                self.configure_repository(state_name=debug_repo_id, repo_id=debug_repo_id, repo_name=debug_repo_id, repo_url=f"{baseurl}/debug/{distro_basedir}/repo/{dist_repo}/", refresh=False)
              else:
                self.purge_repository(state_name=debug_repo_id, repo_id=debug_repo_id)

              if dist_repo != 'sle' and self.enable_debug:
                self.configure_repository(state_name=debug_update_repo_id, repo_id=debug_update_repo_id, repo_name=debug_update_repo_id, repo_url=f"{baseurl}/update/{update_dir}/{dist_repo}_debug/")
              else:
                self.purge_repository(state_name=debug_update_repo_id, repo_id=debug_update_repo_id)

              if dist_repo in ["oss", "non-oss"] and self.enable_source:
                self.configure_repository(state_name=source_repo_id, repo_id=source_repo_id, repo_name=repo_id, repo_url=f"{baseurl}/source/{distro_basedir}/repo/{dist_repo}/")
              else:
                self.purge_repository(state_name=source_repo_id, repo_id=source_repo_id)
          case _:
            raise SaltRenderError(f"No handling yet for {__salt__['grains.get']('osfullname')} {__salt__['grains.get']('osmajorrelease', 0)}")
      case _:
        raise SaltRenderError(f"No handling yet for {__salt__['grains.get']('osfullname')}")

    if self.enable_openh264:
      repo_id = "repo-openh264"
      project_name = "Open H.264 Codec"
      codecs_baseurl = "https://codecs.opensuse.org/openh264"
      codecs_url = None

      if 'openSUSE Tumbleweed' == __salt__['grains.get']('osfullname'):
        codecs_url = f"{codecs_baseurl}/openSUSE_Tumbleweed"

      elif __salt__['grains.get']('osfullname') in ["Leap", "SLES" ]:
        if __salt__['grains.get']('osmajorrelease', 0) >= 16:
          codecs_url = f"{codecs_baseurl}/openSUSE_Leap_16"
        else:
          codecs_url = f"{codecs_baseurl}/openSUSE_Leap"

      if codecs_url:

        self.configure_repository(state_name=repo_id, repo_id=repo_id, repo_name=project_name, repo_url=codecs_url)

    for obs_instance, repositories_list in __salt__['pillar.get']('zypp:repositories',{}).items():
      if self.always_use_obs_instance:
        self.baseurl = f"{self.baseurl}/{obs_instance}"

      if "obs" == obs_instance:
        self.baseurl = f"{self.baseurl}/repositories"

      for repo_id, project_name in repositories_list.items():

        cleaned_repo_id = repo_id.replace(':','_')


        project_name_for_url = project_name.replace(':', ':/')
        repo_base_url        = f"{self.baseurl}/{project_name_for_url}/"
        repo_url             = self.guess_repository(repo_base_url)
        self.configure_repository(state_name=cleaned_repo_id, repo_id=repo_id, repo_name=project_name, repo_url=repo_url)

    for repo_id, repodata in __salt__['pillar.get']('zypp:isv',{}).items():
      self.configure_repository(state_name=repo_id, repo_id=repo_id, repo_name=repodata['name'],
        repo_url=repodata['baseurl'],
        refresh=repodata.get('refresh', True),
        gpgcheck=repodata.get('gpgcheck', 1),
        gpgkey=repodata.get('gpgkey', None)
      )

    if self.purge_untracked:
      repos_on_system = [f.replace('.repo', '') for f in os.listdir("/etc/zypp/repos.d")]
      bad_repositories = [r for r in repos_on_system if not(r in self.repo_tracker.values())]
      for repo in bad_repositories:
        repo_id = f"zypp_purge_repo_{repo}"
        self.purge_repository(state_name=repo_id, repo_id=repo, additional_fields=[{'require_in': list(self.repo_tracker.keys())}])

    all_services = [f.replace('.service', '') for f in os.listdir("/etc/zypp/services.d")]
    if len(all_services) > 0:
      self.config["zypper_disable_services"] = {
        "cmd.run": [
          {"name": f"/usr/bin/zypper modifyservice --disable {' '.join(all_services)}"},
          {'require_in': list(self.repo_tracker.keys())},
          {'require': ["zypper_remove_service_package"]}
        ]
      }

    base_service_package = f"openSUSE-repos-{__salt__['grains.get']('osfullname')}"
    self.config["zypper_remove_service_package"] = {
      "pkg.purged": [
        {'pkgs': [ base_service_package, f"{base_service_package}-NVIDIA", ]},
      ]
    }

    locked_packages = __salt__['pillar.get']('zypp:locks',[])
    if len(locked_packages) > 0:
      config_section = "zypp_lock_pkgs"

      self.config[config_section] = {
        "pkg.held": [
          {'replace': True},
          {'pkgs': locked_packages }
        ]
      }

    refresh_deps = list(self.repo_tracker.keys())
    self.config["zypper_refresh"] = {
      "cmd.run": [
        {'name': f"/usr/bin/zypper --non-interactive --gpg-auto-import-keys ref {' '.join(self.repo_tracker.values())}"},
        {'onchanges': refresh_deps},
        {'require':   refresh_deps},
      ]
    }

    check_zypper_filename = ['/etc/monitoring-plugins/check_zypper-ignores.txt', '/etc/nagios/check_zypper-ignores.txt']
    if 'check_zypper' in __salt__['pillar.get']('zypp', {}):
      self.config["monitoring_check_zypper_dirs"] = {
        "file.directory": [
          {'user':  'root'},
          {'group': 'root'},
          {'mode':  '0755'},
          {'names': [os.path.dirname(f) for f in check_zypper_filename]},
        ]
      }

      check_zypper_template = [{'source': 'salt://profile-base/files/etc/monitoring-plugins/check_zypper-ignores.txt.j2'}]

      self.config["zypper_check_ignores"] = {
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
        self.config[filename] = { "file.absent": []}

      for dirname in [os.path.dirname(f) for f in check_zypper_filename]:
        self.config[dirname] = {"file.absent": []}


  def configure_repository(self, state_name, repo_id, repo_name, repo_url, refresh=True, gpgcheck=True, gpgkey=None, additional_fields=[]):
    if gpgkey is None:
      gpgkey = self.repomd_key_url(repo_url)

    ret = [
      {'name':      repo_id},
      {'humanname': repo_name},
      {'baseurl':   repo_url},
      {'enabled':   True},
      {'gpgcheck':  gpgcheck},
      {'refresh':   refresh},
    ]

    if gpgkey:
      ret.append({'gpgkey': gpgkey})

    ret.extend(additional_fields)

    self.repo_tracker[state_name] = repo_id
    self.config[state_name] = {"pkgrepo.managed": ret}

  def purge_repository(self, state_name, repo_id, additional_fields=[]):
    fields = [
        {"name": repo_id}
      ]
    fields.extend(additional_fields)

    self.config[state_name] = ret = {"pkgrepo.absent": fields }

  def repomd_key_url(self, baseurl):
      if not(baseurl.endswith('/')):
          baseurl = f"{baseurl}/"
      repomd_key_path = 'repodata/repomd.xml.key'
      repomd_url = f"{baseurl}{repomd_key_path}"
      result = requests.head(repomd_url)
      log.info(f"Querying {repomd_url} resulted in {result.status_code}")
      if result.status_code in [200, 302, 301]:
          return repomd_url

  def guess_repository(self, baseurl):
      repository_list = []

      osrelease_info = __salt__['grains.get']('osrelease_info')

      major_version = osrelease_info[0]
      if len(osrelease_info) > 1:
          minor_version = osrelease_info[1]
      else:
          minor_version = 0
      osfullname = __salt__['grains.get']('osfullname')
      if osfullname == "SLES":
          if len(osrelease_info) > 1:
              repository_list.append("SLE_{major_version}_SP{minor_version}".format(major_version=major_version, minor_version=minor_version))
          else:
              repository_list.append("SLE_{major_version}".format(major_version=major_version))
          repository_list.append("{major_version}.{minor_version}".format(major_version=major_version, minor_version=minor_version))
      elif osfullname == "Leap":
          repository_list.append("{major_version}.{minor_version}".format(major_version=major_version, minor_version=minor_version))
          repository_list.append("openSUSE_Leap_{major_version}.{minor_version}".format(major_version=major_version, minor_version=minor_version))
          if len(osrelease_info) > 1:
              repository_list.append("SLE_{major_version}_SP{minor_version}".format(major_version=major_version, minor_version=minor_version))
          else:
              repository_list.append("SLE_{major_version}".format(major_version=major_version))
      elif osfullname == 'openSUSE Tumbleweed':
          repository_list.append("openSUSE_Tumbleweed")
          repository_list.append("openSUSE_Factory")
      else:
          log.error("Do not know how to handle distro {distro}".format(distro=osfullname))

      repomd_path = 'repodata/repomd.xml'

      log.debug("osrelease_info: {osrelease_info} osfullname: {osfullname} repository list: {repository_list}".format(osfullname=osfullname, osrelease_info=osrelease_info, repository_list=repository_list))

      for repository in repository_list:
          repo_url = baseurl + repository + "/"
          full_url = repo_url + repomd_path
          log.debug("Testing {full_url}".format(full_url=full_url))
          result = requests.head(full_url)
          if result.status_code in [200, 302, 301]:
              return repo_url
          log.info("Querying {full_url} resulted in {status_code}".format(full_url=full_url, status_code=result.status_code))

      error_message = "No valid repository found for baseurl: {baseurl} repository list: {repository_list} osrelease_info: {osrelease_info} osfullname: {osfullname}".format(baseurl=baseurl, osfullname=osfullname, osrelease_info=osrelease_info, repository_list=repository_list)

      log.error(error_message)
      raise SaltRenderError(error_message)

def run():
  return ZyppConfigurator().config