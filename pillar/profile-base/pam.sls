pam:
  salt_managed: True
  unix:
    enable: True
    try_first_pass: True
    use_authtok: True
    nullok: True
    shadow: true
  wtmpdb:
    enable: True
    skip_if: sshd
{%- for module in ['env', 'limits', 'systemd', 'umask', ] %}
  {{ module }}:
    enable: True
{%- endfor %}
