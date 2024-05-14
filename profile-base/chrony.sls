cleanup_ntp:
  pkg.removed:
    - pkgs:
      - ntp

chrony_package:
   pkg.installed:
     - names:
       - chrony

chrony_config:
  file.managed:
    - user: root
    - group: chrony
    - mode: '0640'
    - template: jinja
    - require:
      - chrony_package
    - names:
      - /etc/chrony.conf:
        - source: salt://{{ slspath }}/files/etc/chrony.conf.j2

chrony_service:
  service.running:
    - name: chronyd
    - enable: True
    - require:
      - cleanup_ntp
    - watch:
      - chrony_config

