ca-certificates:
  pkg.installed:
    - pkgs:
      - ca-certificates-buildops: ">=1.3"
      - ca-certificates-suse
    - fromrepo: SUSE_CA

remove_old_company_cas:
  pkg.purged:
    - names:
      - ca-certificates-netiq
      - ca-certificates-attachmate
      - ca-certificates-microfocus

