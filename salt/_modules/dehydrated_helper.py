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

def certtypes(certdata):
  if 'cert_types' in certdata:
    return certdata['cert_types']
  if 'cert_types' in __pillar__['dehydrated']:
    return __pillar__['dehydrated']['cert_types']
  return ['rsa', 'ecdsa']

def certpaths(certdata):
  return_data = []
  cert_primary_domain = certdata['domains'][0]
  for cert_type in certtypes(certdata):
    return_data.append(f"/etc/ssl/services/{cert_primary_domain}.with.chain.pem.{cert_type}")
  return return_data
