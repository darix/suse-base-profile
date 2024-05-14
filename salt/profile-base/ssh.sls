openssh_package:
   pkg.installed:
     - names:
       - openssh

# TODO: add support for ALP and friends
{%- if grains.osfullname == "openSUSE Tumbleweed" %}
{%- set config_path = "/etc/ssh/sshd_config.d/99-salt.conf" %}
{%- else %}
{%- set config_path = "/etc/ssh/sshd_config" %}
{%- endif %}

openssh_config:
  file.managed:
    - user: root
    - group: root
    - mode: '0600'
    - template: jinja
    - names:
      - {{ config_path }}:
        - source: salt://{{ slspath }}/files/etc/ssh/sshd_config.j2

openssh_service:
  service.running:
    - name: sshd
    - enable: True
    - watch:
      - openssh_config

