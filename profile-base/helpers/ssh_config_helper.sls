#
{%- macro ssh_handle_boolean(value) %}
  {%- if  (value is sameas true) %}
    {{- 'yes' }}
  {%- else %}
    {%- if value %}
      {{- value }}
    {%- else %}
      {{- 'no' }}
    {%- endif %}
  {%- endif %}
{%- endmacro %}

{%- macro ssh_output_value(option_name, option_value, indent='') %}
    {%- if option_value is sequence and not option_value is string %}
      {%- for sub_value in option_value %}
{{ indent }}{{ option_name }} {{ ssh_handle_boolean(sub_value) }}
      {%- endfor %}
    {%- else %}
{{-  indent }}{{ option_name }} {{ ssh_handle_boolean(option_value) }}
    {%- endif %}
{%- endmacro %}

{%- macro ssh_config_option(option_name, default_value=None) %}
  {%- if 'ssh' in pillar %}
    {%- set option_value = pillar.ssh.get(option_name, default_value) %}
  {%- endif %}
  {%- if option_value != None %}
{{ ssh_output_value(option_name, option_value) }}
  {%- endif %}
{%- endmacro %}

{%- macro ssh_config_match_options() %}
  {%- if 'ssh' in pillar and 'Match' in pillar.ssh %}
    {%- for matcher, match_data in pillar.ssh['Match'].items() %}
Match {{ matcher }}
      {%- for option_name, option_value in match_data.items() %}
    {{ ssh_output_value(option_name, option_value, indent='    ') }}
      {%- endfor %}
    {%- endfor %}
  {%- endif %}
{%- endmacro %}