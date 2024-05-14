dracut_nowaitforswap:
  file.replace:
    - name: /etc/dracut.conf
    - pattern: "^nowaitforswap=.*"
    - repl: "nowaitforswap=yes"
    - append_if_not_found: True

{%- if 'grub' in pillar %}
{%- for setting, value in pillar.grub.items() %}

grub_{{ setting }}:
  file.replace:
    - name: /etc/default/grub
    - pattern: GRUB_{{ setting | upper }}=.*
    - repl: GRUB_{{ setting | upper }}="{{ value }}"
    - append_if_not_found: True

{%- endfor %}
{%- endif %}

grub_rebuild_config:
  cmd.run:
    - name: /usr/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg
    - onchanges:
      - file: /etc/dracut.conf
      - file: /etc/default/grub