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

#
# Copyright (C) 2024 SUSE LLC
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#


import salt.utils.data
import logging
import os.path
import os
import salt.loader
from salt.grains.napalm import username
# we need this until we find out how to initialize __opts__ ourself. this include does that for us.
from salt.modules.cmdmod import run_stdout as cmdrun

from salt.exceptions import SaltConfigurationError, SaltRenderError
import salt.pillar.stack
from salt.utils.odict import OrderedDict

log = logging.getLogger(__name__)

def __virtual__():
    """
    This module has no external dependencies
    """
    return True


"""
input:
{%- set root_user_groups = [ "buildops", "bs-prjm" ] %}

sshkeys:
  root:
    groups:
    {% for group in root_user_groups: %}
    - {{ group }}
    {% endfor }}
  kanku1:
    groups:
    - kanku-blubb
    target_path: /etc/kanku/sshkeys-blubb

sshkeys:
  root:
    sshkeys:
      - ...
 kanku1:
    sshkeys:
      - ...
    target_path: /etc/kanku/sshkeys-blubb
"""

class SSHKeysResolver:
    def __init__(self, minion_id, base_dir, pillar):
        self.minion_id = minion_id
        self.pillar = pillar

        self.resolved_sshkeys_pillar = {"sshkeys": {}}

        self.sshkeys_basedir = base_dir
        if not(os.path.exists(self.sshkeys_basedir)):
            raise SaltConfigurationError(f"Can not find sshkeys base dir: {self.sshkeys_basedir}")

        if "sshkeys" in pillar:
            self.resolve()


    def new_pillar(self):
        return self.resolved_sshkeys_pillar


    def resolve(self):
        for username, userdata in self.pillar["sshkeys"].items():
            resolved_usernames = []
            logging.info(f"Resolving data for {username}")


            if "groups" in userdata:
                for group in userdata["groups"]:
                    resolved_usernames.extend(self.resolve_groups(username, group))
            if "users" in userdata:
                resolved_usernames.extend(userdata["users"])
            logging.info(f"User list after resolving {resolved_usernames}")
            self.resolve_users(username, resolved_usernames)

    def resolve_users(self, target_username, users):
        user_list = {}
        for user in users:
            user_file = os.path.join(self.sshkeys_basedir, "users", f"{user}.sls")
            if os.path.exists(user_file):
                user_data = self.render(user_file)
                user_list[user] = user_data["sshkeys"]["users"][user]
            else:
                raise SaltRenderError(f"Failed to find user file for {user} {user_file}")
        self.merge_user_results(target_username, user_list)


    def merge_user_results(self, target_username, input_data):
        if not(target_username in self.resolved_sshkeys_pillar["sshkeys"]):
            self.resolved_sshkeys_pillar["sshkeys"][target_username] = {}
        if not("users" in self.resolved_sshkeys_pillar["sshkeys"][target_username]):
            self.resolved_sshkeys_pillar["sshkeys"][target_username]["sshkeys"] = {}

        self.resolved_sshkeys_pillar["sshkeys"][target_username]["sshkeys"]  = { **self.resolved_sshkeys_pillar["sshkeys"][target_username]["sshkeys"], **input_data}

    def render(self, filename):
        default_renderer="jinja|yaml"
        renderers = salt.loader.render(__opts__, __salt__)

        ret = salt.template.compile_template(
            filename,
            renderers,
            default_renderer,
            __opts__["renderer_blacklist"],
            __opts__["renderer_whitelist"],
        )
        return ret.read() if __utils__["stringio.is_readable"](ret) else ret


    def resolve_groups(self, username, groupname):
        resolved_usernames = []
        group_file = os.path.join(self.sshkeys_basedir, "groups", f"{groupname}.sls")
        if os.path.exists(group_file):
            group_data = self.render(group_file)
            if "include" in group_data:
                for line in group_data["include"]:
                    if line.startswith("sshkeys.users."):
                        resolved_usernames.append(line.split(".", 3)[-1])
                    elif line.startswith("sshkeys.groups."):
                        resolved_usernames.extend(self.resolve_groups(line.split(".", 3)[-1]))
                    else:
                        raise SaltRenderError(f"Resolving groups and no idea how to handle line {line}")
            if "sshkeys" in group_data and "users" in group_data["sshkeys"]:
                logging.error(f"Found raw ssh keys user data in {group_file}")
                logging.error(f"User data: {group_data['sshkeys']['users']}")
                logging.error( "Merging into resolved data")
                self.merge_user_results(username, group_data["sshkeys"]["users"])
        else:
            raise SaltRenderError(f"Failed to find group file for {groupname} {group_file}")
        return resolved_usernames


def ext_pillar(minion_id, pillar, base_dir):
    sshkeys_resolver = SSHKeysResolver(minion_id, base_dir, pillar)

    return sshkeys_resolver.new_pillar()