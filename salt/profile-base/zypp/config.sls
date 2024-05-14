{%- if 'config' in pillar.zypp %}
  {%- for file_name, file_data in pillar.zypp.config.items() %}

    {%- for setting, value in file_data.items() %}
# TODO: if someone added a true line already, this line will add another
{{ file_name | regex_replace('\.', '_') }}_{{ setting | regex_replace('\.', '_') }}:
  file.replace:
    - name: /etc/zypp/{{ file_name }}
    - pattern: "^(# +)?{{ setting }} =.*"
    - repl: "{{ setting }} = {{ value }}"

    {%- endfor %}
  {%- endfor %}
{%- endif %}
