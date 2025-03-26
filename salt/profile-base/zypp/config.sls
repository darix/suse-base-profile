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

{%- if 'config' in pillar.zypp %}
  {%- for file_name, file_data in pillar.zypp.config.items() %}

    {%- for setting, value in file_data.items() %}
# TODO: if someone added a true line already, this line will add another
{{ file_name | regex_replace('\.', '_') }}_{{ setting | regex_replace('\.', '_') }}:
  file.replace:
    - name: /etc/zypp/{{ file_name }}
    - pattern: "^(# +)?{{ setting }} =.*"
    - repl: "{{ setting }} = {{ value }}"

    {%- endfor %}
  {%- endfor %}
{%- endif %}
