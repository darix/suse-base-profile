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

{%- if 'mgmt_ip_range' in pillar %}
ipset_install:
  pkg.installed:
    - names:
      - ipset
      - ipset-persistent

admin_hosts:
  ipset.set_present:
    - set_type: bitmap:ip
    - range: {{ pillar.mgmt_ip_range }}
    - comment: All hosts that should have ssh/rsync/nrpe access

{%- set needs_admin_hosts_dependency = false %}
{%- set admin_hosts_data = salt['mine.get'](pillar.admin_hosts, 'mgmt_ip_addrs', tgt_type='compound') | dictsort() %}
{%- if admin_hosts_data|length > 0 %}
{%- set needs_admin_hosts_dependency = true %}
ipset_admin_hosts:
  ipset.present:
    - set_name: admin_hosts
    - entry:
   {%- for host, addresses in admin_hosts_data %}
      {%- for address in addresses %}
      - {{ address }}
      {%- endfor %}
   {%- endfor %}
{%- endif %}

ipset_dump_once:
  cmd.run:
    - name: /usr/sbin/ipset save -file /etc/ferm/ipset
    - onchanges:
      - admin_hosts
      {%- if needs_admin_hosts_dependency %}
      - ipset_admin_hosts
      {%- endif %}
    - require:
      - ipset_install
      - admin_hosts
      {%- if needs_admin_hosts_dependency %}
      - ipset_admin_hosts
      {%- endif %}

ipset_persistent_service:
  service.running:
    - name: ipset-persistent
    - enable: True
    - require:
      - ipset_dump_once
{%- endif %}
