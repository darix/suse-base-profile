systemd_journald_settings:
  ini.options_present:
    # TODO: change to drop in for TW/ALP
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
    - require:
      - systemd_journald_settings
    - onchanges:
      - systemd_journald_settings
    - watch:
      - systemd_journald_settings
