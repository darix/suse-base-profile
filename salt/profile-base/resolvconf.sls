{%- if "network" in pillar and "resolver" in pillar.network %}
resolv_conf:
  file.managed:
    - user: root
    - group: root
    - mode: '0644'
    - template: jinja
    - follow_symlinks: false
    - context:
      default_options:
        - "rotate"
        - "attempts=3"
    - names:
      - /etc/resolv.conf:
        - source: salt://{{ slspath }}/files/etc/resolv.conf.j2
  cmd.run:
    - name: /usr/sbin/config.postfix
    - onlyif: test -f /usr/sbin/config.postfix
    - onchanges:
      - file: /etc/resolv.conf
    - require:
      - file: /etc/resolv.conf
{%- endif %}