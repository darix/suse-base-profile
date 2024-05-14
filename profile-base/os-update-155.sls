os_release:
    file.managed:
    - user: root
    - group: root
    - mode: '0644'
    - names:
      - /etc/os-release:
        - source: salt://profile/base/files/etc/os-release-15.5
