{%- if (grains.osfullname in ["Leap", "SLES" ] and grains.osrelease_info[0] > 12) %}
  systemd_coredump_packages:
     pkg.installed:
      - names:
        - systemd-coredump
{%- endif %}
