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

cleanup_ntp:
  pkg.removed:
    - pkgs:
      - ntp

chrony_package:
   pkg.installed:
     - names:
       - chrony

chrony_config:
  file.managed:
    - user: root
    - group: chrony
    - mode: '0640'
    - template: jinja
    - require:
      - chrony_package
    - names:
      - /etc/chrony.conf:
        - source: salt://{{ slspath }}/files/etc/chrony.conf.j2

chrony_service:
  service.running:
    - name: chronyd
    - enable: True
    - require:
      - cleanup_ntp
    - onchange:
      - chrony_config
    - require:
      - chrony_config
    - watch:
      - chrony_config