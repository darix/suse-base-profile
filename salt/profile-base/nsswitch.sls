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

{%- set passwd_modules   = ["compat"] %}
{%- set group_modules    = ["compat"] %}
{%- set shadow_modules   = ["compat"] %}
{%- set netgroup_modules = ["files"] %}
{%- set autofs_modules   = ["files"] %}

# TODO: handle ALP and friends
{%- if (grains.osfullname == "openSUSE Tumbleweed") or (grains.osfullname in ["Leap", "SLES" ] and (grains.osrelease|float) >= 16) %}
{%- do passwd_modules.append("systemd") %}
{%- do group_modules.append("[SUCCESS=merge] systemd") %}
{%- endif %}

{%- if  (grains.osfullname in ["Leap", "SLES" ] and (grains.osrelease|float) > 15.5) %}
{%- do passwd_modules.append("systemd") %}
{%- do group_modules.append("systemd") %}
{%- endif %}

{%- if 'sssd' in pillar and 'map_users' in pillar.sssd and pillar.sssd.map_users %}
{%- do passwd_modules.append("sss") %}
{%- do group_modules.append("sss") %}
{%- endif %}

{%- if 'sssd' in pillar and 'netgroup' in pillar.sssd and pillar.sssd.netgroup %}
{%- do netgroup_modules.append("sss") %}
{%- else %}
{%- do netgroup_modules.append("nis") %}
{%- endif %}

{%- if 'sssd' in pillar and 'autofs' in pillar.sssd and pillar.sssd.autofs %}
{%- do autofs_modules.append("sss") %}
{%- else %}
{%- do autofs_modules.append("nis") %}
{%- endif %}

{%- if (grains.osfullname == "openSUSE Tumbleweed") or (grains.osfullname in ["Leap", "SLES" ] and (grains.osrelease|float) >= 16) %}
nsswitch_copy_to_etc:
  file.copy:
    - name:   /etc/nsswitch.conf
    - source: /usr/etc/nsswitch.conf
    - preserve: True
{%- endif %}

nsswitch_passwd:
  file.replace:
    - name: /etc/nsswitch.conf
    - pattern: '^(passwd:\s+).*?$'
    - repl: '\1{{ passwd_modules| join(" ") }}'
{%- if (grains.osfullname == "openSUSE Tumbleweed") or (grains.osfullname in ["Leap", "SLES" ] and (grains.osrelease|float) >= 16) %}
    - require:
      - nsswitch_copy_to_etc
{%- endif %}

nsswitch_group:
  file.replace:
    - name: /etc/nsswitch.conf
    - pattern: '^(group:\s+).*?$'
    - repl: '\1{{ group_modules| join(" ") }}'
{%- if (grains.osfullname == "openSUSE Tumbleweed") or (grains.osfullname in ["Leap", "SLES" ] and (grains.osrelease|float) >= 16) %}
    - require:
      - nsswitch_copy_to_etc
{%- endif %}

nsswitch_shadow:
  file.replace:
    - name: /etc/nsswitch.conf
    - pattern: '^(shadow:\s+)\.*?$'
    - repl: '\1{{ shadow_modules| join(" ") }}'
{%- if (grains.osfullname == "openSUSE Tumbleweed") or (grains.osfullname in ["Leap", "SLES" ] and (grains.osrelease|float) >= 16) %}
    - require:
      - nsswitch_copy_to_etc
{%- endif %}

nsswitch_netgroup:
  file.replace:
    - name: /etc/nsswitch.conf
    - pattern: '^(netgroup:\s+).*?$'
    - repl: '\1{{ netgroup_modules| join(" ") }}'
{%- if (grains.osfullname == "openSUSE Tumbleweed") or (grains.osfullname in ["Leap", "SLES" ] and (grains.osrelease|float) >= 16) %}
    - require:
      - nsswitch_copy_to_etc
{%- endif %}

nsswitch_automount:
  file.replace:
    - name: /etc/nsswitch.conf
    - pattern: '^(automount:\s+).*?$'
    - repl: '\1{{ autofs_modules| join(" ") }}'
{%- if (grains.osfullname == "openSUSE Tumbleweed") or (grains.osfullname in ["Leap", "SLES" ] and (grains.osrelease|float) >= 16) %}
    - require:
      - nsswitch_copy_to_etc
{%- endif %}