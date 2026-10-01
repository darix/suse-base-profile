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

{%- set is_modern_linux = (grains.osfullname in ["openSUSE Tumbleweed", "openSUSE Tumbleweed-Slowroll"]) or (grains.osfullname in ["Leap", "SLES" ] and (grains.osrelease|float) >= 16) %}

{%- set passwd_modules   = ["compat", "systemd"] %}
{%- set passwd_compat_modules = [] %}
{%- set group_modules    = ["compat"] %}
{%- set shadow_modules   = ["compat"] %}
{%- set netgroup_modules = ["files"] %}
{%- set autofs_modules   = ["files"] %}

{%- if is_modern_linux %}
{%- do group_modules.append("[SUCCESS=merge] systemd") %}
{%- do shadow_modules.append("systemd") %}
{%- else %}
{%- do group_modules.append("systemd") %}
{%- endif %}

{%- if 'sssd' in pillar %}

{%- if pillar.sssd.get('map_users', False) %}
{%- do passwd_modules.append("sss") %}
{%- do shadow_modules.append("sss") %}
{%- do group_modules.append("sss") %}
{%- do passwd_compat_modules.append("sss") %}
{%- endif %}

{%- if pillar.sssd.get('netgroup', False) %}
{%- do netgroup_modules.append("sss") %}
{%- endif %}

{%- if pillar.sssd.get('autofs', False) %}
{%- do autofs_modules.append("sss") %}
{%- endif %}

{%- endif %}

{%- if is_modern_linux %}
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
{%- if is_modern_linux %}
    - require:
      - nsswitch_copy_to_etc
{%- endif %}

{% if passwd_compat_modules |length > 0 %}
nsswitch_passwd_compat:
  file.replace:
    - name: /etc/nsswitch.conf
    - pattern: '^(passwd_compat:\s+).*?$'
    - repl: 'passwd_compat: {{ passwd_compat_modules| join(" ") }}'
    - append_if_not_found: True
{%- if is_modern_linux %}
    - require:
      - nsswitch_copy_to_etc
{%- endif %}
{%- endif %}

nsswitch_group:
  file.replace:
    - name: /etc/nsswitch.conf
    - pattern: '^(group:\s+).*?$'
    - repl: '\1{{ group_modules| join(" ") }}'
{%- if is_modern_linux %}
    - require:
      - nsswitch_copy_to_etc
{%- endif %}

nsswitch_shadow:
  file.replace:
    - name: /etc/nsswitch.conf
    - pattern: '^(shadow:\s+)\.*?$'
    - repl: '\1{{ shadow_modules| join(" ") }}'
{%- if is_modern_linux %}
    - require:
      - nsswitch_copy_to_etc
{%- endif %}

nsswitch_netgroup:
  file.replace:
    - name: /etc/nsswitch.conf
    - pattern: '^(netgroup:\s+).*?$'
    - repl: '\1{{ netgroup_modules| join(" ") }}'
{%- if is_modern_linux %}
    - require:
      - nsswitch_copy_to_etc
{%- endif %}

nsswitch_automount:
  file.replace:
    - name: /etc/nsswitch.conf
    - pattern: '^(automount:\s+).*?$'
    - repl: '\1{{ autofs_modules| join(" ") }}'
{%- if is_modern_linux %}
    - require:
      - nsswitch_copy_to_etc
{%- endif %}
