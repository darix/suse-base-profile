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

{%- macro acls(certdata) %}
{%- if "acls_for_combined_file" in certdata: %}
{%-   for acl_setting in certdata["acls_for_combined_file"]: %}
{%-       set acl_type_prefix = acl_setting["acl_type"][0] %}
{%-       set acl_perms = "r" %}
{%-       if "perms" in acl_setting: %}
{%-           set acl_perms = acl_setting["perms"] %}
{%-       endif %}
{%-       for acl_name in acl_setting["acl_names"]: %}
{%-         for full_path in salt['dehydrated_helper.certpaths'](certdata) %}
{{ '/usr/bin/setfacl -m "' ~ acl_type_prefix ~ ":" ~ acl_name ~ ":" ~ acl_perms ~ '" "' ~ full_path ~ '"' }}
{%-         endfor %}
{%-       endfor %}
{%-   endfor %}
{%- endif %}
{%- endmacro %}

{%- macro postrun_hooks(certdata) %}
  {%- if 'postrun_hooks' in certdata %}
      {%- for lines in certdata.postrun_hooks %}
      {%-   if lines is string %}
{{ lines }}
      {%-   else %}
      {%-     for line in lines %}
{{ line }}
      {%-     endfor %}
      {%-   endif %}
      {%- endfor %}
  {%- endif %}
{%- endmacro %}

{%- macro services(certdata) %}
  {%- if 'services' in certdata %}
      {%- for services in certdata.services %}
      {%-   if services is string %}
/usr/bin/systemctl is-active {{ services }} && /usr/bin/systemctl try-reload-or-restart {{ services }}
      {%-   else %}
      {%-     for service in services %}
/usr/bin/systemctl is-active {{ service }} && /usr/bin/systemctl try-reload-or-restart {{ service }}
      {%-     endfor %}
      {%-   endif %}
      {%- endfor %}
  {%- endif %}
{%- endmacro %}