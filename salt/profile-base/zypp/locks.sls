{%- if "zypp" in pillar and "locks" in pillar.zypp %}
zypp_lock_pkgs:
  pkg.held:
    - replace: True
    - pkgs:
      {%- for pkg in pillar.zypp.locks %}
      - {{ pkg }}
      {%- endfor %}
{%- endif %}