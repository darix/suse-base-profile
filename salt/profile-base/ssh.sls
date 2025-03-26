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

openssh_package:
   pkg.installed:
     - names:
       - openssh

# TODO: add support for ALP and friends
{%- if grains.osfullname == "openSUSE Tumbleweed" %}
{%- set config_path = "/etc/ssh/sshd_config.d/99-salt.conf" %}
{%- else %}
{%- set config_path = "/etc/ssh/sshd_config" %}
{%- endif %}

openssh_config:
  file.managed:
    - user: root
    - group: root
    - mode: '0600'
    - template: jinja
    - names:
      - {{ config_path }}:
        - source: salt://{{ slspath }}/files/etc/ssh/sshd_config.j2

openssh_service:
  service.running:
    - name: sshd
    - enable: True
    - require:
      - openssh_config
    - onchanges:
      - openssh_config
    - watch:
      - openssh_config

