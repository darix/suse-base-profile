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

{%- if 'isv' in pillar.zypp %}
  {%- set repositories = [] %}

  {%- for repo_id, repodata in pillar.zypp.isv.items() %}
      {%- do repositories.append(repo_id) %}

{{ repo_id }}:
  pkgrepo.managed:
    - name:       {{ repo_id }}
    - humanname:  {{ repodata.name }}
    - baseurl:    {{ repodata.baseurl }}
    {%- if "gpgkey" in repodata %}
    - gpgkey:     {{ repodata.gpgkey }}
    {%- endif %}
    - gpgcheck: {{ repodata.get('gpgcheck', 1) }}
    - refresh:  {{ repodata.get('refresh', 1) }}

  {%- endfor %}

isv_zypper_refresh:
  cmd.run:
    - name: /usr/bin/zypper --non-interactive --gpg-auto-import-keys ref {{ repositories|join(' ') }}
    - onchanges:
{%- for repo_id in repositories %}
      - {{ repo_id }}
{%- endfor %}


{%- endif %}
