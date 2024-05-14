{%- macro jump_hosts_entries(minion_id, jump_host) %}
{%- set minion_jump_address = salt['mine.get'](minion_id, 'internal_ssh_address').get(minion_id, minion_id) %}
{%- set minion_jump_port = 22 %}
{%- if minion_jump_address == '' %}
{%-    set minion_jump_host = minion_id %}
{%- else %}
{%-   if ':' in minion_jump_address %}
{%-      set minion_jump_host, minion_jump_port = minion_jump_address.split(':', 2) %}
{%-   else %}
{%-      set minion_jump_host = minion_jump_address %}
{%-   endif %}
{%- endif %}
Host {{ minion_id.split('.')[0] }}
  Hostname {{ minion_jump_host }}
  Port {{ minion_jump_port }}
{%- if jump_host != minion_id %}
  ProxyJump root@{{ jump_host }}
{%- endif %}
  ForwardAgent yes
  User root

Host {{ minion_id }}
  Hostname {{ minion_jump_host }}
  Port {{ minion_jump_port }}
{%- if jump_host != minion_id %}
  ProxyJump root@{{ jump_host }}
{%- endif %}
  ForwardAgent yes
  User root

{%- endmacro %}
