{% if 'sssd' in pillar %}
sssd_packages:
  pkg.installed:
    - names:
      - sssd
      - sssd-ldap
{%- if 'autofs' in pillar.sssd and pillar.sssd.autofs %}
      - autofs
{%- endif %}
# 32bit package needed as pam-config always wants the 32bit variant
{%- if grains.osrelease | float < 15.6 %}
      - sssd-common-32bit
{%- else %}
      - sssd-32bit
{%- endif %}

sssd_config:
  file.managed:
    - user: root
    - group: root
    - mode: 0600
    - template: jinja
    - names:
      - /etc/sssd/conf.d/salt.conf:
        - source: salt://profile/base/files/etc/sssd/conf.d/salt.conf.j2

sssd_pam_enable:
  cmd.run:
    - name: /usr/sbin/pam-config --add --sss
    - unless: "/usr/bin/grep -q 'pam_sss' /etc/pam.d/common-session-pc"

sssd_service:
  service.running:
    - name: sssd
    - enable: True
    - require:
      - sssd_pam_enable
    - watch:
      - sssd_config
{%- endif %}
