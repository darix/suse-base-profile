#!py
from salt.modules.cmdmod import run_stdout as cmdrun
import logging
log = logging.getLogger("pampampam")

# pam-config --query --mkhomedir
# session: umask=077 skel=/etc/skel

def pam_module_add_condition_cmdline(module_name):
  return f'pam-config --query --{module_name} | grep -q :'

def pam_module_delete_condition_cmdline(module_name):
  return f'test $(pam-config --delete --{module_name}  | wc -l) -eq 0'

def run():
  config = {}

  pam_modules = {
    'mkhomedir': {
      'options': ['skel', 'umask'],
    }
  }

  for module_name, module_data in pam_modules.items():
    log.error(f"Handling pam module {module_name} with module data {module_data}")

    # TODO: currently we are not handling if module settings change
    if __salt__['pillar.get'](f'pam:{module_name}:enable', False):
      pam_module_condition_cmdline = pam_module_add_condition_cmdline(module_name)
      pam_module_cmdline = ["pam-config", "--add", f"--{module_name}"]

      for option in module_data.get('options', []):
        module_setting = __salt__['pillar.get'](f"pam:{module_name}:{option}", None)
        log.error(f"Handling option {option} with module setting {module_setting}")

        if not(module_setting is None):
          if isinstance(option, bool):
            pam_module_cmdline.append(f"--{module_name}-{option}")
          else:
            pam_module_cmdline.append(f"--{module_name}-{option}={module_setting}")
    else:
      pam_module_cmdline = ["pam-config", "--delete", f"--{module_name}"]
      pam_module_condition_cmdline = pam_module_delete_condition_cmdline(module_name)

    config[f'pam_module_{module_name}'] = {
      'cmd.run': [
        {'name': " ".join(pam_module_cmdline)},
        {'unless': pam_module_condition_cmdline}
      ]
    }

  return config
