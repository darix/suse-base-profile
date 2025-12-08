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

{%- if 'salt' in pillar and 'master' in pillar.salt %}
salt_master_additional_packages:
  pkg.installed:
    - names:
      - acl
      - gopass
      - gopass-impersonate-pass
      - nsca-ng-client

master_drop_in:
  file.managed:
    - user: root
    - group: salt
    - mode: '0640'
    - template: jinja
    - names:
       - /etc/salt/master.d/salt_managed.conf:
         - source: salt://{{ slspath }}/files/etc/salt/master.d.config.j2

{%- if pillar.get("step:client_config:use_cron_force_renew", False) %}
salt_master_cert_refresh_cronjob:
  file.managed:
    - name: /etc/cron.daily/salt_step_ca_cert_mode_force_deploy
    - user: root
    - group: root
    - mode: '0750'
    - contents:
      - "#!/bin/bash"
      - "salt -N step_ca_cert_mode_force_deploy_nodes state.apply step-ca"
{%- else %}
salt_master_cert_refresh_cronjob:
  file.absent:
    - name: /etc/cron.daily/salt_step_ca_cert_mode_force_deploy
{%- for minion_id, fqdn in salt['mine.get']("N@step_ca_cert_mode_force_deploy_nodes", 'fqdn', tgt_type='compound') | dictsort() %}
force_deploy_service_{{ minion_id | regex_replace('\.-', '_') }}:
  service.running:
     - name: step-ca-renew-certificate-mode@{{ minion_id }}.timer
     - enable: True

{%- endfor %}
{%- endif %}
{%- endif %}

{%- if 'nsca_ng' in pillar and 'client' in pillar.nsca_ng and 'config' in pillar.nsca_ng.client %}
{%- set send_nsca_config = '/etc/send_nsca.cfg' %}
send_nsca_config:
  file.managed:
    - name: {{ send_nsca_config }}
    - user: root
    - group: nagios
    - mode: '0640'
    - contents:
      {%- for key, value in pillar.nsca_ng.client.config.items() %}
      - '{{ key }}="{{ value }}"'
      {%- endfor %}
  acl.present:
    - name: {{ send_nsca_config }}
    - acl_type: user
    - acl_name: salt
    - perms: r
    - require:
      - file: send_nsca_config
{%- endif %}

{%- if 'salt' in pillar and 'minion' in pillar.salt %}
salt_minion_pkg_installed:
  pkg.installed:
    - names:
      - salt-minion

minion_drop_in:
  file.managed:
    - user: root
    - group: salt
    - mode: '0640'
    - template: jinja
    - names:
       - /etc/salt/minion.d/salt_managed.conf:
         - source: salt://{{ slspath }}/files/etc/salt/minion.d.config.j2
    - require:
      - salt_minion_pkg_installed
{%- endif %}
