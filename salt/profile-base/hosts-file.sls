{%- if 'network' in pillar and 'resolver' in pillar.network and 'hosts' in pillar.network.resolver %}
etc_hosts:
  file.managed:
    - user: root
    - group: root
    - mode: '0644'
    - template: jinja
    - names:
      - /etc/hosts:
        - source: salt://{{ slspath }}/files/etc/hosts.j2
  cmd.run:
    - name: /usr/bin/systemctl reload dnsmasq.service
    - onlyif: /usr/bin/systemctl is-active dnsmasq.service
    - require:
      - file: etc_hosts
    - onchanges:
      - file: etc_hosts
{%- endif %}
