ipsets_persistent_dump:
  cmd.run:
    - name: /usr/sbin/ipset save -file /etc/ferm/ipset
