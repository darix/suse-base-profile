def certtypes(certdata):
  if 'cert_types' in certdata:
    return certdata['cert_types']
  if 'cert_types' in __pillar__['dehydrated']:
    return __pillar__['dehydrated']['cert_types']
  return ['rsa', 'ecdsa']

def certpaths(certdata):
  return_data = []
  cert_primary_domain = certdata['domains'][0]
  for cert_type in certtypes(certdata):
    return_data.append(f"/etc/ssl/services/{cert_primary_domain}.with.chain.pem.{cert_type}")
  return return_data
