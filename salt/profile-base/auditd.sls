#
# suse-base-profile
#
# Copyright (C) 2025   darix
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
{%-
  set default_settings = {
    'local_events': 'yes',
    'write_logs': 'yes',
    'log_file': '/var/log/audit/audit.log',
    'log_group': 'audit',
    'log_format': 'RAW',
    'flush': 'INCREMENTAL_ASYNC',
    'freq': '50',
    'max_log_file': '8',
    'num_logs': '5',
    'priority_boost': '4',
    'name_format': 'NONE',
    '##name': 'mydomain',
    'max_log_file_action': 'ROTATE',
    'space_left': '75',
    'space_left_action': 'SYSLOG',
    'verify_email': 'yes',
    'action_mail_acct': 'root',
    'admin_space_left': '50',
    'admin_space_left_action': 'SUSPEND',
    'disk_full_action': 'SUSPEND',
    'disk_error_action': 'SUSPEND',
    'use_libwrap': 'yes',
    '##tcp_listen_port': '60',
    'tcp_listen_queue': '5',
    'tcp_max_per_addr': '1',
    '##tcp_client_ports': '1024-65535',
    'tcp_client_max_idle': '0',
    'transport': 'TCP',
    'distribute_network': 'no',
    'q_depth': '2000',
    'overflow_action': 'SYSLOG',
    'max_restarts': '10',
    'plugin_dir': '/etc/audit/plugins.d',
    'end_of_event_timeout': '2',
  }
%}

auditd_packages:
  pkg.installed:
    - names:
      - audit
      - audit-audispd-plugins

auditd_config:
  file.managed:
    - name: /etc/audit/auditd.conf
    - user: root
    - group: root
    - mode: '0640'
    - require:
      - auditd_packages
    - contents:
      - '#'
      - '# This file controls the configuration of the audit daemon'
      - '#'
      - ''
      {%- for key, value in salt['pillar.get']('auditd:config', default=default_settings, merge=True).items() %}
      - "{{ key }} = {{ value }}"
      {%- endfor %}


auditd_service:
   service.running:
    - name: auditd
    - enable: True
    - require:
      - auditd_config
    - watch:
      - auditd_config
