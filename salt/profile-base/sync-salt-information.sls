clear_cache:
  module.run:
    - name: saltutil.clear_cache

sync_all:
  module.run:
    - name: saltutil.sync_all
    - refresh: True

refresh_grains:
  module.run:
    - name: saltutil.refresh_grains

mine_update:
  module.run:
    - name: mine.update
    - refresh: True


