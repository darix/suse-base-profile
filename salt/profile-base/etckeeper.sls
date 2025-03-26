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
