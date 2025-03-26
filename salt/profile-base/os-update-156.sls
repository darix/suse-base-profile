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

{%- if grains.osfullname in [ 'Leap', 'SLES' ] %}
os_release:
    file.managed:
    - user: root
    - group: root
    - mode: '0644'
    - names:
      - /etc/os-release:
        - source: salt://{{ slspath }}/files/etc/os-release-{{ grains.osfullname | lower }}-15.6
{%- endif %}