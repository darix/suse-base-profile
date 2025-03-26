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

{%- set content = [] %}

{%- if "locale" in pillar and "language" in pillar.locale %}
{%- set locale_language = pillar.locale.language %}
{%- else %}
{%- set locale_language = "en_US.UTF-8" %}
{%- endif %}

{%- do content.append("LANG=" ~ locale_language) %}

{%- if "locale" in pillar and "formats" in pillar.locale %}
{% for format, value in pillar.locale.formats.items() %}
# TODO: add support that if the variable is already prefixed with LC_ we wouldnt do that again.
{%- do content.append("LC_" ~ format|upper ~ "=" ~ value) %}
{%- endfor %}
{%- endif %}

locale_packages:
  pkg.installed:
    - names:
      - systemd
      {%- if grains.osfullname == 'openSUSE Tumbleweed' and locale_language in ['en_US.UTF-8', 'C.UTF-8'] %}
      - glibc-locale-base
      {%- else %}
      - glibc-locale
      {%- endif %}

locale_conf:
  file.managed:
    - name: /etc/locale.conf
    - user: root
    - group: root
    - mode: '0644'
    - require:
      - locale_packages
    - contents:
      {% if "greeting" in pillar %}
      - "# {{ pillar.greeting }}"
      {%- endif %}
      {%- for line in content %}
      - "{{ line }}"
      {%- endfor %}
