zypper:
  refreshdb_force: false

zypp:
  config:
    zypp.conf:
      solver.onlyRequires: 'true'
      download.use_deltarpm: 'false'
      solver.dupAllowVendorChange: 'false'
    zypper.conf:
      runSearchPackages: 'never'
{%- if grains.osfullname == "SLES" %}
  products_enable_debug: false
  products:
    15:
      - SLE-Product-SLES
      - SLE-Module-Basesystem
{%- endif %}