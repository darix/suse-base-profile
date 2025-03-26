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

{%- for console in [ 'ttyS0', 'ttyS1', 'ttyS2', 'hvc0', 'console' ] %}
securetty_{{ console }}:
  file.replace:
    - name: /etc/securetty
    - pattern: {{ console }}
    - repl:    {{ console }}
    - append_if_not_found: True
{% endfor %}