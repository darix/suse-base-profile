{%- if "monitoring" in pillar %}
monitoring_packages:
  pkg.installed:
    - pkgs:
{%- if grains.virtual == 'physical' %}
      - monitoring-plugins-bonding
{%- endif %}
      - monitoring-plugins-common
      - monitoring-plugins-cpu_stats
      - monitoring-plugins-disk
      - monitoring-plugins-eth
      - monitoring-plugins-http
{%- if grains.virtual == 'physical' %}
      - monitoring-plugins-ipmi-sensor1
{%- endif %}
      - monitoring-plugins-load
      - monitoring-plugins-logrotate
      - monitoring-plugins-mailq
      - monitoring-plugins-mem
{%- if grains.virtual == 'physical' %}
      - monitoring-plugins-multipath
      - monitoring-plugins-md_raid
      - monitoring-plugins-smart
{%- endif %}
      - monitoring-plugins-ntp_time
      - monitoring-plugins-procs
      - monitoring-plugins-running_kernel
      - monitoring-plugins-sar-perf
      - monitoring-plugins-swap
      - monitoring-plugins-systemd_service
      - monitoring-plugins-users
      - monitoring-plugins-zypper
      - nrpe: '>= 4'
      - sudo


nrpe_cleanup_old_config:
  file.absent:
    - name: /etc/nrpe.d/99-salt.cfg

nrpe_d_config:
  file.managed:
    - user: root
    - group: root
    - mode: '0644'
    - template: jinja
    - require:
      - monitoring_packages
    - names:
      - /etc/nrpe.d/zzz-salt.cfg:
        - source: salt://{{ slspath }}/files/etc/nrpe.d/99-salt.cfg.j2

nrpe_config:
  file.replace:
    - name: /etc/nrpe.cfg
    - ignore_if_missing: True
    - pattern: '^(# *)?allowed_hosts=.*'
{%- if 'monitoring' in pillar and 'server' in pillar.monitoring and 'addresses' in pillar.monitoring.server %}
    - repl: allowed_hosts={{ pillar.monitoring.server.addresses|join(',') }}
{%- else %}
    - repl: allowed_hosts=127.0.0.1,::1
{%- endif %}
    - require:
      - monitoring_packages

nrpe_sudo_rules:
  file.managed:
    - user: root
    - group: root
    - mode: '0400'
    - template: jinja
    - require:
      - monitoring_packages
    - names:
      - /etc/sudoers.d/99-salt-monitoring:
        - source: salt://{{ slspath }}/files/etc/sudoers.d/99-salt-monitoring.j2

{%- if 'check_haproxy' in pillar.monitoring.checks and 'nagiosgroups' in pillar.monitoring %}
fix_nagios_user_groups_for_haproxy:
  user.present:
    - name: nagios
    - groups:
  {%- for entry in pillar.monitoring.nagiosgroups | sort %}
      - {{ entry }}
  {%- endfor %}
    - require:
      - monitoring_packages
      - haproxy.install
    - require_in:
      - nrpe_service
    - onchanges_in:
      - nrpe_service
{%- endif %}


nrpe_service:
  service.running:
    - name: nrpe
    - enable: True
    - watch:
      - nrpe_config
      - nrpe_d_config
{%- endif %}
