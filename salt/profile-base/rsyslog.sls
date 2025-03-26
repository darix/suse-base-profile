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

uninstall_syslog_ng_package:
  pkg.removed:
    - names:
      - syslog-ng

{%- if 'syslog' in pillar %}
{%- set rsyslog_version_dep = '>= 8.2406.0' %}
rsyslog_package:
  pkg.installed:
    - pkgs:
      - librelp0: '1.11.0'
      - rsyslog: '{{ rsyslog_version_dep }}'
      - rsyslog-module-relp: '{{ rsyslog_version_dep }}'
    - require:
      - uninstall_syslog_ng_package

rsyslog_remote_host:
  file.managed:
    - user: root
    - group: root
    - mode: '0644'
    - template: jinja
    - require:
      - rsyslog_package
    - names:
      - /etc/rsyslog.d/remote.conf:
        - source: salt://{{ slspath }}/files/etc/rsyslog.d/remote.conf.j2

rsyslog_service:
  service.running:
    - name: rsyslog
    - enable: True
    - require:
      - rsyslog_remote_host
    - watch:
      - rsyslog_remote_host
    - onchanges:
      - rsyslog_remote_host
{%- endif %}
