{%- if grains.osrelease_info[0] > 12 %}
  issue_generator_package:
    pkg.installed:
      - names:
        - issue-generator

  {%- set interfaces = salt.filter_interfaces.interface_names_with_global_addresses() %}
  sysconfig_issuesgenerator:
     file.replace:
       - name: /etc/sysconfig/issue-generator
       - pattern: "NETWORK_INTERFACE_REGEX=.*"
       - repl: NETWORK_INTERFACE_REGEX="^({{ interfaces|sort|join('|') }})"
       - require:
         - issue_generator_package
{%- endif %}

