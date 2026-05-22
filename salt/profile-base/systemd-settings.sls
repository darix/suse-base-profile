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


# systemd:
#   overrides:
#     nginx.service:
#       Service:
#         - ExecStartPre=
#         - ExecStartPre=/usr/sbin/nginx -T
#         - LimitNOFILE=16384
#   settings:
#     resolved:
#       Resolve:
#         DNS: 192.168.1.3#fortress.home.nordisch.org
#         FallbackDNS: '5.9.115.232#bakfiet.nordisch.org 2a01:4f8:162:60b1::2#bakfiet.nordisch.org'
#         Domains: 'nordisch.org fritz.box'
#         DNSOverTLS: 'yes'
#         DNSSEC: 'yes'
#         Cache: 'yes'
#     journald:
#       'Journal':
#         'Storage': 'persistent'
#         'ForwardToSyslog': 'yes'
#         'SystemKeepFree': '1G'

{%- macro render_file_content(file_data) %}
      {%- if 'managed_by_salt' in pillar %}
      - "# {{ pillar.managed_by_salt }}"
      {%- endif %}
      {%- for section_name, section_data in file_data.items() %}
      - '[{{ section_name }}]'
      {%- if section_data is list %}
      {%-   for setting_data in section_data %}
      - {{ setting_data }}
      {%-   endfor %}
      {%- else %}
      {%- for k,v in section_data.items() %}
      - {{ k }}={{ v }}
      {%- endfor %}
      {%- endif %}
      {%- endfor %}
{%- endmacro %}

{%- macro reload_or_restart_job(service, restart_section, override_section, cleaned_service_name) %}
{{ restart_section }}:
  cmd.run:
    - name: '/usr/bin/systemctl try-reload-or-restart {{ service }}'
    - onlyif: '/usr/bin/systemctl is-active {{ service }}'
    {%- if cleaned_service_name in salt['cp.list_states']() %}
    - require:
      - {{ cleaned_service_name }}
    {%- endif %}
    - onchanges:
      - systemd_daemon_reload
    - require:
      - systemd_daemon_reload
    - watch:
      - systemd_daemon_reload
    - onchanges:
      - {{ override_section }}
{%- endmacro %}

cleanup_systemd_journald_settings:
  file.absent:
    - name: /etc/systemd/journald.conf

systemd_journald_directory:
  file.directory:
    - name: /var/log/journal
    - user: root
    - group: systemd-journal
    - dir_mode: '2755'

{%- for systemd_part, systemd_part_settings in salt['pillar.get']('systemd:settings', {}).items() %}
{%- set drop_in_file = '/etc/systemd/' ~ systemd_part ~ '.conf.d/99-salt.conf' %}
{%- set service = 'systemd-'~ systemd_part ~ '.service' %}
{%- set cleaned_service_name = service.replace('.', '_') %}
{%- set override_section = 'systemd_settings_' ~ systemd_part %}
{%- set restart_section = 'systemd_settings_restart_' ~ systemd_part %}
{{ override_section }}:
  file.managed:
    - name: {{ drop_in_file }}
    - makedirs: true
    - dir_mode: '0755'
    - mode: '0644'
    - user: root
    - group: root
    - watch_in:
      - systemd_daemon_reload
    - contents:
{{ render_file_content(systemd_part_settings) }}

{{ reload_or_restart_job(service, restart_section, override_section, cleaned_service_name) }}

{%- endfor %}

{%- set systemd_dir = '/etc/systemd/system' %}
{%- set systemd_units = [] %}

{%- if 'systemd' in pillar %}
{%-   if 'overrides' in pillar.systemd %}
{%-     for service, service_data in pillar.systemd.overrides.items() %}

{%-       set systemd_unit         = systemd_dir ~ "/" ~ service ~ ".d/99-salt.conf" %}
{%-       set cleaned_service_name = service.replace('.', '_') %}
{%-       set override_section     = "systemd_override_" ~ cleaned_service_name %}
{%-       set restart_section      = "forced_restart_" ~ cleaned_service_name %}

{%-       do systemd_units.append(override_section) %}

{{ override_section }}:
  file.managed:
    - name: {{ systemd_unit }}
    - makedirs: true
    - dir_mode: '0755'
    - mode: '0644'
    - user: root
    - group: root
    - watch_in:
      - systemd_daemon_reload
      - {{ restart_section }}
    - contents:
{{ render_file_content(service_data) }}

{{ reload_or_restart_job(service, restart_section, override_section, cleaned_service_name) }}
{%- endfor %}

systemd_daemon_reload:
  module.run:
    - name: service.systemctl_reload
    - onchanges:
    {%- for service in systemd_units %}
      - {{ service }}
    {%- endfor %}

{%-   endif %}
{%- endif %}
