{%- if 'etckeeper' in pillar and 'enabled' in pillar.etckeeper and pillar.etckeeper.enabled %}
etckeeper_packages:
     pkg.installed:
       - pkgs:
         - etckeeper
         - etckeeper-zypp-plugin
         - git-core

etckeeper_init:
  cmd.run:
    - name: /usr/sbin/etckeeper init
    - creates: /etc/.git/

{%- if 'bootstrap' in pillar.etckeeper and pillar.etckeeper.bootstrap %}
etckeeper_initial_commit:
  cmd.run:
    - name: /usr/sbin/etckeeper commit "automatic initial commit" || true
    - onlyif: /usr/sbin/etckeeper unclean
{%- endif %}
{%- endif %}
