{%- if "locale" in pillar and "language" in pillar.locale %}
{%- set locale_language = pillar.locale.language %}
{%- else %}
{%- set locale_language = "en_US.UTF-8" %}
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
    - contents: "LANG={{ locale_language }}"
