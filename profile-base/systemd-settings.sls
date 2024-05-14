systemd_journald_settings:
  ini.options_present:
    - name: /etc/systemd/journald.conf
    - separator: '='
    - strict: True
    - sections:
        'Journal':
          'Storage': 'persistent'
          'ForwardToSyslog': 'yes'
          'SystemKeepFree': '1G'

systemd_journald_directory:
  file.directory:
    - name: /var/log/journal
    - user: root
    - group: systemd-journal
    - dir_mode: '2755'

systemd_journald_service:
  service.running:
    - name: systemd-journald
    - enable: True
    - watch:
      - systemd_journald_settings
