#!py

import logging
from salt.exceptions import SaltRenderError

log = logging.getLogger(__name__)

def mountoptions(options_list=[]):
    default_options = {
        "async":"sync",
        "insecure":"secure",
        "no_acl": "acl",
        "no_subtree_check":"subtree_check",
        "ro":"rw",
        "root_squash":"no_root_squash",
    }

    for default_value, alternative_value in default_options.items():
        if not(default_value in options_list or alternative_value in options_list):
            options_list.append(default_value)
    return(options_list)

def run():
    config = {}
    if "nfs_server" in __pillar__:
        config["nfs_server_packages"] = {
            "pkg.installed": [
                {"names": [ "nfs-kernel-server" ]},
            ]
        }
        nfs_server_requires = ["nfs_server_packages"]

        i=0
        exports_list = []
        if "exports" in __pillar__["nfs_server"]:
            for export_path, export_data in __pillar__["nfs_server"]["exports"].items():
                i+=1
                clients_data = []

                for host, export_options in export_data.items():
                    clients_data.append( { "hosts": host, "options": mountoptions(export_options), } )

                export_state_name = f"nfs_export_{i}"
                exports_list.append(export_state_name)

                config[export_state_name] = {
                    "nfs_export.present": [
                        { "name": export_path },
                        { "clients": clients_data },
                        { "require": nfs_server_requires },
                    ]
                }

        idmap_domain = __pillar__["nfs_server"].get("idmap_domain", "localdomain")

        if __grains__["oscodename"] == 'openSUSE Tumbleweed':
            idmapd_conf = "/etc/idmapd.conf.d/salt.conf"
            config["fix_idmap_domain"] = {
                "file.managed": [
                    { "name":    "/etc/idmapd.conf.d/salt.conf" },
                    { "user":    "root" },
                    { "group":   "root" },
                    { "mode":    "0644" },
                    { "contents": f"Domain = {idmap_domain}"}
                ]
            }
        else:
            config["fix_idmap_domain"] = {
                "file.replace": [
                    { "name":    "/etc/idmapd.conf" },
                    { "pattern": "^Domain\s*=\s*.*$" },
                    { "repl":    f"Domain = {idmap_domain}" },
                    { "require": nfs_server_requires },
                    { "append_if_not_found", True }
                ]
            }

        if len(exports_list) > 0:
            exports_list.append("fix_idmap_domain")
            config["nfs_server_service"] = {
                "service.running": [
                    { "name": "nfs-server.service"},
                    { "enable": True },
                    { "reload": True },
                    { "require": exports_list },
                ]
            }




    return config