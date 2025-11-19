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

def run():
  config = {}
  default_sysctl_content="""####
#
# /etc/sysctl.conf is meant for local sysctl settings
#
# sysctl reads settings from the following locations:
#   /boot/sysctl.conf-<kernelversion>
#   /lib/sysctl.d/*.conf
#   /usr/lib/sysctl.d/*.conf
#   /usr/local/lib/sysctl.d/*.conf
#   /etc/sysctl.d/*.conf
#   /run/sysctl.d/*.conf
#   /etc/sysctl.conf
#
# To disable or override a distribution provided file just place a
# file with the same name in /etc/sysctl.d/
#
# See sysctl.conf(5), sysctl.d(5) and sysctl(8) for more information
#
####
"""

  config["restore_default_sysctl"] = {
    "file.managed": [
      { 'name': '/etc/sysctl.conf' },
      { 'mode': '0644' },
      { 'user': 'root' },
      { 'group': 'root' },
      { 'contents': default_sysctl_content },
      { 'onlyif': 'test -e /etc/sysctl.conf' },
      { "require_in": ["run_sysctl"]},
      { "onchanges_in": ["run_sysctl"]},
    ]
  }
  sysctld_dir = "/etc/sysctl.d/"
  sysctld_salt_config = "99-salt.conf"
  if 'sysctl' in __pillar__:
    sysctl_salt_content = []

    for key, value in __salt__["pillar.get"]("sysctl", {}).items():
      sysctl_salt_content.append(f"{key} = {value}")

    # needs to be at th end of the file
    # This will ensure that immediatly subsequent connections use the new values
    for proto in [4,6]:
      sysctl_salt_content.append(f"net.ipv{proto}.route.flush = 1")

    config["sysctl_salt_config"] = {
      "file.managed": [
        { 'name': os.path.join(sysctld_dir, sysctld_salt_config)},
        { 'mode': '0644' },
        { 'user': 'root' },
        { 'group': 'root' },
        { 'contents': "\n".join(sysctl_salt_content) },
        { "require_in": ["run_sysctl"]},
        { "onchanges_in": ["run_sysctl"]},
      ]
    }

  bad_files_to_be_purged = [f for f in os.listdir(sysctld_dir) if not(sysctld_salt_config == f)]

  for filename in bad_files_to_be_purged:
    config[f"purge_sysctl_{filename}"] = {
      "file.absent": [
        {"name": os.path.join(sysctld_dir, filename)},
        { "require_in": ["run_sysctl"]},
        { "onchanges_in": ["run_sysctl"]},
      ]
    }

  config["run_sysctl"] = {
    "cmd.run": [
      {"name": "/sbin/sysctl --system"},
    ]
  }
  return config