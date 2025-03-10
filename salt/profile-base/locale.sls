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
