{%- if 'check_zypper' in  pillar.zypp %}
#
# the directory is more of a fallback as all our new checks use the monitoring-plugins path ... so make sure it is available
#
zypper_nagios_base_dir:
  file.directory:
    - user: root
    - group: root
    - mode: 0755
    - name: /etc/nagios/

#
# This directory must be generated in advance if no
# monitoring-plugins-* packages are installed while 
# bootstrapping
#
zypper_monitoring_plugins_base_dir:
  file.directory:
    - user: root
    - group: root
    - mode: 0755
    - name: /etc/monitoring-plugins/

zypper_check_ignores:
  file.managed:
    - user: root
    - group: root
    - mode: 0644
    - template: jinja
    - names:
      - /etc/monitoring-plugins/check_zypper-ignores.txt:
        - source: salt://{{ slspath }}/files/etc/monitoring-plugins/check_zypper-ignores.txt.j2
      - /etc/nagios/check_zypper-ignores.txt:
        - source: salt://{{ slspath }}/files/etc/monitoring-plugins/check_zypper-ignores.txt.j2
{%- endif %}
