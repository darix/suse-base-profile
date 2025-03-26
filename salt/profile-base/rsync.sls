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

{%- if 'rsync' in pillar and 'modules' in pillar.rsync %}
rsyncd_packages:
  pkg.installed:
    - names:
      - rsync

rsyncd_config:
  file.managed:
    - user: root
    - group: root
    - mode: '0644'
    - template: jinja
    - names:
      - /etc/rsyncd.conf:
        - source: salt://{{ slspath }}/files/etc/rsyncd.conf.j2

rsyncd_secrets:
  file.managed:
    - user: root
    - group: root
    - mode: '0600'
    - template: jinja
    - names:
      - /etc/rsyncd.secrets:
        - source: salt://{{ slspath }}/files/etc/rsyncd.secrets.j2

rsyncd_service:
  service.running:
    - name: rsyncd
    - enable: True
    - watch:
      - rsyncd_config
    - require:
      - rsyncd_config
    - onchanges:
      - rsyncd_config
{%- else %}
rsyncd_socket_dead:
  service.dead:
    - name: rsyncd.socket
    - enable: False

rsyncd_service_dead:
  service.dead:
    - name: rsyncd.service
    - enable: False
{%- endif %}
