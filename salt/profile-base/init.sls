{%- set is_container = grains.virtual in ["LXC", "container"] %}
include:
  - .zypp
  - .timezone
  - .locale
  - .wicked-network
  - .hosts-file
  - .resolvconf
{%- if not(is_container) %}
  - .grub
  - .auditd
  - .sysctl
  - .chrony
  - .udev-rules
  - .mounts
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
{%- if not(is_container) %}
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
  - .salt-config
  - .apache
  - .resticprofile
