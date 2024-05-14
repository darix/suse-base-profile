{%- if "sysconfig" in pillar %}
{%- for file, file_data in pillar.sysconfig.items() %}
  {%- for key in file_data %}
{%- set setting = key|upper %}
{%- if 'value' in file_data[key] %}
  {%- set value = file_data[key]['value'] %}
{%- else %}
  {%- set value = file_data[key] %}
{%- endif %}
{%- if value is sequence and not value is string %}
  {%- set value = value|join(" ") %}
{%- endif %}

sysconfig_{{ file | regex_replace('/', '_') }}_{{ setting }}:
  file.replace:
    - name: /etc/sysconfig/{{ file }}
    - pattern: "^{{ setting }} *=.*"
    - repl: {{ setting }}="{{ value }}"
    - append_if_not_found: True
    {%- if 'require' in file_data[key] %}
    - require:
      {%- if file_data[key]['require'] is string %}
      - {{ file_data[key]['require'] }}
      {%- else %}
      {%- for requires in file_data[key]['require'] %}
      - {{ requires }}
      {%- endfor %}
      {%- endif %}
    {%- endif -%}
    {%- if 'cmd' in file_data[key] %}
  cmd.run:
    - name: {{ file_data[key]['cmd'] }}
    - onchanges:
      - file: /etc/sysconfig/{{ file }}
    {%- endif %}
  {%- endfor %}
{%- endfor %}
{%- endif %}