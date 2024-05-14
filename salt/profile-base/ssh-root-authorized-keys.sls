ssh-root-authorized-keys-dir:
  file.directory:
    - user: root
    - group: root
    - mode: '0755'
    - name: /root/.ssh

ssh-root-authorized-keys:
  file.managed:
    - user: root
    - group: root
    - mode: '0644'
    - template: jinja
    - names:
      - /root/.ssh/authorized_keys:
        - source: salt://{{ slspath }}/files/root/.ssh/authorized_keys.j2

