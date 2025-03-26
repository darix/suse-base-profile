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

systemd_journald_settings:
  ini.options_present:
    # TODO: change to drop in for TW/ALP
    - name: /etc/systemd/journald.conf
    - separator: '='
    - strict: True
    - sections:
        'Journal':
          'Storage': 'persistent'
          'ForwardToSyslog': 'yes'
          'SystemKeepFree': '1G'

systemd_journald_directory:
  file.directory:
    - name: /var/log/journal
    - user: root
    - group: systemd-journal
    - dir_mode: '2755'

systemd_journald_service:
  service.running:
    - name: systemd-journald
    - enable: True
    - require:
      - systemd_journald_settings
    - onchanges:
      - systemd_journald_settings
    - watch:
      - systemd_journald_settings
