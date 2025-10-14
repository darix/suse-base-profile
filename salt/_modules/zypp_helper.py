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

import logging

import requests

from salt.exceptions import SaltRenderError

log = logging.getLogger(__name__)

def repomd_key_url(baseurl):
    repomd_key_path = 'repodata/repomd.xml.key'
    repomd_url = f"{baseurl}/{repomd_key_path}"
    result = requests.head(repomd_url)
    log.info(f"Querying {repomd_url} resulted in {result.status_code}")
    if result.status_code in [200, 302, 301]:
        return repomd_url

def guess_repository(baseurl):
    repository_list = []

    osrelease_info = __salt__['grains.get']('osrelease_info')

    major_version = osrelease_info[0]
    if len(osrelease_info) > 1:
        minor_version = osrelease_info[1]
    else:
        minor_version = 0
    osfullname = __salt__['grains.get']('osfullname')
    if osfullname == "SLES":
        if len(osrelease_info) > 1:
            repository_list.append("SLE_{major_version}_SP{minor_version}".format(major_version=major_version, minor_version=minor_version))
        else:
            repository_list.append("SLE_{major_version}".format(major_version=major_version))
        repository_list.append("{major_version}.{minor_version}".format(major_version=major_version, minor_version=minor_version))
    elif osfullname == "Leap":
        repository_list.append("{major_version}.{minor_version}".format(major_version=major_version, minor_version=minor_version))
        repository_list.append("openSUSE_Leap_{major_version}.{minor_version}".format(major_version=major_version, minor_version=minor_version))
        if len(osrelease_info) > 1:
            repository_list.append("SLE_{major_version}_SP{minor_version}".format(major_version=major_version, minor_version=minor_version))
        else:
            repository_list.append("SLE_{major_version}".format(major_version=major_version))
    elif osfullname == 'openSUSE Tumbleweed':
        repository_list.append("openSUSE_Tumbleweed")
        repository_list.append("openSUSE_Factory")
    else:
        log.error("Do not know how to handle distro {distro}".format(distro=osfullname))

    repomd_path = 'repodata/repomd.xml'

    log.debug("osrelease_info: {osrelease_info} osfullname: {osfullname} repository list: {repository_list}".format(osfullname=osfullname, osrelease_info=osrelease_info, repository_list=repository_list))

    for repository in repository_list:
        repo_url = baseurl + repository + "/"
        full_url = repo_url + repomd_path
        log.debug("Testing {full_url}".format(full_url=full_url))
        result = requests.head(full_url)
        if result.status_code in [200, 302, 301]:
            return repo_url
        log.info("Querying {full_url} resulted in {status_code}".format(full_url=full_url, status_code=result.status_code))

    error_message = "No valid repository found for baseurl: {baseurl} repository list: {repository_list} osrelease_info: {osrelease_info} osfullname: {osfullname}".format(baseurl=baseurl, osfullname=osfullname, osrelease_info=osrelease_info, repository_list=repository_list)

    log.error(error_message)
    raise SaltRenderError(error_message)
