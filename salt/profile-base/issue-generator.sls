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

{%- if grains.osrelease_info[0] > 12 %}
  issue_generator_package:
    pkg.installed:
      - names:
        - issue-generator

  {%- set interfaces = salt.filter_interfaces.interface_names_with_global_addresses() %}
  sysconfig_issuesgenerator:
     file.replace:
       - name: /etc/sysconfig/issue-generator
       - pattern: "NETWORK_INTERFACE_REGEX=.*"
       - repl: NETWORK_INTERFACE_REGEX="^({{ interfaces|sort|join('|') }})"
       - require:
         - issue_generator_package
{%- endif %}

