openssh_package:
   pkg.installed:
     - names:
       - openssh

openssh_config:
  file.managed:
    - user: root
    - group: root
    - mode: '0600'
    - template: jinja
    - names:
      - /etc/ssh/sshd_config:
        - source: salt://profile/base/files/etc/ssh/sshd_config.j2

openssh_service:
  service.running:
    - name: sshd
    - enable: True
    - watch:
      - openssh_config

