{%- if pillar.get('use_kexec_reboot', False) %}
kexec_tools_packages:
  pkg.installed:
    - pkgs:
      - kexec-tools

enable_kexex_load:
  service.enabled:
    - name: kexec-load.service
    - require:
      - kexec_tools_packages

change_reboot_target:
  file.symlink:
    - name: /etc/systemd/system/reboot.target
    - target: /usr/lib/systemd/system/kexec.target
    - user: root
    - group: root
    - require:
      - enable_kexex_load

run_systemctl_daemon_reload:
  cmd.run:
    - name: /usr/bin/systemctl daemon-reload
    - require:
      - change_reboot_target
    - onchanges:
      - change_reboot_target
{%- else %}
disable_kexex_load:
  service.disabled:
    - name: kexec-load.service
    - require_in:
      - kexec_tools_packages

change_reboot_target:
  file.absent:
    - name:  /etc/systemd/system/reboot.target

run_systemctl_daemon_reload:
  cmd.run:
    - name: /usr/bin/systemctl daemon-reload
    - require:
      - change_reboot_target
    - onchanges:
      - change_reboot_target
{%- endif %}