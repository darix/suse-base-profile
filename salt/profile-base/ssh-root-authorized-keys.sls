#!py

import os.path
from salt.exceptions import SaltRenderError

def run():
    config = {}

    if "sshkeys" in __pillar__:
        for username, userdata in __pillar__["sshkeys"].items():
            target_dir = userdata.get("target_dir", f"~{username}")

            if target_dir.startswith("~"):
                homedir = os.path.expanduser(target_dir)
                if homedir == target_dir:
                    raise SaltRenderError(f"Can not resolve the homedir for user {username} {target_dir}")
                if not(os.path.isdir(homedir)):
                    raise SaltRenderError(f"Invalid homedir? Not a directory? {target_dir}")

                target_dir = homedir

            target_owner = userdata.get("target_owner", username)
            target_group = userdata.get("target_group", None)

            config[f"ssh-{username}-authorized-keys-dir"] = {
                "file.directory": [
                    {"user": target_owner},
                    {"mode", userdata.get("dir_mode", '0751')},
                    {"name": f"{target_dir}/.ssh"},
                ]
            }

            if target_group:
                config[f"ssh-{username}-authorized-keys-dir"]["group"] = target_group

            config[f"ssh-{username}-authorized-keys-file"] = {
                "file.managed": [
                    { 'user': target_owner },
                    { 'mode': '0644' },
                    { 'template': 'jinja' },
                    { 'name': f"{target_dir}/.ssh/authorized_keys" },
                    { 'source': f"salt://profile-base/files/root/.ssh/authorized_keys.j2" },
                    { 'context': {
                            "sshkeys": userdata["sshkeys"]
                        }
                    },
                ]
            }

            if target_group:
                config[f"ssh-{username}-authorized-keys-file"]["group"] = target_group

    return config