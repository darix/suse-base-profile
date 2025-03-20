{%- if grains.osfullname in [ 'Leap', 'SLES' ] %}
os_release:
    file.managed:
    - user: root
    - group: root
    - mode: '0644'
    - names:
      - /etc/os-release:
        - source: salt://{{ slspath }}/files/etc/os-release-{{ grains.osfullname | lower }}-15.7
{%- endif %}
