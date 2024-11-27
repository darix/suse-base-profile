{%- from 'profile-base/helpers/networkd_helpers.sls' import networkd_config  %}

systemd_network_packages:
  pkg.installed:
   - names:
     - systemd-network

# other types of systemd-network files need:
#  1. define file naming index
#  2. add to the logic below

{%- set base_indices = { 'bonds': 0, 'hw_devs': 1, 'vlans': 3, 'bridges': 5 } %}

{%- if 'systemd' in pillar %}
{%-   if 'networkd' in pillar.systemd %}
{%-     for devtype, base_index in base_indices.items() %}

{%-       if devtype in pillar.systemd.networkd %}

{%-         set current_sub_pillar = pillar.systemd.networkd[devtype] %}
{%-         set network_files = None %}
{%-         set netdev_files  = None %}
{%-         set link_files    = None %}

{%-         if 'network_files' in current_sub_pillar %}
{%-           set network_files = current_sub_pillar.network_files %}
{%-         endif %}

{%-         if 'netdev_files' in current_sub_pillar %}
{%-           set netdev_files = current_sub_pillar.netdev_files %}
{%-         endif %}

{%-         if 'link_files' in current_sub_pillar %}
{%-           set link_files = current_sub_pillar.link_files %}
{%-         endif %}

{{ networkd_config(devtype, base_index, network_files, netdev_files, link_files) }}

{%-       endif %}
{%      endfor %}

wicked_disable:
  service.dead:
    - name: wicked
    - enable: False

systemd_networkd:
  service.running:
    - name: systemd-networkd
    - enable: true
    - require:
      - wicked_disable
      - systemd_network_packages

systemd_networkctl_reload:
  cmd.run:
    - name: '/usr/bin/networkctl reload'
    - require:
      - systemd_networkd

{%-   endif %}
{%- endif %}
