include:
  - .zypp.config
  {%- if grains.oscodename == 'openSUSE Tumbleweed' %}
  - .zypp.tumbleweed
  {%- endif %}
  {%- if grains.osfullname == "SLES" %}
  - .zypp.sles
  {%- endif %}
  {%- if grains.osfullname == "Leap" %}
  - .zypp.leap
  {%- endif %}
  - .zypp.openh264
  - .zypp.isv-repositories
  - .zypp.check_zypper
  - .zypp.locks
