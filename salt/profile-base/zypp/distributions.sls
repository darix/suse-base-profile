#!py
from salt.exceptions import SaltConfigurationError
import os.path

import logging

log = logging.getLogger(__name__)

class DistributionRepositories:
    def __init__(self, obs_instance="obs", enabled_repositories={}, disabled_repositories={}):
      self.config = {}

      self.obs_instance = obs_instance
      self.zypp_pillar = __pillar__['zypp']

      if not('domain' in __grains__):
         raise SaltConfigurationError('Domain grain not set')

      domain = __grains__.get("domain", None)

      if (domain == None or domain == ''):
        raise SaltConfigurationError('Domain grain empty?')

      self.baseurl = self.zypp_pillar.get('baseurl', f'http://download.{domain}')

      if self.zypp_pillar.get('always_use_obs_instance', False):
        self.baseurl = f"{baseurl}/{obs_instance}"

      self.enabled_repositories  = enabled_repositories
      self.disabled_repositories = disabled_repositories


    def repositories(self):
      for repo_id, repo_data in self.disabled_repositories.items():
        log.error(f"handling disabled repository {repo_id}")
        full_repo_id = f"remove_{repo_id}"
        self.config[full_repo_id] = {
          "pkgrepo.absent": [
            {'name': repo_data['name']},
          ]
        }

      for repo_id, repo_data in self.enabled_repositories.items():
        log.error(f"handling enabled repository {repo_id}")
        self.config[repo_id] = {
          "pkgrepo.managed": [
            {'name':      repo_data['name'] },
            {'humanname': repo_data['name'] },
            {'baseurl':   os.path.join(self.baseurl, repo_data['repository_path']) },
            {'enabled':   repo_data['enabled']},
            {'gpgcheck',  True},
            {'refresh',   repo_data['refresh']},
          ]
        }

      repository_ids = list(self.enabled_repositories.keys())
      repository_ids_string = ' '.join(repository_ids)

      self.config['refresh_distribution_repositories'] = {
        'cmd.run': [
          {'name':      '/usr/bin/zypper --non-interactive --gpg-auto-ipmort-keys ref {repository_ids_string}' },
          {'onchanges': repository_ids },
        ]
      }
      return self.config

      def repository_url(self, path):
        return os.path.join(self.baseurl, path)

class TumbleweedRepositories(DistributionRepositories):
    # Repository priorities are without effect. All enabled repositories share the same priority.
    #
    # # | Alias         | Name                                   | Enabled | GPG Check | Refresh | URI
    # --+---------------+----------------------------------------+---------+-----------+---------+---------------------------------------------------------
    # 1 | repo-debug    | openSUSE-Tumbleweed-Debug              | No      | ----      | ----    | http://download.opensuse.org/debug/tumbleweed/repo/oss/
    # 2 | repo-non-oss  | openSUSE-Tumbleweed-Non-Oss            | Yes     | ( p) Yes  | Yes     | http://download.opensuse.org/tumbleweed/repo/non-oss/
    # 3 | repo-openh264 | Open H.264 Codec (openSUSE Tumbleweed) | Yes     | ( p) Yes  | Yes     | http://codecs.opensuse.org/openh264/openSUSE_Tumbleweed
    # 4 | repo-oss      | openSUSE-Tumbleweed-Oss                | Yes     | ( p) Yes  | Yes     | http://download.opensuse.org/tumbleweed/repo/oss/
    # 5 | repo-source   | openSUSE-Tumbleweed-Source             | No      | ----      | ----    | http://download.opensuse.org/source/tumbleweed/repo/oss/
    # 6 | repo-update   | openSUSE-Tumbleweed-Update             | Yes     | ( p) Yes  | Yes     | http://download.opensuse.org/update/tumbleweed/
    #
    def __init__(self, obs_instance="obs"):
        enabled_repositories = {
          'repo-oss': {
            'repository_path': 'tumbleweed/repo/oss/',
            'name': 'repo-oss',
            'enabled': True,
            'refresh': True,
          }
        }
        disabled_repositories = {
          'repo-source':{
            'name': 'repo-source'
          }
        }
        super().__init__(obs_instance, enabled_repositories=enabled_repositories, disabled_repositories=disabled_repositories)

class LeapRepositories(DistributionRepositories):
    # Repository priorities are without effect. All enabled repositories share the same priority.
    #
    # #  | Alias                       | Name                                                                                        | Enabled | GPG Check | Refresh
    # ---+-----------------------------+---------------------------------------------------------------------------------------------+---------+-----------+--------
    #  1 | repo-backports-debug-update | Update repository with updates for openSUSE Leap debuginfo packages from openSUSE Backports | No      | ----      | ----
    #  2 | repo-backports-update       | Update repository of openSUSE Backports                                                     | Yes     | ( p) Yes  | Yes
    #  3 | repo-debug                  | Debug Repository                                                                            | No      | ----      | ----
    #  4 | repo-debug-non-oss          | Debug Repository (Non-OSS)                                                                  | No      | ----      | ----
    #  5 | repo-debug-update           | Update Repository (Debug)                                                                   | No      | ----      | ----
    #  6 | repo-debug-update-non-oss   | Update Repository (Debug, Non-OSS)                                                          | No      | ----      | ----
    #  7 | repo-non-oss                | Non-OSS Repository                                                                          | Yes     | ( p) Yes  | Yes
    #  8 | repo-openh264               | Open H.264 Codec (openSUSE Leap)                                                            | Yes     | ( p) Yes  | Yes
    #  9 | repo-oss                    | Main Repository                                                                             | Yes     | ( p) Yes  | Yes
    # 10 | repo-sle-debug-update       | Update repository with debuginfo for updates from SUSE Linux Enterprise 15                  | No      | ----      | ----
    # 11 | repo-sle-update             | Update repository with updates from SUSE Linux Enterprise 15                                | Yes     | ( p) Yes  | Yes
    # 12 | repo-source                 | Source Repository                                                                           | No      | ----      | ----
    # 13 | repo-update                 | Main Update Repository                                                                      | Yes     | ( p) Yes  | Yes
    # 14 | repo-update-non-oss         | Update Repository (Non-Oss)                                                                 | Yes     | ( p) Yes  | Yes
    #
    def __init__(self, obs_instance="obs"):
        enabled_repositories = {}
        disabled_repositories = {}
        super().__init__(obs_instance, enabled_repositories=enabled_repositories, disabled_repositories=disabled_repositories)

class SLERepositories(DistributionRepositories):
    def __init__(self, obs_instance="ibs"):
        enabled_repositories = {}
        disabled_repositories = {}
        super().__init__(obs_instance, enabled_repositories=enabled_repositories, disabled_repositories=disabled_repositories)

def run():
    repository_config = None
    if "openSUSE Tumbleweed" == __grains__['oscodename']:
      repository_config = TumbleweedRepositories()
    elif "SLES" == __grains__['osfullname']:
      repository_config = SLERepositories()
    elif "Leap" == __grains__['osfullname']:
      repository_config = LeapRepositories()
    else:
      log.error(__grains__)
      raise SaltConfigurationError(f'Do not know how to handle this distribution')

    if repository_config:
      repos = repository_config.repositories()
      log.error(repos)
      return repos
