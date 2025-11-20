#
# suse-base-profile
#
# Copyright (C) 2025   darix
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

#
# Usage:
#
# The indent levels are important!
#
# haproxy_config:
#   filetreedeployer.deploy:
#     - config:
#         pillar_prefix: 'configs'     # required
#         pillar_path:   'etc:haproxy' # required
#         dir_mode:      750           # optional: default: 755
#         file_mode:     640           # optional: default: 644
#         user:          root          # optional: default: root
#         group:         haproxy       # optional: default: root
#         affected_states:
#           require_in:
#             - haproxy_service
#           onchanges_in:
#             - haproxy_service
#     - overrides:                     # optional: allows overriding dir_mode, file_mode, user, group
#         {%- for filename in ['/etc/haproxy/certlist-gen', '/etc/haproxy/verify-ssl'] %}
#         {{ filename }}:
#            file_mode: 750
#         {%- endfor %}

class FileTreeDeploy:
    def __init__(self, section_data):
        self.ret = { 'name':     section_data.get('name'),
                     'result':   True,
                     'changes':  {},
                     'comment':  ''}
        self.config = section_data.get('config')

        self.pillar_prefix     = self.config.get('pillar_prefix')
        self.pillar_path       = self.config.get('pillar_path')

        self.default_dir_mode  = self.config.get('dir_mode',  755)
        self.default_file_mode = self.config.get('file_mode', 644)
        self.default_user      = self.config.get('user',      'root')
        self.default_group     = self.config.get('group',     'root')

        self.overrides         = section_data.get('overrides', dict())

        self.require_in        = section_data.get('affected_states', {}).get('require_in', [])
        self.onchanges_in      = section_data.get('affected_states', {}).get('onchanges_in', [])

        if self.pillar_prefix == None or self.pillar_path == None:
            raise ValueError("pillar_prefix and pillar_path can not be empty")

        #raise ValueError(self.default_dir_mode)
        self.full_pillar_path   = self.pillar_prefix + ':' + self.pillar_path
        self.target_prefix      = '/' + self.pillar_path.replace(':', '/')

    def get_permissions(self,path):
        file_settings = self.overrides.get(path, dict())

        dir_mode  = file_settings.get('dir_mode',  self.default_dir_mode)
        file_mode = file_settings.get('file_mode', self.default_file_mode)
        user      = file_settings.get('user',      self.default_user)
        group     = file_settings.get('group',     self.default_group)

        return dir_mode, file_mode, user, group

    def process_item(self, pillar_path, target_prefix):
        for item_path in __salt__['pillar.keys'](pillar_path):
            target_path = target_prefix + '/' + item_path
            sub_item_path = pillar_path + ':' + item_path
            try:
                sub_items = __salt__['pillar.keys'](sub_item_path)
                if len(sub_items) > 0:
                    self.directory_item(target_path)
                    self.process_item(sub_item_path, target_path)
            except ValueError as ex:
                self.file_item(target_path, sub_item_path)
                pass

    def file_item(self, target_path, pillar_path):
        dir_mode, file_mode, user, group = self.get_permissions(target_path)
        ret = __states__['file.managed'](
            name            = target_path,
            dir_mode        = dir_mode,
            mode            = file_mode,
            user            = user,
            group           = group,
            contents_pillar = pillar_path,
            require_in      = self.require_in,
            onchanges_in    = self.onchanges_in
        )
        self.update_return_data(target_path, ret)

    def directory_item(self, target_path):
        dir_mode, file_mode, user, group = self.get_permissions(target_path)
        ret = __states__['file.directory'](
            name            = target_path,
            mode            = dir_mode,
            user            = user,
            group           = group
        )
        self.update_return_data(target_path, ret)

    def update_return_data(self, target_path, ret):
        if ret['result'] is not None:
          self.ret['result'] = self.ret['result'] & ret['result']
        if len(ret['changes']) > 0:
            self.ret['changes'][target_path] = ret['changes']

    def deploy(self):
        self.directory_item(self.target_prefix)

        self.process_item(self.full_pillar_path, self.target_prefix)

        __salt__['log.debug']('filetreedeployer: {0}'.format(self.ret))

        if __opts__['test']:
          if self.ret['result']:
            if self.ret['changes']:
              self.ret['comment'] = "Would update {0} using {1}".format(self.target_prefix, self.full_pillar_path)
            else:
              self.ret['comment'] = "No changes, {0} already matches {1}".format(self.target_prefix, self.full_pillar_path)
          else:
            self.ret['comment'] = "Failed to test state"

        elif not __opts__['test']:
          if self.ret['result']:
            if self.ret['changes']:
              self.ret['comment'] = "Successfully deployed {0} to {1}".format(self.full_pillar_path, self.target_prefix)
            else:
              self.ret['comment'] = "No changes, {0} already matches {1}".format(self.target_prefix, self.full_pillar_path)
          else:
              self.ret['comment'] = "Failed to deploy {0} to {1}".format(self.full_pillar_path, self.target_prefix)
        else:
          __salt__['log.error']('Illegal opts:test value, this should not happen!')

        __salt__['log.debug']('filetreedeployer: {0}'.format(self.ret))

        return self.ret

def deploy(name, config, overrides={}):
    section_data = { 'name': name, 'config': config, 'overrides': dict() }
    ftd = FileTreeDeploy( section_data )
    return ftd.deploy()
