cron_package:
  pkg.installed:
    - names:
      - cronie

cron_service:
  service.running:
    - name: cron
    - enable: True