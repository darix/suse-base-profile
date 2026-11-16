pam:
  salt_managed: True
  unix:
    enable: True
    try_first_pass: True
    use_authtok: True
    nullok: True
    shadow: true
{%- for module in ['env', 'limits', 'systemd', 'umask', ] %}
  {{ module }}:
    enable: True
{%- endfor %}
