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

# usage example
# salt 'yourhosthere*' state.apply profile-base.dehydrated-cleanup-postrun-hooks

import os
import logging


def run():
    log = logging.getLogger(__name__)
    config = {}
    path = "/etc/dehydrated/postrun-hooks.d"
    salt_script_filename = "99-salt.sh"
    salt_script = os.path.join(path, salt_script_filename)
    has_salt_script = os.path.exists(salt_script)
    if has_salt_script:
        with os.scandir(path) as it:
            for entry in it:
                if (
                    entry.name.endswith(".sh")
                    and entry.is_file()
                    and not entry.name == salt_script_filename
                ):
                    section = f"cleanup_old_postrun_hook_{entry.name}"
                    config[section] = {
                        "file.absent": [
                            {"name": entry.path},
                        ]
                    }
    else:
        raise FileNotFoundError(
            f"Can not cleanup here as {salt_script} is missing. Maybe apply profile-base.dehydrated first?"
        )
    return config
