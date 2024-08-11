{%- if grains.osfullname == 'Leap' %}

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

  {%- set distro_basedir = 'distribution/leap/' ~ grains.osrelease %}
  {%- set update_basedir = 'leap/' ~ grains.osrelease %}

  {%- set only_has_updates   = ['backports', 'sle'] %}

  {%- set update_for_baserepo = False %}

  {%- for repo in only_has_updates %}
     {%- do repositories_list.append(repo) %}
  {%- endfor %}

  {%- set repositories = [] %}

{%- for repo in repositories_list %}

    {%- set repo_id   = "repo-" ~ repo %}


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
    - humanname:  {{ repo_id }}-update
    - name:       {{ repo_id }}-update
    - baseurl:    {{ baseurl }}/update/{{ update_basedir }}/{{ repo }}/
    - enabled: True
    - gpgcheck: True
    - refresh:    True


{%- if 'enable_debug' in pillar.zypp and pillar.zypp.enable_debug %}
  {%- set debug_repo_id = repo_id ~ '-debug' %}
  {%- do repositories.append(debug_repo_id) %}
{{ debug_repo_id }}:
  pkgrepo.managed:
    - humanname:  {{ debug_repo_id }}
    - name:       {{ debug_repo_id }}
    - baseurl:    {{ baseurl }}/debug/{{ distro_basedir }}/repo/{{ repo }}
    - enabled: True
    - gpgcheck: True
    - refresh:    {{ update_for_baserepo }}

  {%- set debug_repo_id = repo_id ~ '-update-debug' %}
  {%- do repositories.append(debug_repo_id) %}
{{ debug_repo_id }}:
  pkgrepo.managed:
    - humanname:  {{ debug_repo_id }}
    - name:       {{ debug_repo_id }}
    - baseurl:    {{ baseurl }}/update/{{ update_basedir }}/{{ repo }}_debug/
    - enabled: True
    - gpgcheck: True
    - refresh:    True
{%- endif %}

{%- if 'enable_source' in pillar.zypp and pillar.zypp.enable_source %}

  {%- set source_repo_id = repo_id ~ '-source' %}
  {%- do repositories.append(source_repo_id) %}

{{ source_repo_id }}:
  pkgrepo.managed:
    - humanname:  {{ source_repo_id }}
    - name:       {{ source_repo_id }}
    - baseurl:    {{ baseurl }}/source/{{ distro_basedir }}/repo/{{ repo }}
    - enabled: True
    - gpgcheck: True
    - refresh:    {{ update_for_baserepo }}
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
