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
  - .ethtool
  - .ipsets
  - .dehydrated
  - .apparmor-local-overrides
  - .etckeeper
{%- if not(is_container) %}
  - .nsswitch
{%- endif %}
  - .sssd
  - .salt-config
  - .apache
  - .resticprofile
  - .flatpak
  - .nfs-exports
