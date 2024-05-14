{%- if 'repositories' in pillar.zypp %}

  {%- if 'baseurl' in pillar.zypp %}
  {%- set baseurl = pillar.zypp.baseurl %}
  {%- else %}
  {%- set baseurl = "http://download." ~ grains.domain %}
  {%- endif %}

  {%- set repositories = [] %}

  {%- for obs_instance, repositories_list in pillar.zypp.repositories.items() %}

    {%- if "always_use_obs_instance" in pillar.zypp and pillar.zypp.always_use_obs_instance %}
      {%- set baseurl = "{baseurl}/{obs_instance}".format(baseurl=baseurl, obs_instance=obs_instance) %}
    {%- endif %}

    {%- if obs_instance == 'obs' %}
      {%- set baseurl = "{baseurl}/repositories".format(baseurl=baseurl) %}
    {%- endif %}

    {%- for repo_id, project_name in repositories_list.items() %}

      {%- do repositories.append(repo_id) %}

      {%- set project_name_for_url = project_name | regex_replace(':', ':/') %}
      {%- set repo_base_url = "{baseurl}/{project_name_for_url}/".format(baseurl=baseurl, project_name_for_url=project_name_for_url) %}  # noqa: 204
      {%- set repo_url = salt['zypp_helper.guess_repository'](repo_base_url) %}

{{ repo_id }}:
  pkgrepo.managed:
    - name:       {{ repo_id }}
    - humanname:  {{ project_name }}
    - baseurl:    {{ repo_url }}
    - gpgcheck: 1
    - refresh: True

    {%- endfor %}
  {%- endfor %}

isv_zypper_refresh:
  cmd.run:
    - name: /usr/bin/zypper --non-interactive --gpg-auto-import-keys ref {{ repositories|join(' ') }}
    - onchanges:
{%- for repo_id in repositories %}
      - {{ repo_id }}
{%- endfor %}


{%- endif %}
