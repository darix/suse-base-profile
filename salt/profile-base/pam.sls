#!py
from salt.modules.cmdmod import run_stdout as cmdrun
import logging

log = logging.getLogger("pampampam")

# pam-config --query --mkhomedir
# session: umask=077 skel=/etc/skel


def pam_module_add_condition_cmdline(module_name):
    return f"pam-config --query --{module_name} | grep -q :"


def pam_module_delete_condition_cmdline(module_name):
    return f"test $(pam-config --delete --{module_name}  | wc -l) -eq 0"


def run():
    config = {}

    pam_modules = {
        "access": {
            "options": [
                "debug",
                "nodefgroup",
                "noaudit",
                "accessfile",
                "fieldsep",
                "listsep",
            ]
        },
        "apparmor": {"options": ["debug"]},
        "ccreds": {},
        "cracklib": {
            "options": [
                "debug",
                "reject_username",
                "gecoscheck",
                "enforce_for_root",
                "authtok_type",
                "retry",
                "difok",
                "difignore",
                "minlen",
                "dcredit",
                "ucredit",
                "lcredit",
                "ocredit",
                "minclass",
                "dictpath",
                "maxrepeat",
                "maxsequence",
                "maxclassrepeat",
            ]
        },
        "deny": {},
        "ecryptfs": {"options": ["unwrap"]},
        "env": {"options": ["debug", "conffile", "envfile", "readenv"]},
        "exec": {
            "options": ["debug", "expose_authtok", "seteuid", "quiet", "log", "option"]
        },
        "faildelay": {"options": ["debug", "delay"]},
        "fp": {"options": ["debug"]},
        "fprint": {"options": ["debug"]},
        "fprintd": {"options": ["debug"]},
        "fscrypt": {},
        "gnome_keyring": {"options": ["auto_start", "only_if"]},
        "group": {},
        "himmelblau": {"options": ["debug"]},
        "kanidm": {"options": ["debug"]},
        "krb5": {"options": ["debug", "ignore_unknown_principals", "minimum_uid"]},
        "kwallet5": {},
        "lastlog2": {"options": ["debug", "silent", "database", "silent_if"]},
        "ldap": {"options": ["debug"]},
        "limits": {"options": ["debug", "change_uid", "utmp_early", "conf"]},
        "localuser": {"options": ["debug", "file"]},
        "make": {},
        "mkhomedir": {"options": ["debug", "silent", "umask", "skel"]},
        "mktemp": {"options": ["debug"]},
        "nam": {},
        "passwdqc": {
            "options": [
                "ask_oldauthtok",
                "check_oldauthtok",
                "use_first_pass",
                "use_authtok",
                "min",
                "max",
                "passphrase",
                "match",
                "similar",
                "random",
                "enforce",
                "retry",
            ]
        },
        "pkcs11": {"options": ["debug", "configfile"]},
        "pwcheck": {
            "options": [
                "debug",
                "nullok",
                "cracklib",
                "no_obscure_checks",
                "enforce_for_root",
                "cracklib_path",
                "maxlen",
                "minlen",
                "tries",
                "remember",
            ]
        },
        "pwhistory": {
            "options": [
                "debug",
                "use_authtok",
                "enforce_for_root",
                "remember",
                "retry",
                "authtok_type",
                "file",
            ]
        },
        "pwquality": {
            "options": [
                "debug",
                "reject_username",
                "gecoscheck",
                "enforce_for_root",
                "local_users_only",
                "use_authtok",
                "authtok_type",
                "retry",
                "difok",
                "minlen",
                "dcredit",
                "ucredit",
                "lcredit",
                "ocredit",
                "minclass",
                "dictpath",
                "maxrepeat",
                "maxsequence",
                "maxclassrepeat",
                "dictcheck",
                "usercheck",
                "enforcing",
                "badwords",
            ]
        },
        "selinux": {"options": ["debug"]},
        "ssh": {"options": ["debug", "nullok", "keyfiles"]},
        "sss": {
            "options": [
                "quiet",
                "forward_pass",
                "use_first_pass",
                "use_authtok",
                "ignore_unknown_user",
                "ignore_authinfo_unavail",
                "allow_missing_name",
                "prompt_always",
                "try_cert_auth",
                "require_cert_auth",
                "allow_chauthtok_by_root",
                "retry",
                "domains",
            ]
        },
        "succeed_if": {},
        "systemd": {
            "options": [
                "debug",
                "kill_session_processes",
                "kill_only_users",
                "kill_exclude_users",
                "controllers",
                "reset_controllers",
            ]
        },
        "systemd_home": {"options": ["debug", "suspend"]},
        "thinkfinger": {"options": ["debug"]},
        "umask": {"options": ["debug", "silent", "usergroups", "umask"]},
        "unix": {
            "options": [
                "debug",
                "audit",
                "nodelay",
                "nullok",
                "shadow",
                "md5",
                "bigcrypt",
                "sha256",
                "sha512",
                "blowfish",
                "nis",
                "broken_shadow",
                "use_first_pass",
                "try_first_pass",
                "authtok_type",
                "remember",
                "rounds",
                "minlen",
            ]
        },
        "unix2": {
            "options": ["nullok", "debug", "trace", "none", "call_modules", "nisdir"]
        },
        "unix_ng": {
            "options": [
                "nullok",
                "debug",
                "quiet",
                "use_first_pass",
                "try_first_pass",
                "authtok_type",
            ]
        },
        "winbind": {"options": ["debug"]},
        "wtmpdb": {"options": ["debug", "silent", "database", "skip_if"]},
        "ck_connector": {"options": ["debug"]},
        "cryptpass": {},
        "csync": {
            "options": [
                "use_first_pass",
                "try_first_pass",
                "soft_try_pass",
                "nullok",
                "debug",
                "silent",
            ]
        },
        "google_authenticator": {"options": ["noskewadj", "nullok", "secret"]},
        "keyinit": {"options": ["debug", "force", "revoke"]},
        "lastlog": {
            "options": [
                "debug",
                "silent",
                "never",
                "nodate",
                "nohost",
                "noterm",
                "nowtmp",
                "noupdate",
                "showfailed",
            ]
        },
        "loginuid": {"options": ["require_auditd"]},
        "mount": {},
        "u2f": {
            "options": [
                "debug",
                "nouserok",
                "openasuser",
                "alwaysok",
                "interactive",
                "manual",
                "cue",
                "nodetect",
                "sshformat",
                "debug_file",
                "origin",
                "appid",
                "authfile",
                "authpending_file",
                "max_devices",
                "prompt",
                "cue_prompt",
                "userpresence",
                "userverification",
                "pinverification",
            ]
        },
    }

    for module_name, module_data in pam_modules.items():
        log.error(f"Handling pam module {module_name} with module data {module_data}")

        # TODO: currently we are not handling if module settings change
        if __salt__["pillar.get"](f"pam:{module_name}:enable", False):
            pam_module_condition_cmdline = pam_module_add_condition_cmdline(module_name)
            pam_module_cmdline = ["pam-config", "--add", f"--{module_name}"]

            for option in module_data.get("options", []):
                module_setting = __salt__["pillar.get"](
                    f"pam:{module_name}:{option}", None
                )
                log.error(
                    f"Handling option {option} with module setting {module_setting}"
                )

                if not (module_setting is None):
                    if isinstance(option, bool):
                        pam_module_cmdline.append(f"--{module_name}-{option}")
                    else:
                        pam_module_cmdline.append(
                            f"--{module_name}-{option}={module_setting}"
                        )
        else:
            pam_module_cmdline = ["pam-config", "--delete", f"--{module_name}"]
            pam_module_condition_cmdline = pam_module_delete_condition_cmdline(
                module_name
            )

        config[f"pam_module_{module_name}"] = {
            "cmd.run": [
                {"name": " ".join(pam_module_cmdline)},
                {"unless": pam_module_condition_cmdline},
            ]
        }

    return config
