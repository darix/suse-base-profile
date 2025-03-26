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

#!py

import os.path
from salt.exceptions import SaltRenderError

def run():
    config = {}

    if "sshkeys" in __pillar__:
        for username, userdata in __pillar__["sshkeys"].items():
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

            config[f"ssh-{username}-authorized-keys-dir"] = {
                "file.directory": [
                    {"user": target_owner},
                    {"mode", userdata.get("dir_mode", '0751')},
                    {"name": f"{target_dir}/.ssh"},
                ]
            }

            if target_group:
                config[f"ssh-{username}-authorized-keys-dir"]["group"] = target_group

            config[f"ssh-{username}-authorized-keys-file"] = {
                "file.managed": [
                    { 'user': target_owner },
                    { 'mode': '0644' },
                    { 'template': 'jinja' },
                    { 'name': f"{target_dir}/.ssh/authorized_keys" },
                    { 'source': f"salt://profile-base/files/root/.ssh/authorized_keys.j2" },
                    { 'context': {
                            "sshkeys": userdata["sshkeys"]
                        }
                    },
                ]
            }

            if target_group:
                config[f"ssh-{username}-authorized-keys-file"]["group"] = target_group

    return config