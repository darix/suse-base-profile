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

{%- macro jump_hosts_entries(minion_id, jump_host) %}
{%- set minion_jump_address = salt['mine.get'](minion_id, 'internal_ssh_address').get(minion_id, minion_id) %}
{%- set minion_jump_port = 22 %}
{%- if minion_jump_address == '' %}
{%-    set minion_jump_host = minion_id %}
{%- else %}
{%-   if ':' in minion_jump_address %}
{%-      set minion_jump_host, minion_jump_port = minion_jump_address.split(':', 2) %}
{%-   else %}
{%-      set minion_jump_host = minion_jump_address %}
{%-   endif %}
{%- endif %}
Host {{ minion_id.split('.')[0] }}
  Hostname {{ minion_jump_host }}
  Port {{ minion_jump_port }}
{%- if jump_host != minion_id %}
  ProxyJump root@{{ jump_host }}
{%- endif %}
  ForwardAgent yes
  User root

Host {{ minion_id }}
  Hostname {{ minion_jump_host }}
  Port {{ minion_jump_port }}
{%- if jump_host != minion_id %}
  ProxyJump root@{{ jump_host }}
{%- endif %}
  ForwardAgent yes
  User root

{%- endmacro %}
