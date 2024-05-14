{%- set modules_with_separate_packages = ["apparmor", "asn", "auth_mellon", "auth_mellon-diagnostics", "auth_memcookie", "auth_signature", "form", "maxminddb", "perl", "php7", "wsgi", "xforward" ] %}
{%- set has_filetree = 'configs' in pillar and 'etc' in pillar.configs and 'apache2' in pillar.configs.etc %}
{%- if "sysconfig" in pillar and "apache2" in pillar.sysconfig %}
apache2_packages:
   pkg.installed:
     - require_in:
       {%- for key, data in pillar.sysconfig.apache2.items() %}
       {%- set setting = key|upper %}
       - sysconfig_apache2_{{ setting }}
       {%- endfor %}
       {%- if has_filetree %}
       - apache2_deploy_files
       {%- endif %}
     - names:
       - apache2
       - apache2-utils
       - monitoring-plugins-apachestatus_auto
       {%- if "apache_mpm" in pillar.sysconfig.apache2 and pillar.sysconfig.apache2.apache_mpm != "" %}
       - apache2-{{ pillar.sysconfig.apache2.apache_mpm }}
       {%- else %}
       - apache2-prefork
       {%- endif %}
       {%- if "apache_modules" in pillar.sysconfig.apache2 %}
       {%- for module in modules_with_separate_packages %}
       {%- if module in pillar.sysconfig.apache2.apache_modules %}
       - apache2-mod_{{ module }}
       {%- endif %}
       {%- endfor %}
       {%- endif %}

{%- if has_filetree %}
apache2_deploy_files:
  filetreedeployer.deploy:
    - config:
        pillar_prefix: 'configs'
        pillar_path:   'etc:apache2'
{%- endif %}

apache2_service:
  service.running:
    - name: apache2
    - enable: true
    - reload: true
    - require:
      - apache2_packages
      - file: /etc/sysconfig/apache2
      {%- if has_filetree %}
      - apache2_deploy_files
      {%- endif %}
    - onchanges:
      - file: /etc/sysconfig/apache2
      {%- if has_filetree %}
      - apache2_deploy_files
      {%- endif %}
{%- endif %}
