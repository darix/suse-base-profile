{%- from 'profile-base/helpers/ssh_config_helper.sls' import ssh_handle_boolean  %}

postfix_package:
  pkg.installed:
    - names:
      - postfix

{%- set changed_settings = [] %}
{%- if 'mail' in pillar %}

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
{%- do changed_settings.append("postfix_sysconfig_relayhost") %}
postfix_sysconfig_relayhost:
  file.replace:
    - name: /etc/sysconfig/postfix
    - pattern: POSTFIX_RELAYHOST=".*"
    - repl: POSTFIX_RELAYHOST="[{{ pillar.mail.relay }}]"
{%- endif %}

{%- do changed_settings.append("postfix_sysconfig_myhostname") %}
postfix_sysconfig_myhostname:
  file.replace:
    - name: /etc/sysconfig/postfix
    - pattern: POSTFIX_MYHOSTNAME=".*"
    - repl: POSTFIX_MYHOSTNAME="{{ myhostname }}"
    - append_if_not_found: True

{%- if 'masquerade_domain' in pillar.mail %}
{%- do changed_settings.append("postfix_sysconfig_masquerade_domain") %}
postfix_sysconfig_masquerade_domain:
  file.replace:
    - name: /etc/sysconfig/postfix
    - pattern: POSTFIX_MASQUERADE_DOMAIN=".*"
    - repl: POSTFIX_MASQUERADE_DOMAIN="{{ pillar.mail.masquerade_domain }}"
{%- endif %}

{%- do changed_settings.append("postfix_sysconfig_masquerade_exceptions") %}
postfix_sysconfig_masquerade_exceptions:
  file.replace:
    - name: /etc/sysconfig/postfix
    - pattern: POSTFIX_ADD_MASQUERADE_EXCEPTIONS=".*"
    - repl: POSTFIX_ADD_MASQUERADE_EXCEPTIONS=""
    - append_if_not_found: True

{%- do changed_settings.append("postfix_sysconfig_mynetworks") %}
postfix_sysconfig_mynetworks:
  file.replace:
    - name: /etc/sysconfig/postfix
    - pattern: POSTFIX_ADD_MYNETWORKS_STYLE=".*"
    - repl: POSTFIX_ADD_MYNETWORKS_STYLE="{{ mynetworks_style }}"
    - append_if_not_found: True

{%- do changed_settings.append("postfix_sysconfig_mail_from_header") %}
postfix_sysconfig_mail_from_header:
  file.replace:
    - name: /etc/sysconfig/mail
    - pattern: FROM_HEADER=".*"
    - repl: FROM_HEADER="{{ from_header }}"

{%- do changed_settings.append("postfix_sysconfig_mail_listen_remote") %}
postfix_sysconfig_mail_listen_remote:
  file.replace:
    - name: /etc/sysconfig/mail
    - pattern: SMTPD_LISTEN_REMOTE=".*"
    - repl: SMTPD_LISTEN_REMOTE="{{ listen_remote }}"

{%- if 'aliases' in pillar.mail %}
{%- for alias, target in pillar.mail.aliases.items() %}
mail_aliases_{{ alias }}:
  file.replace:
    - name: /etc/aliases
    - pattern: "^{{ alias }}:.*"
    - repl: "{{ alias }}: {{ target }}"
    - append_if_not_found: True
{%- endfor %}

run_newaliases:
  cmd.run:
    - name: /usr/bin/newaliases
    - onchanges:
      - file: /etc/aliases
{%- endif %}
{%- endif %}


postfix_service:
  service.running:
    - name: postfix
    - enable: True
    - reload: True
    - require:
      - postfix_package
      {%- if changed_settings|length > 0 %}
      {%- for changed_setting in changed_settings %}
      - {{ changed_setting }}
      {%- endfor %}
    - onchanges:
      {%- for changed_setting in changed_settings %}
      - {{ changed_setting }}
      {%- endfor %}
      {%- endif %}
  cmd.run:
    - name: /usr/sbin/config.postfix
    - require:
      - postfix_package
      {%- if changed_settings|length > 0 %}
      {%- for changed_setting in changed_settings %}
      - {{ changed_setting }}
      {%- endfor %}
    - onchanges:
      {%- for changed_setting in changed_settings %}
      - {{ changed_setting }}
      {%- endfor %}
      {%- endif %}