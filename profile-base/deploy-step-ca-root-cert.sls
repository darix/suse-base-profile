{%- if 'step_ca_root_cert' in pillar %}
## needs
## install -D -o salt -g salt -m 0640 /var/lib/step-ca/.step/certs/root_ca.crt /srv/salt/file_tree/nodegroups/all/step_ca_root_cert
##
root_cert_deploy:
  file.managed:
    - name: /usr/share/pki/trust/anchors/step-ca-kanku.crt.pem
    - user: root
    - group: root
    - mode: 0640
    - contents_pillar: step_ca_root_cert
  cmd.run:
    - name: /usr/sbin/update-ca-certificates
{%- else %}
root_cert_deploy:
  file.absent:
    - name: /usr/share/pki/trust/anchors/step-ca-kanku.crt.pem
  cmd.run:
    - name: /usr/sbin/update-ca-certificates
{%- endif %}
