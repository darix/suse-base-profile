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

{%- if "sysconfig" in pillar %}
{%- for file, file_data in pillar.sysconfig.items() %}
  {%- for key in file_data %}
{%- set setting = key|upper %}
{%- if 'value' in file_data[key] %}
  {%- set value = file_data[key]['value'] %}
{%- else %}
  {%- set value = file_data[key] %}
{%- endif %}
{%- if value is sequence and not value is string %}
  {%- set value = value|join(" ") %}
{%- endif %}

sysconfig_{{ file | regex_replace('/', '_') }}_{{ setting }}:
  file.replace:
    - name: /etc/sysconfig/{{ file }}
    - pattern: "^{{ setting }} *=.*"
    - repl: {{ setting }}="{{ value }}"
    - append_if_not_found: True
    {%- if 'require' in file_data[key] %}
    - require:
      {%- if file_data[key]['require'] is string %}
      - {{ file_data[key]['require'] }}
      {%- else %}
      {%- for requires in file_data[key]['require'] %}
      - {{ requires }}
      {%- endfor %}
      {%- endif %}
    {%- endif -%}
    {%- if 'require_in' in file_data[key] %}
    - require:
      {%- if file_data[key]['require_in'] is string %}
      - {{ file_data[key]['require_in'] }}
      {%- else %}
      {%- for requires in file_data[key]['require_in'] %}
      - {{ requires }}
      {%- endfor %}
      {%- endif %}
    {%- endif -%}
    {%- if 'cmd' in file_data[key] %}
  cmd.run:
    - name: {{ file_data[key]['cmd'] }}
    - onchanges:
      - file: /etc/sysconfig/{{ file }}
    {%- endif %}
  {%- endfor %}
{%- endfor %}
{%- endif %}