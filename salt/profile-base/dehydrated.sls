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

{%- if 'dehydrated' in pillar %}
# TODO: for instances support we need a check if we have any instances with certs
{%-   if 'certs' in pillar.dehydrated and pillar.dehydrated.certs|length > 0 %}

{%-     set run_immediately = true %}
{%-     if 'run_immediately' in pillar.dehydrated %}
{%-       set run_immediately = pillar.dehydrated.run_immediately %}
{%-     endif %}

{%-     set enable_timer = true %}
{%-     if 'enable_timer' in pillar.dehydrated %}
{%-       set enable_timer = pillar.dehydrated.enable_timer %}
{%-     endif %}

{%-     set deploy_hooks = true %}
{%-     if 'deploy_hooks' in pillar.dehydrated %}
{%-       set deploy_hooks = pillar.dehydrated.deploy_hooks %}
{%-     endif %}

{%-     set use_acmeresponder = false %}
{%-     if 'use_acmeresponder' in pillar.dehydrated %}
{%-       set use_acmeresponder = pillar.dehydrated.use_acmeresponder %}
{%-     endif %}

{%-     set cert_services     = [] %}
{%-     set cert_postrunhooks = [] %}
{%-     set cert_acls         = [] %}

dehydrated_package:
  pkg.installed:
    - pkgs:
      - dehydrated: '>= 0.7.1'
      - acl
      {%- if 'use_apache' in pillar.dehydrated and pillar.dehydrated.use_apache %}
      - dehydrated-apache2: '>= 0.7.1'
      {%- endif %}
      {%- if 'use_nginx' in pillar.dehydrated and pillar.dehydrated.use_nginx %}
      - dehydrated-nginx: '>= 0.7.1'
      {%- endif %}
      {%- if use_acmeresponder %}
      - dehydrated-acmeresponder
      {%- endif %}

dehydrated_domains_d:
  file.directory:
    - name: /etc/dehydrated/domains.d/
    - user: root
    - group: dehydrated
    - mode: '0750'
    - require:
      - dehydrated_package

dehydrated_services:
  file.directory:
    - name: /etc/ssl/services/
    - user: dehydrated
    - group: dehydrated
    - mode: '0711'

{%-     if 'config' in pillar.dehydrated %}
{%-       set setting = 'CONFIG_D' %}
{%-       set value   = '${BASEDIR}/config.d' %}
#
# make sure that config.d is loaded
#
dehydrated_config_config_d:
  file.replace:
    - name: /etc/dehydrated/config
    - pattern: '^{{ setting }} *=.*'
    - repl: '{{ setting }}="{{ value }}"'
    - append_if_not_found: true
    - require:
      - dehydrated_package

dehydrated_config_config_d_salt:
  file.managed:
    - user: root
    - group: dehydrated
    - mode: '0640'
    - template: jinja
    - require:
      - dehydrated_config_config_d
    - names:
      - /etc/dehydrated/config.d/99-salt.sh:
        - source: salt://{{ slspath }}/files/etc/dehydrated/config.d/99-salt.sh.j2
#/ if config
{%-     endif %}


dehydrated_domains:
  file.managed:
    - user: root
    - group: dehydrated
    - mode: '0640'
    - template: jinja
    - require:
      - dehydrated_domains_d
    - names:
      - /etc/dehydrated/salt-domains.txt:
        - source: salt://{{ slspath }}/files/etc/dehydrated/domains.txt.j2

{%-     for certname, certdata in pillar.dehydrated.certs.items() %}

{%-       set cert_types = salt['dehydrated_helper.certtypes'](certdata) %}


{%-       if 'services' in certdata %}
{%-          do cert_services.append(certdata.services) %}
{%-       endif %}


{%- if "acls_for_combined_file" in certdata: %}
{%-   for acl_setting in certdata["acls_for_combined_file"]: %}
{%-       set acl_type_prefix = acl_setting["acl_type"][0] %}
{%-       set acl_perms = "r" %}
{%-       if "perms" in acl_setting: %}
{%-           set acl_perms = acl_setting["perms"] %}
{%-       endif %}
{%-       for acl_name in acl_setting["acl_names"]: %}
{%-         for cert_type in cert_types: %}
{%-           set cert_primary_domain = certdata.domains[0] %}
{%-           set full_path = "/etc/ssl/services/" ~ cert_primary_domain ~ ".with.chain.pem." ~ cert_type %}
{%-           do cert_acls.append('/usr/bin/setfacl -m "' ~ acl_type_prefix ~ ":" ~ acl_name ~ ":" ~ acl_perms ~ '" "' ~ full_path ~ '"') %}
{%-         endfor %}
{%-       endfor %}
{%-   endfor %}
{%- endif %}

{%-       if 'postrun_hooks' in certdata %}
{%-          do cert_postrunhooks.append(certdata.postrun_hooks) %}
{%-       endif %}

{%-       for certtype in cert_types %}
dehydrated_domains_d_{{ certname }}_{{ certtype }}:
  file.managed:
    - name: /etc/dehydrated/domains.d/{{ certname }}_{{ certtype }}
    - user: root
    - group: dehydrated
    - mode: '0640'
    {%- if certtype == "ecdsa" %}
    - contents: "KEY_ALGO=secp384r1"
    {%- else %}
    - contents: "KEY_ALGO={{ certtype }}"
    {%- endif %}
{%-       endfor %}
{%-     endfor %}

dehydrated_generic_hooks:
  file.managed:
    - user: root
    - group: dehydrated
    - mode: '0750'
    - names:
      - /etc/dehydrated/hooks.sh:
        - source: salt://{{ slspath }}/files/etc/dehydrated/hooks.sh

{%- if cert_services|length > 0 or cert_postrunhooks|length >0 or cert_acls|length >0 %}
dehydrated_postrunhooks_hooks:
  file.managed:
    - user: root
    - group: dehydrated
    - mode: '0750'
    - template: jinja
    - name: /etc/dehydrated/postrun-hooks.d/99-salt.sh
    - source: salt://{{ slspath }}/files/etc/dehydrated/postrun-hooks.d/99-salt.sh.j2
{%- endif %}

{%-     if deploy_hooks %}
{%-       if 'configs' in pillar and 'etc' in pillar.configs and 'dehydrated' in pillar.configs.etc %}
dehydrated_deploy_files:
  filetreedeployer.deploy:
    - config:
        pillar_prefix: 'configs'
        pillar_path:   'etc:dehydrated'
        dir_mode:      '0750'
        file_mode:     '0750'
        user:          root
        group:         dehydrated
#/ if configs in filetree pillar
{%-       endif %}
#/ if deploy hooks
{%-     endif %}

{%- if use_acmeresponder %}
enable_acmeresponder:
  cmd.run:
    - name: /usr/bin/systemctl enable --now acmeresponder.socket
    - require:
      - dehydrated_package
{%- endif %}

{%-     if run_immediately %}
{%-       if not('keepalived' in pillar) %}
dehydrated_timer_service:
  service.running:
    - name: dehydrated.timer
    - require:
      - dehydrated_package
    - enable: True
#/ if not(keepalived)
{%-       endif %}

dehydrated_postrunhooks_service:
  service.enabled:
    - name: dehydrated-postrun-hooks.service

# this is the hash for "https://acme-v02.api.letsencrypt.org/directory\n"
{%-       set ca_hashed_url = "aHR0cHM6Ly9hY21lLXYwMi5hcGkubGV0c2VuY3J5cHQub3JnL2RpcmVjdG9yeQo" %}
{%-       if 'ca' in pillar.dehydrated.config %}
# dehydrated has a '\n' at the end of the url so we need to do the same here.
{%-         set ca_hashed_url = salt.hashutil.base64_b64encode (pillar.dehydrated.config.ca ~ "\n")|regex_replace('=+$', '') %}
#/ if ca
{%-       endif %}

run_dehydrated_register:
  cmd.run:
    - name: /usr/bin/dehydrated --accept-terms --register
    # only run register if the registration file does not exist yet.
    - creates: /etc/dehydrated/accounts/{{ ca_hashed_url }}/registration_info.json

run_dehydrated:
  cmd.run:
    - name: /usr/bin/systemctl start dehydrated.service
    {%- if use_acmeresponder %}
    - require:
      - enable_acmeresponder
    {%- endif %}
    - onchanges:
      - file: /etc/dehydrated/salt-domains.txt
      - file: /etc/dehydrated/config
      - file: /etc/dehydrated/config.d/99-salt.sh
      {%- if deploy_hooks %}
      {%-   if 'configs' in pillar and 'etc' in pillar.configs and 'dehydrated' in pillar.configs.etc %}
      - dehydrated_deploy_files
      #/ if configs in filetree pillar
      {%-     endif %}
      #/ if deploy_hooks
      {%-   endif %}
#/ if run_immediately
{%-   endif %}
#/ if certs
{%-   endif %}
#/ if dehydrated
{%- endif %}
