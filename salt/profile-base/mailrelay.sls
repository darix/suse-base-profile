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

{%- from 'profile-base/helpers/ssh_config_helper.sls' import ssh_handle_boolean  %}

{%- if 'mail' in pillar and 'relay' in pillar.mail %}

postfix_package:
  pkg.installed:
    - names:
      - postfix

{%- if "myhostname" in pillar.mail %}
{%- set myhostname = pillar.mail.myhostname %}
{%- else %}
{%- set myhostname = grains.fqdn %}
{%- endif %}

{%- if "mynetworks_style" in pillar.mail %}
{%- set mynetworks_style = pillar.mail.mynetworks_style %}
{%- else %}
{%- set mynetworks_style = "host" %}
{%- endif %}

{%- if "from_header" in pillar.mail %}
{%- set from_header = pillar.mail.from_header %}
{%- else %}
{%- set from_header = grains.fqdn %}
{%- endif %}

{%- if "listen_remote" in pillar.mail %}
{%- set listen_remote = ssh_handle_boolean(pillar.mail.listen_remote) %}
{%- else %}
{%- set listen_remote = "no" %}
{%- endif %}

{%- if 'relay' in pillar.mail %}
postfix_sysconfig_relayhost:
  file.replace:
    - name: /etc/sysconfig/postfix
    - require:
      - postfix_package
    - require_in:
      - postfix_service
    - onchanges_in:
      - postfix_service
    - pattern: POSTFIX_RELAYHOST=".*"
    - repl: POSTFIX_RELAYHOST="[{{ pillar.mail.relay }}]"
{%- endif %}

postfix_sysconfig_myhostname:
  file.replace:
    - name: /etc/sysconfig/postfix
    - require:
      - postfix_package
    - require_in:
      - postfix_service
    - onchanges_in:
      - postfix_service
    - pattern: POSTFIX_MYHOSTNAME=".*"
    - repl: POSTFIX_MYHOSTNAME="{{ myhostname }}"
    - append_if_not_found: True

{%- if 'masquerade_domain' in pillar.mail %}
postfix_sysconfig_masquerade_domain:
  file.replace:
    - name: /etc/sysconfig/postfix
    - require:
      - postfix_package
    - require_in:
      - postfix_service
    - onchanges_in:
      - postfix_service
    - pattern: POSTFIX_MASQUERADE_DOMAIN=".*"
    - repl: POSTFIX_MASQUERADE_DOMAIN="{{ pillar.mail.masquerade_domain }}"
{%- endif %}

postfix_sysconfig_masquerade_exceptions:
  file.replace:
    - name: /etc/sysconfig/postfix
    - require:
      - postfix_package
    - require_in:
      - postfix_service
    - onchanges_in:
      - postfix_service
    - pattern: POSTFIX_ADD_MASQUERADE_EXCEPTIONS=".*"
    - repl: POSTFIX_ADD_MASQUERADE_EXCEPTIONS=""
    - append_if_not_found: True

postfix_sysconfig_mynetworks:
  file.replace:
    - name: /etc/sysconfig/postfix
    - require:
      - postfix_package
    - require_in:
      - postfix_service
    - onchanges_in:
      - postfix_service
    - pattern: POSTFIX_ADD_MYNETWORKS_STYLE=".*"
    - repl: POSTFIX_ADD_MYNETWORKS_STYLE="{{ mynetworks_style }}"
    - append_if_not_found: True

{%- if "smtp_bind_address" in pillar.mail %}
postfix_sysconfig_bind_adress:
  file.replace:
    - name: /etc/sysconfig/postfix
    - require:
      - postfix_package
    - require_in:
      - postfix_service
    - onchanges_in:
      - postfix_service
    - pattern: POSTFIX_ADD_SMTP_BIND_ADDRESS=".*"
    - repl: POSTFIX_ADD_SMTP_BIND_ADDRESS="{{ pillar.mail.smtp_bind_address }}"
    - append_if_not_found: True
{%- endif %}

postfix_sysconfig_mail_from_header:
  file.replace:
    - name: /etc/sysconfig/mail
    - require:
      - postfix_package
    - require_in:
      - postfix_service
    - onchanges_in:
      - postfix_service
    - pattern: FROM_HEADER=".*"
    - repl: FROM_HEADER="{{ from_header }}"

postfix_sysconfig_mail_listen_remote:
  file.replace:
    - name: /etc/sysconfig/mail
    - require:
      - postfix_package
    - require_in:
      - postfix_service
    - onchanges_in:
      - postfix_service
    - pattern: SMTPD_LISTEN_REMOTE=".*"
    - repl: SMTPD_LISTEN_REMOTE="{{ listen_remote }}"

{%- if 'aliases' in pillar.mail %}
{%- for alias, target in pillar.mail.aliases.items() %}
mail_aliases_{{ alias }}:
  file.replace:
    - name: /etc/aliases
    - require:
      - postfix_package
    - require_in:
      - postfix_service
    - onchanges_in:
      - postfix_service
    - pattern: "^{{ alias }}:.*"
    - repl: "{{ alias }}: {{ target }}"
    - append_if_not_found: True
{%- endfor %}

run_newaliases:
  cmd.run:
    - name: /usr/bin/newaliases
    - require:
      - postfix_package
    - require_in:
      - postfix_service
    - onchanges_in:
      - postfix_service
    - onchanges:
      - file: /etc/aliases
{%- endif %}

postfix_service:
  service.running:
    - name: postfix
    - enable: True
    - reload: True
    - require:
      - postfix_package
  cmd.run:
    - name: /usr/sbin/config.postfix
    - require:
      - postfix_package
{%- else %}
postfix_service:
  service.dead:
    - name: postfix
    - enable: False

postfix_package:
  pkg.purged:
    - pkgs:
      - postfix
    - require:
      - postfix_service
{%- endif %}