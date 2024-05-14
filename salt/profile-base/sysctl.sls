
{%- if "sysctl" in pillar %}
{%- set items = [] %}
{%- for key, value in pillar.sysctl.items() %}
  {%- do items.append(key) %}
{{ key }}:
   sysctl.present:
     - value: {{ value }}
{%- endfor %}

run_sysctl:
  cmd.run:
    - name: /sbin/sysctl --system
    - onchanges:
      {%- for item in items %}
      - {{ item }}
      {%- endfor %}
{%- endif %}