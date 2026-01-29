#
# suse-base-profile
#
# Copyright (C) 2025   darix
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

{%- set is_container = grains.virtual in ["LXC", "container", "systemd-nspawn"] %}
include:
  - .zypp
  - .timezone
  - .locale
  - .hosts-file
{%- if not(is_container) %}
  - .kexec-reboot
  - .systemd-networkd-ng
  - .wicked-network
  - .resolvconf
  - .grub
  - .auditd
  - .sysctl
  - .chrony
  - .udev-rules
  - .mounts
  - .systemd-coredump
  - .systemd-socket-redirector
  - .systemd-settings
{%- endif %}
  - .systemd-overrides
  - .sysconfig
  - .screen
  - .tmux
  - .mailrelay
{%- if not(is_container) %}
  - .rsyslog
  - .issue-generator
  - .monitoring
  - .cron
  - .logrotate
  - .rsync
  - .ssh
  - .ssh-root-authorized-keys
  - .ethtool
  - .ipsets
  - .dehydrated
  - .apparmor-local-overrides
  - .nsswitch
  - .sssd
{%- endif %}
  - .etckeeper
  - .salt-config
  - .resticprofile
{%- if not(is_container) %}
  - .apache
  - .flatpak
  - .nfs-exports
{%- endif %}
