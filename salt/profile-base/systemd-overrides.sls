# systemd:
#   overrides:
#     nginx.service:
#       Service:
#         - ExecStartPre=
#         - ExecStartPre=/usr/sbin/nginx -T
#         - LimitNOFILE=16384

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
      {%- if 'managed_by_salt' in pillar %}
      - "# {{ pillar.managed_by_salt }}"
      {%- endif %}

      {%- for section_name, section_data in service_data.items() %}
      - '[{{ section_name }}]'
      {%-   for setting_data in section_data %}
      - {{ setting_data }}
      {%-   endfor %}
      {%- endfor %}

{{ restart_section }}:
  cmd.run:
    - name: '/usr/bin/systemctl try-restart {{ service }}'
    {%- if cleaned_service_name in salt['cp.list_states']() %}
    - require:
      - {{ cleaned_service_name }}
    {%- endif %}
    - watch:
      - systemd_daemon_reload
    - onchanges:
      - {{ override_section }}

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
