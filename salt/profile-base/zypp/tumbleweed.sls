{%- if grains.oscodename == 'openSUSE Tumbleweed' %}

  {%- set obs_instance = 'obs' %}

  {%- if 'baseurl' in pillar.zypp %}
  {%- set baseurl = pillar.zypp.baseurl %}
  {%- else %}
  {%- set baseurl = "http://download." ~ grains.domain %}
  {%- endif %}

  {%- if "always_use_obs_instance" in pillar.zypp and pillar.zypp.always_use_obs_instance %}
    {%- set baseurl = "{baseurl}/{obs_instance}".format(baseurl=baseurl, obs_instance=obs_instance) %}
  {%- endif %}

  {%- set repositories_list = ['oss'] %}

  {%- set only_has_updates   = [] %}

  {%- if 'enable_non_oss' in pillar.zypp %}
      {%- do repositories_list.append('non-oss') %}
  {%- endif %}

  {%- set distro_basedir = 'tumbleweed' %}
  {%- set update_basedir = 'tumbleweed' %}
  {%- set update_for_baserepo = True %}

  {%- set repositories = [] %}

{%- for repo in repositories_list %}

    {%- set repo_id        = "repo-" ~ repo      %}
    {%- set update_repo_id = repo_id ~ "-update" %}
    {%- set debug_repo_id  = repo_id ~ "-debug"  %}
    {%- set source_repo_id = repo_id ~ "-source" %}

    {%- set update_dir     = update_basedir      %}

    {%- if repo == "non-oss" %}
      {%- set update_dir     = update_basedir ~ '-' ~ repo %}
    {%- endif %}

    {%- do repositories.append(repo_id) %}

{{ repo_id }}:
  pkgrepo.managed:
    - humanname:  {{ repo_id }}
    - name:       {{ repo_id }}
    - baseurl:    {{ baseurl }}/{{ distro_basedir }}/repo/{{ repo }}/
    - enabled:    True
    - gpgcheck:   True
    - refresh:    {{ update_for_baserepo }}

    {%- do repositories.append(update_repo_id) %}

{{ update_repo_id }}:
  pkgrepo.managed:
    - humanname:  {{ update_repo_id }}
    - name:       {{ update_repo_id }}
    - baseurl:    {{ baseurl }}/update/{{ update_dir }}/
    - enabled:    True
    - gpgcheck:   True
    - refresh:    True

    {%- if repo == 'oss' %}
      {%- if 'enable_debug' in pillar.zypp and pillar.zypp.enable_debug %}
        {%- do repositories.append(debug_repo_id) %}

{{ debug_repo_id }}:
  pkgrepo.managed:
    - humanname:  {{ debug_repo_id }}
    - name:       {{ debug_repo_id }}
    - baseurl:    {{ baseurl }}/debug/{{ distro_basedir }}/repo/{{ repo }}
    - enabled: True
    - gpgcheck: True
    - refresh:    {{ update_for_baserepo }}

      {%- else %}

{{ debug_repo_id }}:
  pkgrepo.absent:
    - name:       {{ debug_repo_id }}

      {%- endif %}
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

    {% else %}

{{ source_repo_id }}:
  pkgrepo.absent:
    - name:       {{ source_repo_id }}

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
