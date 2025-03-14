uninstall_syslog_ng_package:
  pkg.removed:
    - names:
      - syslog-ng

{%- if 'syslog' in pillar %}
{%- set rsyslog_version_dep = '>= 8.2406.0' %}
rsyslog_package:
  pkg.installed:
    - pkgs:
      - librelp0: '1.11.0'
      - rsyslog: '{{ rsyslog_version_dep }}'
      - rsyslog-module-relp: '{{ rsyslog_version_dep }}'
    - require:
      - uninstall_syslog_ng_package

rsyslog_remote_host:
  file.managed:
    - user: root
    - group: root
    - mode: '0644'
    - template: jinja
    - require:
      - rsyslog_package
    - names:
      - /etc/rsyslog.d/remote.conf:
        - source: salt://{{ slspath }}/files/etc/rsyslog.d/remote.conf.j2

rsyslog_service:
  service.running:
    - name: rsyslog
    - enable: True
    - require:
      - rsyslog_remote_host
    - watch:
      - rsyslog_remote_host
    - onchanges:
      - rsyslog_remote_host
{%- endif %}
