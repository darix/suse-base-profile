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
{%- macro ssh_handle_boolean(value) %}
  {%- if  (value is sameas true) %}
    {{- 'yes' }}
  {%- else %}
    {%- if value %}
      {{- value }}
    {%- else %}
      {{- 'no' }}
    {%- endif %}
  {%- endif %}
{%- endmacro %}

{%- macro ssh_output_value(option_name, option_value, indent='') %}
    {%- if option_value is sequence and not option_value is string %}
      {%- for sub_value in option_value %}
{{ indent }}{{ option_name }} {{ ssh_handle_boolean(sub_value) }}
      {%- endfor %}
    {%- else %}
{{-  indent }}{{ option_name }} {{ ssh_handle_boolean(option_value) }}
    {%- endif %}
{%- endmacro %}

{%- macro ssh_config_option(option_name, default_value=None) %}
  {%- set option_value = None %}
  {%- if 'ssh' in pillar %}
    {%- set option_value = pillar.ssh.get(option_name, default_value) %}
  {%- endif %}
  {%- if option_value != None %}
{{ ssh_output_value(option_name, option_value) }}
  {%- endif %}
{%- endmacro %}

{%- macro ssh_config_match_options() %}
  {%- if 'ssh' in pillar and 'Match' in pillar.ssh %}
    {%- for matcher, match_data in pillar.ssh['Match'].items() %}
Match {{ matcher }}
      {%- for option_name, option_value in match_data.items() %}
    {{ ssh_output_value(option_name, option_value, indent='    ') }}
      {%- endfor %}
    {%- endfor %}
  {%- endif %}
{%- endmacro %}