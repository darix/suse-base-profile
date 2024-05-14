#!py

# usage example
# salt 'yourhosthere*' state.apply profile-base.dehydrated-cleanup-postrun-hooks

import os
import logging


def run():
    log = logging.getLogger(__name__)
    config = {}
    path = "/etc/dehydrated/postrun-hooks.d"
    salt_script_filename = "99-salt.sh"
    salt_script = os.path.join(path, salt_script_filename)
    has_salt_script = os.path.exists(salt_script)
    if has_salt_script:
        with os.scandir(path) as it:
            for entry in it:
                if (
                    entry.name.endswith(".sh")
                    and entry.is_file()
                    and not entry.name == salt_script_filename
                ):
                    section = f"cleanup_old_postrun_hook_{entry.name}"
                    config[section] = {
                        "file.absent": [
                            {"name": entry.path},
                        ]
                    }
    else:
        raise FileNotFoundError(
            f"Can not cleanup here as {salt_script} is missing. Maybe apply profile-base.dehydrated first?"
        )
    return config
