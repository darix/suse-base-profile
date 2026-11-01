resticprofile:
  config:
    global:
      ionice: true
      ionice-class: 3
      ionice-level: 7
      nice: 19
      priority: background
      prevent-sleep: true
    default:
      backup:
        exclude-caches: true
        one-file-system: true
        schedule: daily
        schedule-lock-wait: 2h
        schedule-permission: system
      password-file: /etc/resticprofile/{{ grains.id }}.key
      retention:
        compact: false
        host: true
        keep-daily: 1
        keep-hourly: 5
        keep-last: 3
        keep-monthly: 30
        keep-tag:
        - forever
        keep-weekly: 10
        keep-within: 3h
        keep-yearly: 1
        prune: false
        tag: true
      forget:
        keep-last: 3
        keep-hourly: 5
        keep-daily: 1
        keep-weekly: 10
        keep-monthly: 30
        keep-yearly: 1
        keep-within: "3h"
        keep-tag:
          - "forever"
        compact: true
        prune: true
        # path can be a boolean ('true' meaning to copy source paths from 'backup')
        # or a path or list of paths to use instead. Default is `true` if not specified.
        #path: []
        # tag can be a boolean ('true' meaning to copy tag set from 'backup')
        # or a custom set of tags. Default is 'false', meaning that tags are NOT used.
        tag: true
        # host can be a boolean ('true' meaning current hostname) or a string to specify a different hostname
        host: true
    root:
      inherit: default
      backup:
        source:
          - /etc/
          - /root/
