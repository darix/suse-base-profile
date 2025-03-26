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

{%- if "flatpak" in pillar %}
flatpak-packages:
  pkg.latest:
    - pkgs:
      - flatpak
      - flatpak-builder

  {%- set registered_repositories = [] %}
  {%- if "repositories" in pillar.flatpak %}

    {%- for repository_name, repository_data in pillar.flatpak.repositories.items() %}

    {%- do registered_repositories.append(repository_name) %}

flatpak-{{ repository_name }}:
  cmd.run:
    - name: flatpak remote-add --if-not-exists {{ repository_name }} {{ repository_data['url'] }}
    - onchanges:
      - flatpak-packages
    - require:
      - flatpak-packages
    {%- endfor %}
  {%- endif %}

  {%- if "apps" in pillar.flatpak and registered_repositories|length > 0 %}
    {%- for app_name in pillar.flatpak %}

flatpak-app-{{ app_name }}:
  cmd.run:
  - name: flatpak install {{ app_name }}
  - require:
    {%- for repository in registered_repositories %}
    - {{ repository }}
    {%- endfor %}

    {%- endfor %}
  {%- endif %}

{%- endif %}
