{%- set content = [] %}

{%- if "locale" in pillar and "language" in pillar.locale %}
{%- do content.append("LANG=" ~ pillar.locale.language) %}
{%- set locale_language = pillar.locale.language %}
{%- else %}
{%- do content.append("LANG=en_US.UTF-8") %}
{%- set locale_language = "en_US.UTF-8" %}
{%- endif %}

{%- if "locale" in pillar and "formats" in pillar.locale %}
{% for format, value in pillar.locale.formats.items() %}
{%- do content.append("LC_" ~ format|upper ~ "=" ~ value) %}
{%- endfor %}
{%- endif %}

locale_packages:
  pkg.installed:
    - names:
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
    - contents:
      {% if "greeting" in pillar %}
      - '# {{ pillar.greeting }}'
      {%- endif %}
      {%- for line in content %}
      - {{ line }}
      {%- endfor %}