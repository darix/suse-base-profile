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

{%- if 'network' in pillar and 'resolver' in pillar.network and 'hosts' in pillar.network.resolver %}
etc_hosts:
  file.managed:
    - user: root
    - group: root
    - mode: '0644'
    - template: jinja
    - names:
      - /etc/hosts:
        - source: salt://{{ slspath }}/files/etc/hosts.j2
  cmd.run:
    - name: /usr/bin/systemctl reload dnsmasq.service
    - onlyif: /usr/bin/systemctl is-active dnsmasq.service
    - require:
      - file: etc_hosts
    - onchanges:
      - file: etc_hosts
{%- endif %}
