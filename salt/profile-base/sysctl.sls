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

restore_default_sysctl:
  file.managed:
    - name: /etc/sysctl.conf
    - mode: '0644'
    - user: root
    - group: root
    - onlyif: test -e /etc/sysctl.conf
    - source: salt://{{ slspath }}/files/etc/sysctl.conf

{%- if "sysctl" in pillar %}
{%- set items = [] %}
{%- for key, value in pillar.sysctl.items() %}
  {%- do items.append(key) %}
{{ key }}:
   sysctl.present:
     - value: {{ value }}
     - require:
       - restore_default_sysctl
{%- endfor %}

run_sysctl:
  cmd.run:
    - name: /sbin/sysctl --system
    - onchanges:
      {%- for item in items %}
      - {{ item }}
      {%- endfor %}
{%- endif %}