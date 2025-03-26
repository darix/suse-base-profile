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

{% if 'sssd' in pillar %}
sssd_packages:
  pkg.installed:
    - names:
      - sssd
      - sssd-ldap
{%- if 'autofs' in pillar.sssd and pillar.sssd.autofs %}
      - autofs
{%- endif %}
# 32bit package needed as pam-config always wants the 32bit variant
{%- if grains.osrelease | float < 15.6 %}
      - sssd-common-32bit
{%- else %}
      - sssd-32bit
{%- endif %}

sssd_config:
  file.managed:
    - user: root
    - group: root
    - mode: 0600
    - template: jinja
    - names:
      - /etc/sssd/conf.d/salt.conf:
        - source: salt://{{ slspath }}/files/etc/sssd/conf.d/salt.conf.j2

sssd_pam_enable:
  cmd.run:
    - name: /usr/sbin/pam-config --add --sss
    - unless: "/usr/bin/grep -q 'pam_sss' /etc/pam.d/common-session-pc"

sssd_service:
  service.running:
    - name: sssd
    - enable: True
    - require:
      - sssd_pam_enable
      - sssd_config
    - onchanges:
      - sssd_config
    - watch:
      - sssd_config
{%- endif %}
