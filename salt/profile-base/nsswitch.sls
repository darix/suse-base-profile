{%- set passwd_modules   = ["compat"] %}
{%- set group_modules    = ["compat"] %}
{%- set shadow_modules   = ["compat"] %}
{%- set netgroup_modules = ["files"] %}
{%- set autofs_modules   = ["files"] %}

# TODO: handle ALP and friends
{%- if grains.osfullname == "openSUSE Tumbleweed" %}
{%- do passwd_modules.append("systemd") %}
{%- do group_modules.append("[SUCCESS=merge] systemd") %}
{%- endif %}

{%- if 'sssd' in pillar and 'map_users' in pillar.sssd and pillar.sssd.map_users %}
{%- do passwd_modules.append("sss") %}
{%- do group_modules.append("sss") %}
{%- endif %}

{%- if 'sssd' in pillar and 'netgroup' in pillar.sssd and pillar.sssd.netgroup %}
{%- do netgroup_modules.append("sss") %}
{%- else %}
{%- do netgroup_modules.append("nis") %}
{%- endif %}

{%- if 'sssd' in pillar and 'autofs' in pillar.sssd and pillar.sssd.autofs %}
{%- do autofs_modules.append("sss") %}
{%- else %}
{%- do autofs_modules.append("nis") %}
{%- endif %}

nsswitch_passwd:
  file.replace:
    - name: /etc/nsswitch.conf
    - pattern: '^(passwd:\s+).*?$'
    - repl: '\1{{ passwd_modules| join(" ") }}'

nsswitch_group:
  file.replace:
    - name: /etc/nsswitch.conf
    - pattern: '^(group:\s+).*?$'
    - repl: '\1{{ group_modules| join(" ") }}'

nsswitch_shadow:
  file.replace:
    - name: /etc/nsswitch.conf
    - pattern: '^(shadow:\s+)\.*?$'
    - repl: '\1{{ shadow_modules| join(" ") }}'

nsswitch_netgroup:
  file.replace:
    - name: /etc/nsswitch.conf
    - pattern: '^(netgroup:\s+).*?$'
    - repl: '\1{{ netgroup_modules| join(" ") }}'

nsswitch_automount:
  file.replace:
    - name: /etc/nsswitch.conf
    - pattern: '^(automount:\s+).*?$'
    - repl: '\1{{ autofs_modules| join(" ") }}'