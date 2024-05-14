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
