logrotate_package:
   pkg.installed:
     - names:
       - logrotate

logrotate_timer:
  service.running:
   - name: logrotate.timer
   - enable: True
