tmux:
  pkg.installed

tmux_root_conf:
  files.managed
    - name: /root/.tmux.conf
    - user: root
    - group: root
    - mode: 0600
    - contents:
      - "set-option -g history-limit 100000"
