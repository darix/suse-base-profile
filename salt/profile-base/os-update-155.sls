{%- if grains.osfullname == 'Leap' %}
os_release:
    file.managed:
    - user: root
    - group: root
    - mode: '0644'
    - names:
      - /etc/os-release:
        - source: salt://{{ slspath }}/files/etc/os-release-15.5
{%- endif %}