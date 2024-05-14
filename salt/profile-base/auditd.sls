auditd_packages:
   pkg.installed:
    - names:
      - audit
      - audit-audispd-plugins

auditd_service:
   service.running:
    - name: auditd
    - enable: True
