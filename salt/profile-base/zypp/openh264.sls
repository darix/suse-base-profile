{%- if 'zypp' in pillar and 'products_enable_openh264' in pillar.zypp and pillar.zypp.products_enable_openh264 %}
  {%- set baseurl = "https://codecs.opensuse.org/openh264/" %}

  {%- set repoid = "repo-openh264" %}
  {%- set project_name = "Open H.264 Codec " %}
  {%- set subdir = None %}

  {%- if grains.osfullname in ["Leap", "SLES" ] %}
  {%- set subdir = "openSUSE_Leap" %}
  {%- set distro_field = "openSUSE Leap" %}
  {%- endif %}

  {%- if grains.osfullname == 'openSUSE Tumbleweed' %}
  {%- set subdir = "openSUSE_Tumbleweed" %}
  {%- set distro_field = grains.osfullname %}
  {%- endif %}

  {%- if subdir %}
    {%- set repo_url = baseurl ~ '/' ~ subdir '/' %}
{{ repo_id }}:
  pkgrepo.managed:
    - name:       {{ repo_id }}
    - humanname:  {{ project_name }}{{ distro_field }}
    - baseurl:    {{ repo_url }}
    - gpgcheck: 1
    - refresh: True

openh264_zypper_refresh:
  cmd.run:
    - name: /usr/bin/zypper --non-interactive --gpg-auto-import-keys ref {{ repo_id }}
    - onchanges:
      - {{ repo_id }}
  {%- endif %}
{%- endif %}