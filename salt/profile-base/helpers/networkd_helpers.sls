{%- macro systemd_network_file(systemd_unit, sections) %}
{{ systemd_unit }}:
  file.managed:
    - name: {{ systemd_unit }}
    - makedirs: true
    - dir_mode: '0755'
    - mode: '0644'
    - user: root
    - group: root
    - require:
      - systemd_network_packages
    - require_in:
      - systemd_networkctl_reload
    - contents:
      {%- if 'managed_by_salt' in pillar %}
      - "# {{ pillar.managed_by_salt }}"
      {%- endif %}
      {%- if sections %}
      {%    for section_name, section_data in sections.items() %}
      - "[{{ section_name }}]"
      {%      for setting_data in section_data %}
      - {{ setting_data }}
      {%-     endfor %}
      {%-   endfor %}
      {%- endif %}
{%- endmacro %}

{%- macro networkd_config(devtype, base_index, network_files, netdev_files, link_files, systemd_dir='/etc/systemd/network') %}
{%-   if netdev_files %}
{%-     for name, sections in netdev_files.items() %}
{%-       set systemd_unit = systemd_dir ~ "/" ~ base_index+loop.index ~ '-' ~ devtype ~ '-' ~ name ~ '.netdev'  %}
{{ systemd_network_file(systemd_unit, sections) }}
{%-     endfor %}
{%-   endif %}
{%-   if network_files %}
{%-     for name, sections in network_files.items() %}
{%-       set systemd_unit = systemd_dir ~ "/" ~ base_index+loop.index ~ '-' ~ devtype ~ '-' ~ name ~ '.network'  %}
{{ systemd_network_file(systemd_unit, sections) }}
{%-     endfor %}
{%-   endif %}
{%-   if link_files %}
{%-     for name, sections in link_files.items() %}
{%-       set systemd_unit = systemd_dir ~ "/" ~ base_index+loop.index ~ '-' ~ devtype ~ '-' ~ name ~ '.link'  %}
{{ systemd_network_file(systemd_unit, sections) }}
{%-     endfor %}
{%-   endif %}
{%- endmacro %}
