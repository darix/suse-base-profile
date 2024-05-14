nsswitch_passwd:
  file.replace:
    - name: /etc/nsswitch.conf
    - pattern: '^passwd:.*'
{%- if 'sssd' in pillar and 'map_users' in pillar.sssd and pillar.sssd.map_users %}
    - repl: 'passwd:		compat sss'
{%- else %}
    - repl: 'passwd:		compat'
{%- endif %}

nsswitch_group:
  file.replace:
    - name: /etc/nsswitch.conf
    - pattern: '^group:.*'
{%- if 'sssd' in pillar and 'map_users' in pillar.sssd and pillar.sssd.map_users %}
    - repl: 'group:		compat sss'
{%- else %}
    - repl: 'group:		compat'
{%- endif %}

nsswitch_shadow:
  file.replace:
    - name: /etc/nsswitch.conf
    - pattern: '^shadow:.*'
{%- if 'sssd' in pillar and 'map_users' in pillar.sssd and pillar.sssd.map_users %}
    - repl: 'shadow:		compat sss'
{%- else %}
    - repl: 'shadow:		compat'
{%- endif %}

nsswitch_netgroup:
  file.replace:
    - name: /etc/nsswitch.conf
    - pattern: '^netgroup:.*'
{%- if 'sssd' in pillar and 'netgroup' in pillar.sssd and pillar.sssd.netgroup %}
    - repl: 'netgroup:	files sss'
{%- else %}
    - repl: 'netgroup:	files nis'
{%- endif %}

nsswitch_automount:
  file.replace:
    - name: /etc/nsswitch.conf
    - pattern: '^automount:.*'
{%- if 'sssd' in pillar and 'autofs' in pillar.sssd and pillar.sssd.autofs %}
    - repl: 'automount:	files sss'
{%- else %}
    - repl: 'automount:	files nis'
{%- endif %}

