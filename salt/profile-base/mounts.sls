# generic mount point handler

{%- if 'mounts' in pillar and pillar.mounts %}
{%- for mount_name, mount_data in pillar.mounts.items() %}
{%- set cleanedup_mount_name = mount_name.replace('/','_').replace('.', '_').replace(' ', '_') %}
mountpoint_{{ cleanedup_mount_name }}:
  mount.mounted:
    - name: {{ mount_name }}
    - mkmnt: True
    - persistent: True
    {%- for name, value in mount_data.items() %}
    - {{ name }}: {{ value }}
    {%- endfor %}
{%- endfor %}
{%- endif %}

{%- set deprecated_fstab_entries = { "devpts": "/dev/pts","proc": "/proc","sysfs": "/sys","debugfs": "/sys/kernel/debug","usbfs": "/proc/bus/usb","tmpfs": "/run" } %}
{%- for target_device, mount_point in deprecated_fstab_entries.items() %}
{%- set cleanedup_mount_name = mount_point.replace('/','_').replace('.', '_') %}
cleanup_fstab{{ cleanedup_mount_name }}:
  mount.fstab_absent:
   - name: {{ target_device }}
   - fs_file: {{ mount_point }}
{%- endfor %}
