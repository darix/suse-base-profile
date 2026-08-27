#!py
#
# suse-base-profile
#
# Copyright (C) 2026   darix
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
from salt.exceptions import SaltRenderError
import os
import logging

preserved_files = [
  '/etc/systemd/networkd.conf.d/routing_tables.conf',
]

def render_file_content(config, override_section, drop_in_file, file_data, restart_section):
  file_content = []
  if __salt__['pillar.get']('managed_by_salt', False):
    file_content.append(f"# {__salt__['pillar.get']('managed_by_salt')}")
  for section_name, section_data in file_data.items():
    file_content.append(f'[{section_name}]')
    if isinstance(section_data, list):
      file_content.extend(section_data)
    elif isinstance(section_data, dict):
      file_content.extend([f'{k}={v}' for k,v in section_data.items()])
    else:
      raise SaltRenderError(f'No idea how to handle {type(section_data)} for section_data')

  config[override_section] = {
    'file.managed': [
      {'name': drop_in_file},
      {'user': 'root'},
      {'group': 'root'},
      {'mode': '0644'},
      {'dir_mode': '0755'},
      {'watch_in': ['systemd_daemon_reload', restart_section]},
      {'contents': file_content},
    ]
  }


def reload_or_restart_job(config, service, restart_section, override_section, cleaned_service_name):
  reload_deps  = ['systemd_daemon_reload']
  require_deps = ['systemd_daemon_reload']

  if cleaned_service_name in __salt__['cp.list_states']():
    require_deps.append(cleaned_service_name)

  config[restart_section] = {
    'cmd.run': [
      { 'name': f'/usr/bin/systemctl try-reload-or-restart {service}'},
      { 'onlyif': '/usr/bin/systemctl is-active {service}'},
      { 'require': reload_deps},
      { 'watch': reload_deps},
      { 'onchanges': [override_section]},
    ]
  }

def walk_for_dropins(dirname):
  result = []
  if os.path.isdir(dirname):
    for filename in os.listdir(dirname):
      full_path = str(os.path.join(dirname, filename))
      if full_path.endswith('.d') and os.path.isdir(full_path):
        result.extend(walk_for_dropins(full_path))
      elif os.path.isfile(full_path) and dirname.endswith('.d'):
        result.append(full_path)
  for preserved_file in preserved_file:
    if preserved_file in result:
      result.remove(preserved_file)
  return result

def run():
  config = {}

  config['cleanup_systemd_journald_settings'] = {
    'file.absent': [
      {'name': '/etc/systemd/journald.conf'}
    ]
  }


  config['systemd_journald_directory'] = {
    'file.directory': [
      { 'name': '/var/log/journal'},
      { 'user': 'root' },
      { 'group': 'systemd-journal' },
      { 'dir_mode': '2755' },
    ]
  }

  existing_systemd_units = walk_for_dropins('/etc/systemd')
  systemd_units = []
  dropin_files  = []

  for systemd_part, systemd_part_settings in __salt__['pillar.get']('systemd:settings', {}).items():
    drop_in_file         = f'/etc/systemd/{systemd_part}.conf.d/99-salt.conf'
    service              = f'systemd-{systemd_part}.service'
    cleaned_service_name = service.replace('.', '_')
    override_section     = f'systemd_settings_{systemd_part}'
    restart_section      = f'systemd_settings_restart_{systemd_part}'

    systemd_units.append(override_section)
    if drop_in_file in existing_systemd_units:
      existing_systemd_units.remove(drop_in_file)

    render_file_content(config, override_section, drop_in_file, systemd_part_settings, restart_section)
    reload_or_restart_job(config, service, restart_section, override_section, cleaned_service_name)


  systemd_dir = '/etc/systemd/system'

  for service, service_data in __salt__['pillar.get']('systemd:overrides', {}).items():
    systemd_unit         = f'{systemd_dir}/{service}.d/99-salt.conf'
    cleaned_service_name = service.replace('.', '_')
    override_section     = f'systemd_override_{cleaned_service_name}'
    restart_section      = f'forced_restart_{cleaned_service_name}'

    systemd_units.append(override_section)
    if systemd_unit in existing_systemd_units:
      existing_systemd_units.append(systemd_unit)

    render_file_content(config, override_section, systemd_unit, service_data, restart_section)
    reload_or_restart_job(config, service, restart_section, override_section, cleaned_service_name)

  for filename in existing_systemd_units:
    config[f'remove_unmanaged_{filename}'] = {
      'file.absent': [
        {'name': filename},
        {'onchanges_in': ['systemd_daemon_reload']},
      ]
    }

  all_units = systemd_units + dropin_files
  if len(all_units) > 0:
    config['systemd_daemon_reload'] = {
      'module.run': [
        { 'name': 'service.systemctl_reload'},
        { 'onchanges': all_units },
      ]
    }

  return config
