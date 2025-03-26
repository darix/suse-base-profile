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

{%- macro cleanup_mount_name(mount_name) %}
{%- if mount_name == '/' %}
{%- set cleanedup_name = "_rootfs" %}
{%- elif mount_name == 'swap' %}
{%- set cleanedup_name = "_swap" %}
{%- else %}
{%- set cleanedup_name = mount_name.replace('/','_').replace('.', '_').replace(' ', '_') %}
{%- endif %}
{{- cleanedup_name }}
{%- endmacro %}

{%- macro pass_for_mountpoint(mount_name, mount_data) %}
  {%- set pass_num = 2 %}

  {%- if mount_name == "/" %}
  {%- set pass_num = 1 %}
  {%- endif %}

  {%- if ("opts" in mount_data and "bind" in mount_data['opts']) or ("fstype" in mount_data and mount_data["fstype"] in ['nfs', 'tmpfs', 'none']) %}
  {%- set pass_num = 0 %}
  {%- endif %}

{{- pass_num }}
{%- endmacro %}

{%- macro mount_option_value(mount_option, mount_data={}, mount_defaults={}) %}
    {%- set mount_defaults = { 'mkmnt': True } %}
    {%- set value = mount_data.get(mount_option, mount_defaults.get(mount_option, None)) %}
    {%- if value != None %}
    - {{ mount_option }}: {{ value }}
    {%- endif %}
{%- endmacro %}

{%- macro mount_options(mount_name, mount_data={}) %}
  {%- set valid_mount_options = [ 'device', 'fstype', 'mkmnt', 'opts', 'dump', 'config', 'persist', 'mount', 'user', 'match_on', 'device_name_regex', 'extra_mount_invisible_options', 'extra_mount_invisible_keys', 'extra_mount_ignore_fs_keys', 'extra_mount_translate_options', 'hidden_opts', 'bind_mount_copy_active_opts' ] %}
  {%- for mount_option in valid_mount_options %}
{{ mount_option_value(mount_option, mount_data) }}
  {%- endfor %}
  {%- set mount_option = 'pass_num' %}
  {%- set value = mount_data.get(mount_option, pass_for_mountpoint(mount_name, mount_data)) %}
    - {{ mount_option }}: {{ value }}
{%- endmacro %}
