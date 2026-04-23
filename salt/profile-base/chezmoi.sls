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

import os.path

def run():
    config = {}

    chezmoi_data     = __salt__["pillar.get"]("chezmoi", {})
    chezmoi_packages = ["chezmoi", "git-core"]

    if len(chezmoi_data) > 0:
      config["chezmoi_packages"] = {
        "pkg.installed": [
          {"pkgs": chezmoi_packages },
        ]
      }

      chezmoi_subdir = "/.local/share/chezmoi"

      for username, userdata in chezmoi_data.items():
          target_dir = userdata.get("target_dir", f"~{username}")
          if target_dir.startswith("~"):
              homedir = os.path.expanduser(target_dir)
              if homedir == target_dir:
                  raise SaltRenderError(f"Can not resolve the homedir for user {username} {target_dir}")
              if not(os.path.isdir(homedir)):
                  raise SaltRenderError(f"Invalid homedir? Not a directory? {target_dir}")

          if not("url" in userdata):
            raise SaltRenderError(f"No url specified for {username}")

          chezmoi_path = f"{homedir}{chezmoi_subdir}"
          chezmoi_url = userdata["url"]
          chezmoi_exists = os.path.exists(chezmoi_path)
          chezmoi_is_dir = os.path.isdir(chezmoi_path)

          if chezmoi_exists and chezmoi_is_dir:
            config[f"chezmoi_update_{username}"] = {
              "cmd.run": [
                {'name': 'chezmoi update'},
                {'runas': username},
                {'umask': userdata.get('umask', '022')},
                {'require': ["chezmoi_packages"]},
              ]
            }
          else:
            config[f"chezmoi_init_{username}"] = {
              "cmd.run": [
                {'name':    f'chezmoi init {chezmoi_url}'},
                {'runas':   username},
                {'creates': chezmoi_path},
                {'umask':   userdata.get('umask', '022')},
                {'require': ["chezmoi_packages"]},
              ]
            }
    else:
      config["chezmoi_packages"] = {
        "pkg.purged": [
          {"pkgs": chezmoi_packages },
        ]
      }

    return config