include:
  - .zypp
  - .timezone
  - .locale
  - .wicked-network
  - .hosts-file
  - .resolvconf
{%- if grains.virtual != "LXC" %}
  - .grub
  - .auditd
  - .sysctl
  - .chrony
  - .udev-rules
{%- endif %}
  - .systemd-coredump
  - .systemd-settings
  - .systemd-overrides
  - .systemd-socket-redirector
  - .sysconfig
  - .screen
  - .tmux
  - .mailrelay
  - .rsyslog
  - .issue-generator
{%- if grains.virtual != "LXC" %}
  - .monitoring
{%- endif %}
  - .rsync
  - .cron
  - .logrotate
  - .ssh
  - .ssh-root-authorized-keys
  - .internal-ca-certificates
  - .ethtool
  - .ipsets
  - .dehydrated
  - .apparmor-local-overrides
  - .etckeeper
  - .nsswitch
  - .sssd
  - .vim-data
  - .salt-config
  - .apache
