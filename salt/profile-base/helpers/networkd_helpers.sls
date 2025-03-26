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

{%- macro systemd_network_file(systemd_unit, sections) %}
{{ systemd_unit }}:
  file.managed:
    - name: {{ systemd_unit }}
    - makedirs: true
    - dir_mode: '0755'
    - mode: '0644'
    - user: root
    - group: root
    - require:
      - systemd_network_packages
    - require_in:
      - systemd_networkctl_reload
    - contents:
      {%- if 'managed_by_salt' in pillar %}
      - "# {{ pillar.managed_by_salt }}"
      {%- endif %}
      {%- if sections %}
      {%    for section_name, section_data in sections.items() %}
      - "[{{ section_name }}]"
      {%      for setting_data in section_data %}
      - {{ setting_data }}
      {%-     endfor %}
      {%-   endfor %}
      {%- endif %}
{%- endmacro %}

{%- macro networkd_config(devtype, base_index, network_files, netdev_files, link_files, systemd_dir='/etc/systemd/network') %}
{%-   if netdev_files %}
{%-     for name, sections in netdev_files.items() %}
{%-       set systemd_unit = systemd_dir ~ "/" ~ base_index+loop.index ~ '-' ~ devtype ~ '-' ~ name ~ '.netdev'  %}
{{ systemd_network_file(systemd_unit, sections) }}
{%-     endfor %}
{%-   endif %}
{%-   if network_files %}
{%-     for name, sections in network_files.items() %}
{%-       set systemd_unit = systemd_dir ~ "/" ~ base_index+loop.index ~ '-' ~ devtype ~ '-' ~ name ~ '.network'  %}
{{ systemd_network_file(systemd_unit, sections) }}
{%-     endfor %}
{%-   endif %}
{%-   if link_files %}
{%-     for name, sections in link_files.items() %}
{%-       set systemd_unit = systemd_dir ~ "/" ~ base_index+loop.index ~ '-' ~ devtype ~ '-' ~ name ~ '.link'  %}
{{ systemd_network_file(systemd_unit, sections) }}
{%-     endfor %}
{%-   endif %}
{%- endmacro %}
