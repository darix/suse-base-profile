import logging

import requests

from salt.exceptions import SaltRenderError

log = logging.getLogger(__name__)


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
