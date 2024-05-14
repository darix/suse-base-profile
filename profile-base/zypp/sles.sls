{%- if grains.osfullname == "SLES" %}
  {%- set obs_instance = 'ibs' %}

  {%- if grains['osrelease_info']|length > 1 %}
    {%- set product_release =          grains.osrelease_info[0] ~ "-SP" ~ grains.osrelease_info[1] %}
    {%- set repo_name       = "SLE_" ~ grains.osrelease_info[0] ~ "_SP" ~ grains.osrelease_info[1] %}
    {%- if grains.osrelease is equalto("15.5") %}
    {%- set previous_product_release =          grains.osrelease_info[0] ~ "-SP4" %}
    {%- set previous_repo_name       = "SLE_" ~ grains.osrelease_info[0] ~ "_SP4" %}
    {%- endif %}
  {%- else %}
    {%- set product_release =          grains.osrelease_info[0] %}
    {%- set repo_name       = "SLE_" ~ grains.osrelease_info[0] %}
  {%- endif %}

  {%- if 'baseurl' in pillar.zypp %}
  {%- set baseurl = pillar.zypp.baseurl %}
  {%- else %}
  {%- set baseurl = "http://download." ~ grains.domain %}
  {%- endif %}

  {%- set repositories = [] %}

# TODO: This needs if grains.osfullname == "SLES" and then an opensuse case too
  {%- for product_name in pillar.zypp.products[grains.osmajorrelease] %}
    {%- for repo_type in [ 'Product', 'Update' ] %}

      {%- set repo_id   = product_name ~ "-" ~ repo_type %}
      {%- do repositories.append(repo_id) %}

{{ repo_id }}:

    {%- if grains.osmajorrelease == 12 and product_name is match('^SLE-Module')  %}
      {%- set product_release = 12 %}
    {%- endif %}

  pkgrepo.managed:
    - humanname:  {{ repo_id }}
    - name:       {{ repo_id }}
    - baseurl:    {{ baseurl }}/{{ obs_instance }}/SUSE/{{ repo_type }}s/{{ product_name }}/{{ product_release }}/{{ grains.osarch }}/{{ repo_type | lower }}
    - gpgcheck: 1
    {%- if repo_type is equalto('Update') %}
    - refresh: True
    {%- endif %}

{%- if repo_type is equalto('Update') %}
  {%- if grains.osrelease is equalto("15.5") %}

      {%- set repo_id_sp4   = product_name ~ "-" ~ repo_type ~ "-SP4" %}
{{ repo_id_sp4 }}:
  pkgrepo.absent:
    - name:       {{ repo_id_sp4 }}
  {%- endif %}
{%- endif %}

    {%- if 'products_enable_debug' in pillar.zypp and pillar.zypp.products_enable_debug %}
      {%- do repositories.append(repo_id ~ '_Debug') %}

{{ repo_id }}_Debug:

  pkgrepo.managed:
    - humanname:  {{ repo_id }}_Debug
    - name:       {{ repo_id }}_Debug
    - baseurl:    {{ baseurl }}/{{ obs_instance }}/SUSE/{{ repo_type }}s/{{ product_name }}/{{ product_release }}/{{ grains.osarch }}/{{ repo_type | lower }}_debug  # noqa: 204
    - gpgcheck: 1
    {%- if repo_type is equalto('Update') %}
    - refresh: True
    {%- endif %}
  {%- endif %}

  {%- endfor %}
{%- endfor %}

{%- if 'products_enable_backports' in pillar.zypp and pillar.zypp.products_enable_backports %}
      {%- set repo_id = "Packagehub" %}
      {%- do repositories.append(repo_id) %}

{{ repo_id }}:

  pkgrepo.managed:
    - humanname:  {{ repo_id }}
    - name:       {{ repo_id }}
    - baseurl:    {{ baseurl }}/{{ obs_instance }}/SUSE/Backports/SLE-{{ product_release }}_{{ grains.osarch }}/standard  # noqa: 204
    - gpgcheck: 1
{%- endif %}

sles_zypper_refresh:
  cmd.run:
    - name: /usr/bin/zypper --non-interactive --gpg-auto-import-keys ref {{ repositories|join(' ') }}
    - require:
{%- for repo_id in repositories %}
      - {{ repo_id }}
{%- endfor %}
    - onchanges:
{%- for repo_id in repositories %}
      - {{ repo_id }}
{%- endfor %}
{%- endif %}
