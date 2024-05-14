timezone_packages:
  pkg.installed:
    - names:
      - timezone

timezone_symlink:
   file.symlink:
     - name: /etc/localtime
     - target: /usr/share/zoneinfo/{{ pillar.get('timezone', 'UTC') }}