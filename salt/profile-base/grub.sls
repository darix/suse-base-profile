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

dracut_nowaitforswap:
  file.replace:
    - name: /etc/dracut.conf
    - pattern: "^nowaitforswap=.*"
    - repl: "nowaitforswap=yes"
    - append_if_not_found: True


{%- set changed_settings = [] %}

{%- if 'grub' in pillar %}

{%- for setting, value in pillar.grub.items() %}

{%- set section = "grub_" ~ setting %}
{%- do changed_settings.append(section) %}

{{ section }}:
  file.replace:
    - name: /etc/default/grub
    - pattern: GRUB_{{ setting | upper }}=.*
    - repl: GRUB_{{ setting | upper }}="{{ value }}"
    - append_if_not_found: True

{%- endfor %}
{%- endif %}

grub_rebuild_config:
  cmd.run:
    - name: /usr/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg
    - onchanges:
      - dracut_nowaitforswap
      {%- for changed_setting in changed_settings %}
      - {{ changed_setting }}
      {%- endfor %}