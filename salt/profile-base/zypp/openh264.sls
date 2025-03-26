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

{%- if 'zypp' in pillar and 'products_enable_openh264' in pillar.zypp and pillar.zypp.products_enable_openh264 %}
  {%- set baseurl = "https://codecs.opensuse.org/openh264/" %}

  {%- set repo_id = "repo-openh264" %}
  {%- set project_name = "Open H.264 Codec " %}
  {%- set subdir = None %}

  {%- if grains.osfullname in ["Leap", "SLES" ] %}
  {%- set subdir = "openSUSE_Leap" %}
  {%- set distro_field = "openSUSE Leap" %}
  {%- endif %}

  {%- if grains.osfullname == 'openSUSE Tumbleweed' %}
  {%- set subdir = "openSUSE_Tumbleweed" %}
  {%- set distro_field = grains.osfullname %}
  {%- endif %}

  {%- if subdir %}
    {%- set repo_url = baseurl ~ subdir ~ '/' %}
{{ repo_id }}:
  pkgrepo.managed:
    - name:       {{ repo_id }}
    - humanname:  {{ project_name }}({{ distro_field }})
    - baseurl:    {{ repo_url }}
    - gpgcheck: 1
    - refresh: True

openh264_zypper_refresh:
  cmd.run:
    - name: /usr/bin/zypper --non-interactive --gpg-auto-import-keys ref {{ repo_id }}
    - onchanges:
      - {{ repo_id }}
  {%- endif %}
{%- endif %}