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

# apparmor:
#   local:
#     usr.sbin.haproxy:
#       - /etc/haproxy/** r,
#       - /etc/ssl/services/* r,
#       - capability dac_read_search,
#       - capability dac_override,
#
{%- set apparmor_local_dir = "/etc/apparmor.d/local/" %}
{%- set overrides_sections = [] %}
{%- if 'apparmor' in pillar %}
{%-   if 'local' in pillar.apparmor %}
{%-     for profile_name, profile_data in pillar.apparmor.local.items() %}
{%-       set overrides_filename = apparmor_local_dir  ~ profile_name %}
{%-       set overrides_section  = 'apparmor_local_' ~ profile_name.replace('.', '_') %}
{%-       do overrides_sections.append(overrides_section) %}
{{ overrides_section }}:
  file.managed:
    - name: {{ overrides_filename }}
    - makedirs: true
    - dir_mode: '0755'
    - mode: '0644'
    - user: root
    - group: root
    - watch_in:
    - contents:
      {%- if 'managed_by_salt' in pillar %}
      - "# {{ pillar.managed_by_salt }}"
      {%- endif %}
      - "# Site-specific additions and overrides for '{{ profile_name }}'."
      - "# For more details, please see /etc/apparmor.d/local/README."
      {%- for override in profile_data %}
      - '{{ override }}'
      {%- endfor %}
{%-     endfor %}

apparmor_reload:
  cmd.run:
    - name: '/usr/bin/aa-enabled && /usr/bin/systemctl try-reload-or-restart apparmor'
    - onchanges:
      {%- for overrides_section in overrides_sections %}
      - {{ overrides_section }}
      {%- endfor %}
{%-   endif %}
{%- endif %}

