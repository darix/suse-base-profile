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

{%- if 'check_zypper' in  pillar.zypp %}
#
# the directory is more of a fallback as all our new checks use the monitoring-plugins path ... so make sure it is available
#
zypper_nagios_base_dir:
  file.directory:
    - user: root
    - group: root
    - mode: 0755
    - name: /etc/nagios/

#
# This directory must be generated in advance if no
# monitoring-plugins-* packages are installed while 
# bootstrapping
#
zypper_monitoring_plugins_base_dir:
  file.directory:
    - user: root
    - group: root
    - mode: 0755
    - name: /etc/monitoring-plugins/

zypper_check_ignores:
  file.managed:
    - user: root
    - group: root
    - mode: 0644
    - template: jinja
    - names:
      - /etc/monitoring-plugins/check_zypper-ignores.txt:
        - source: salt://profile-base/files/etc/monitoring-plugins/check_zypper-ignores.txt.j2
      - /etc/nagios/check_zypper-ignores.txt:
        - source: salt://profile-base/files/etc/monitoring-plugins/check_zypper-ignores.txt.j2
{%- endif %}
