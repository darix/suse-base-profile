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

def handle_options(chezmoi_commandline, userdata, option_name):
    if option_name in userdata:
      global_options = userdata.get(option_name)
      if isinstance(global_options, list):
        chezmoi_commandline.extend(global_options)
      else:
        chezmoi_commandline.append(global_options)

def run():
    config = {}

    chezmoi_data     = __salt__["pillar.get"]("chezmoi", {})
    chezmoi_packages = ["chezmoi", "git-core"]

    chezmoi_update_existing = __salt__["pillar.get"]("chezmoi:update_existing", False)

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

          chezmoi_commandline = ["chezmoi"]

          handle_options(chezmoi_commandline, userdata, "global_options")

          state_parameters = [
              {'runas':   username},
              {'umask':   userdata.get('umask', '022')},
              {'require': ["chezmoi_packages"]},
            ]

          if chezmoi_exists and chezmoi_is_dir:
            if chezmoi_update_existing:
              chezmoi_commandline.append("update")
              handle_options(chezmoi_commandline, userdata, "update_options")
              handle_options(chezmoi_commandline, userdata, "options")
              section_name = f"chezmoi_update_{username}"

              state_parameters.append({'name': " ".join(chezmoi_commandline)})
              config[section_name] = { "cmd.run": state_parameters }
          else:
            chezmoi_commandline.append("init")
            handle_options(chezmoi_commandline, userdata, "init_options")
            handle_options(chezmoi_commandline, userdata, "options")
            chezmoi_commandline.append(chezmoi_url)
            section_name = f"chezmoi_init_{username}"
            state_parameters.append({'creates': chezmoi_path})

            state_parameters.append({'name': " ".join(chezmoi_commandline)})
            config[section_name] = { "cmd.run": state_parameters }
    else:
      config["chezmoi_packages"] = {
        "pkg.purged": [
          {"pkgs": chezmoi_packages },
        ]
      }

    return config