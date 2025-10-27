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

{%- if grains.osfullname == 'Leap' %}

  {%- set obs_instance = 'obs' %}

  {%- if 'baseurl' in pillar.zypp %}
  {%- set baseurl = pillar.zypp.baseurl %}
  {%- else %}
  {%- set baseurl = "https://download." ~ grains.domain %}
  {%- endif %}

  {%- if "always_use_obs_instance" in pillar.zypp and pillar.zypp.always_use_obs_instance %}
    {%- set baseurl = "{baseurl}/{obs_instance}".format(baseurl=baseurl, obs_instance=obs_instance) %}
  {%- endif %}

  {%- set repositories_list = ['oss'] %}

  {%- set only_has_updates   = [] %}

  {%- if 'enable_non_oss' in pillar.zypp and pillar.zypp.enable_non_oss %}
      {%- do repositories_list.append('non-oss') %}
  {%- endif %}

  {%- set distro_basedir = 'distribution/leap/' ~ grains.osrelease %}
  {%- set update_basedir = 'leap/' ~ grains.osrelease %}

  {%- set only_has_updates   = ['backports', 'sle'] %}

  {%- set update_for_baserepo = False %}

  {%- for repo in only_has_updates %}
     {%- do repositories_list.append(repo) %}
  {%- endfor %}

  {%- set repositories = [] %}

{%- for repo in repositories_list %}

    {%- set repo_id              = "repo-" ~ repo %}

    {%- set debug_repo_id        = repo_id ~ '-debug' %}
    {%- set debug_update_repo_id = repo_id ~ '-update-debug' %}
    {%- set source_repo_id       = repo_id ~ '-source' %}

{%- if not(repo in only_has_updates) %}
    {%- do repositories.append(repo_id) %}

{{ repo_id }}:
  pkgrepo.managed:
    - humanname:  {{ repo_id }}
    - name:       {{ repo_id }}
    - baseurl:    {{ baseurl }}/{{ distro_basedir }}/repo/{{ repo }}/
    - enabled: True
    - gpgcheck: True
    - refresh:    {{ update_for_baserepo }}
{%- endif %}

    {%- set update_repo_id = repo_id ~ '-update' %}
    {%- do repositories.append(update_repo_id) %}
{{ update_repo_id }}:
  pkgrepo.managed:
    - humanname:  {{ update_repo_id }}
    - name:       {{ update_repo_id }}
    - baseurl:    {{ baseurl }}/update/{{ update_basedir }}/{{ repo }}/
    - enabled: True
    - gpgcheck: True
    - refresh:    True

{%- if repo in ["oss", "non-oss"] %}

  {%- if 'enable_debug' in pillar.zypp and pillar.zypp.enable_debug %}

    {%- do repositories.append(debug_repo_id) %}
    {%- do repositories.append(debug_update_repo_id) %}

{{ debug_repo_id }}:
  pkgrepo.managed:
    - humanname:  {{ debug_repo_id }}
    - name:       {{ debug_repo_id }}
    - baseurl:    {{ baseurl }}/debug/{{ distro_basedir }}/repo/{{ repo }}
    - enabled: True
    - gpgcheck: True
    - refresh:    {{ update_for_baserepo }}

{{ debug_update_repo_id }}:
  pkgrepo.managed:
    - humanname:  {{ debug_update_repo_id }}
    - name:       {{ debug_update_repo_id }}
    - baseurl:    {{ baseurl }}/update/{{ update_basedir }}/{{ repo }}_debug/
    - enabled: True
    - gpgcheck: True
    - refresh:    True

  {%- else %}

{{ debug_repo_id }}:
  pkgrepo.absent:
    - name:       {{ debug_repo_id }}

{{ debug_update_repo_id }}:
  pkgrepo.absent:
    - name:       {{ debug_update_repo_id }}

  {%- endif %}

  {%- if 'enable_source' in pillar.zypp and pillar.zypp.enable_source %}

    {%- do repositories.append(source_repo_id) %}

{{ source_repo_id }}:
  pkgrepo.managed:
    - humanname:  {{ source_repo_id }}
    - name:       {{ source_repo_id }}
    - baseurl:    {{ baseurl }}/source/{{ distro_basedir }}/repo/{{ repo }}
    - enabled: True
    - gpgcheck: True
    - refresh:    {{ update_for_baserepo }}

  {%- else %}

{{ source_repo_id }}:
  pkgrepo.absent:
    - name:       {{ source_repo_id }}

  {%- endif %}
{%- endif %}

{%- endfor %}

opensuse_zypper_refresh:
  cmd.run:
    - name: /usr/bin/zypper --non-interactive --gpg-auto-import-keys ref {{ repositories|join(' ') }}
    - onchanges:
{%- for repo_id in repositories %}
      - {{ repo_id }}
{%- endfor %}

{%- endif %}
