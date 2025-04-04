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

# udev:
#   rules:
#     - KERNEL!="vd*", GOTO="scheduler_end" ATTR{queue/scheduler}="mq-deadline"
#

{%- if 'udev' in pillar %}
udev_package:
  pkg.installed:
    - names:
      - udev

{%- set udev_generic_rules_file = '/etc/udev/rules.d/99-salt.rules' %}
{%- set udev_net_rules_file     = '/etc/udev/rules.d/70-persistent-net.rules' %}
{%- set udev_rules_files = [] %}

{%- if 'net' in pillar.udev %}
{%- do udev_rules_files.append(udev_net_rules_file) %}
udev_net_rules_salt:
  file.managed:
    - name: {{ udev_net_rules_file }}
    - makedirs: true
    - dir_mode: '0755'
    - mode: '0644'
    - user: root
    - group: root
    - require:
      - pkg: udev
    - contents:
      {%- if 'managed_by_salt' in pillar %}
      - '# {{ pillar.managed_by_salt }}'
      {%- endif %}
      {%- for interface, macaddress in pillar.udev.net.items() %}
      - 'SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="{{ macaddress }}", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="{{ interface }}"'
      {%- endfor %}
{%- endif %}

{%- if 'rules' in pillar.udev %}
{%- do udev_rules_files.append(udev_generic_rules_file) %}
udev_generic_rules_salt:
  file.managed:
    - name: {{ udev_generic_rules_file }}
    - makedirs: true
    - dir_mode: '0755'
    - mode: '0644'
    - user: root
    - group: root
    - require:
      - pkg: udev
    - contents:
      {%- if 'managed_by_salt' in pillar %}
      - '# {{ pillar.managed_by_salt }}'
      {%- endif %}
      {%- for rule in pillar.udev.rules %}
      - '{{ rule }}'
      {%- endfor %}
{%- endif %}

udevadm_reload:
  cmd.run:
    - name: /usr/bin/udevadm control --reload-rules
    - onchanges:
      {%- for file in udev_rules_files %}
      - {{ file }}
      {%- endfor %}
    - require:
      {%- for file in udev_rules_files %}
      - {{ file }}
      {%- endfor %}

udevadm_trigger:
  cmd.run:
    - name: /usr/bin/udevadm trigger
    - onchanges:
      - udevadm_reload
      {%- for file in udev_rules_files %}
      - {{ file }}
      {%- endfor %}
    - require:
      {%- for file in udev_rules_files %}
      - {{ file }}
      {%- endfor %}
      - udevadm_reload
{%- endif %}
