upgrade_salt:
  pkg.latest:
    - name: salt
    - order: last
