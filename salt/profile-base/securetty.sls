{%- for console in [ 'ttyS0', 'ttyS1', 'ttyS2', 'hvc0', 'console' ] %}
securetty_{{ console }}:
  file.replace:
    - name: /etc/securetty
    - pattern: {{ console }}
    - repl:    {{ console }}
    - append_if_not_found: True
{% endfor %}