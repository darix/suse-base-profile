# A very opinionated formula to do a base config of a SUSE machine

## What can the formula do?

Lots and lots of things :)

## installation

Just add the hook it up like every other formula and do the needed

### Required salt master config:

```
file_roots:
  base:
    - {{ salt_base_dir }}/salt
    - {{ formulas_base_dir }}/suse-base-profile/salt/

pillar_roots:
  base:
    - {{ formulas_base_dir }}/suse-base-profile/pillar/
    - {{ salt_base_dir }}/pillar/
module_dirs:
  - {{ salt_base_dir }}/modules
  - {{ formulas_base_dir }}/suse-base-profile/modules/
```

### pillar/top.sls

```
base:
   '*':
     - profile-base
     <load remainining things here>
```

The order is important so you can override our defaults.

## License

[AGPL-3.0-only](https://spdx.org/licenses/AGPL-3.0-only.html)
