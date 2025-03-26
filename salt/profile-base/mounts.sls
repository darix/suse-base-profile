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

# generic mount point handler
{%- from 'profile-base/helpers/mounts_helper.sls' import cleanup_mount_name %}
{%- from 'profile-base/helpers/mounts_helper.sls' import mount_option_value %}
{%- from 'profile-base/helpers/mounts_helper.sls' import mount_options %}

{%- if 'mounts' in pillar and pillar.mounts %}

  {%- for mount_name, mount_data in pillar.mounts.items() %}

    {%- set cleanedup_mount_name = cleanup_mount_name(mount_name) %}

    {%- if mount_name == 'swap' %}

mountpoint{{ cleanedup_mount_name }}:
  mount.swap:
   - name: {{ mount_data['device'] }}
{{ mount_option_value('persist', mount_data) }}

    {%- else %}

mountpoint{{ cleanedup_mount_name }}:
  mount.mounted:
    - name: {{ mount_name }}
{{ mount_options(mount_name, mount_data) }}

    {%- endif %}
  {%- endfor %}
{%- endif %}

{%- set deprecated_fstab_entries = { "devpts": "/dev/pts","proc": "/proc","sysfs": "/sys","debugfs": "/sys/kernel/debug","usbfs": "/proc/bus/usb","tmpfs": "/run" } %}

{%- for target_device, mount_point in deprecated_fstab_entries.items() %}

cleanup_fstab{{ cleanup_mount_name(mount_point) }}:
  mount.fstab_absent:
   - name: {{ target_device }}
   - fs_file: {{ mount_point }}

{%- endfor %}
