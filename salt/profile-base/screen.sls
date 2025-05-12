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

    config["screen_package"] = {
      "pkg.installed": [
        {"pkgs": ["screen"] },
      ]
    }

    if "screen" in __pillar__ and "config" in __pillar__["screen"]:
        for username, userdata in __pillar__["screen"]["config"].items():
            target_dir = userdata.get("target_dir", f"~{username}")
            if target_dir.startswith("~"):
                homedir = os.path.expanduser(target_dir)
                if homedir == target_dir:
                    raise SaltRenderError(f"Can not resolve the homedir for user {username} {target_dir}")
                if not(os.path.isdir(homedir)):
                    raise SaltRenderError(f"Invalid homedir? Not a directory? {target_dir}")

                target_dir = homedir

            target_owner = userdata.get("target_owner", username)
            target_group = userdata.get("target_group", None)

            config_content = "\n".join(userdata.get("settings", []))

            config[f"screen-config-{username}"] = {
                "file.managed": [
                    { 'user': target_owner },
                    { 'mode': '0640' },
                    { 'name': f"{target_dir}/.screenrc" },
                    { 'contents_pillar': f"screen:config:{username}:settings"},
                ]
            }

            if target_group:
                config[f"screen-config-{username}"]["group"] = target_group

    return config
