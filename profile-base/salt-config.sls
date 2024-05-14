{%- if 'salt' in pillar and 'master' in pillar.salt %}
salt_master_additional_packages:
  pkg.installed:
    - names:
      - acl
      - password-store
      - nsca-ng-client

master_drop_in:
  file.managed:
    - user: root
    - group: salt
    - mode: '0640'
    - template: jinja
    - names:
       - /etc/salt/master.d/salt_managed.conf:
         - source: salt://profile/base/files/etc/salt/master.d.config.j2

salt_master_cert_refresh_cronjob:
  file.managed:
    - name: /etc/cron.daily/salt_step_ca_cert_mode_force_deploy
    - user: root
    - group: root
    - mode: '0750'
    - contents:
      - "#!/bin/bash"
      - "salt -N step_ca_cert_mode_force_deploy_nodes state.apply step-ca"
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
         - source: salt://profile/base/files/etc/salt/minion.d.config.j2
    - require:
      - salt_minion_pkg_installed
{%- endif %}
