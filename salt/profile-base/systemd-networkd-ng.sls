#!py
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

# udev:
#   net:
#     porta23: de:ad:be:01
#     porta24: de:ad:be:02

# network:
#   type: sn2
#   # normally you would have an include with those to share them
#   default_gateways:
#     br_ipv4:
#        ipv4: 10.10.10.254
#     br_mixed:
#        ipv4: 10.11.11.254
#        ipv6: fc00::11:ffff
#     br_ipv6:
#        ipv6: fc00::12:ffff
#   interfaces:
#     # all devices with an explicite Kind are assumed to be Kind: ether
#     porta23:
#       bonded_to: bond0
#     porta24:
#       network_options:
#         Network:
#            Bond: bond0
#     # bond and bridge devices resolve their mac address automatically to the underlying first bound interface
#     bond0:
#       Kind: bond
#       network_options:
#         Network:
#           VLAN:
#             - vl_ipv4
#             - vl_mixed
#             - vl_ipv6
#     vl_ipv4:
#       Kind: vlan
#       netdev_options:
#         VLAN:
#           Id: 1004
#       network_options:
#         Network:
#            Bridge: br_ipv4
#     vl_ipv4:
#       Kind: vlan
#       bridged_to: br_ipv6
#       netdev_options:
#         VLAN:
#           Id: 1006
#     vl_mixed:
#       Kind: vlan
#       bridged_to: br_mixed
#       netdev_options:
#         VLAN:
#           Id: 1010
#     br_ipv4:
#       Kind: bridge
#       ipv4_addr:
#         - 10.10.10.1
#     br_ipv6:
#       Kind: bridge
#       ipv6_addr:
#         - fc00::12:1
#     br_mixed:
#       global_default_route: True
#       Kind: bridge
#       ipv6_addr:
#         - fc00::11:1
#       ipv4_addr:
#         - 10.11.11.1
#     porta25:
#       mac_address: de:ad:be:03
#       ipv4_addr:
#         - 10.12.12.1

from salt._compat import ipaddress
import re
import os
import logging

import copy

import salt.utils.dictupdate as dictupdate

log = logging.getLogger(__name__)


def render_dict_to_ini_string(data):
    output_list = []
    for section_name, section_data in data.items():
        if isinstance(section_data, list):
            for subsection_data in section_data:
                output_list.append("")
                output_list.append(f"[{section_name}]")
                for key, value in subsection_data.items():
                    if isinstance(value, list):
                        for subvalue in value:
                            output_list.append(f"{key}={subvalue}")
                    else:
                        output_list.append(f"{key}={value}")
        else:
            output_list.append(f"[{section_name}]")
            for key, value in section_data.items():
                if isinstance(value, list):
                    for subvalue in value:
                        output_list.append(f"{key}={subvalue}")
                else:
                    output_list.append(f"{key}={value}")
        output_list.append("")
    return "\n".join(output_list)

def ensure_section(current_config, section):
    if not(section in current_config):
        current_config[section] = {}

def deepmerge(current_config, additional_config):
    return dictupdate.update(copy.deepcopy(current_config), copy.deepcopy(additional_config))

class NetworkdDeviceConfigs:
    def __init__(self):
        self.config={}
        self.unit_requires     = []
        self.unit_requires_in  = []
        self.unit_onchanges_in = []

        self.rt_tables = []
        self.rt_tables_defaults_list = [
                """
#
# reserved values
#
255	local
254	main
253	default
0	unspec
#
# local
#
#1	inr.ruhep
#
"""
            ]

    def ifcfg_section(self, interface_name):
        return f"ifcfg_{interface_name}"

    def ifcfg_path(self, interface_name):
        return f"/etc/sysconfig/network/ifcfg-{interface_name}"

    def ifrule_section(self, interface_name):
        return f"ifrule_{interface_name}"

    def ifrule_path(self, interface_name):
        return f"/etc/sysconfig/network/ifrule-{interface_name}"

    def ifroute_section(self, interface_name):
        return f"ifroute_{interface_name}"

    def ifroute_path(self, interface_name):
        return f"/etc/sysconfig/network/ifroute-{interface_name}"


    def networkd_link_file(self, interface_name):
        return f"/etc/systemd/network/{interface_name}.link"

    def networkd_netdev_file(self, interface_name):
        return f"/etc/systemd/network/{interface_name}.netdev"

    def networkd_network_file(self, interface_name):
        return f"/etc/systemd/network/{interface_name}.network"

    def networkd_link_section(self, interface_name):
        return f"networkd_{interface_name}_link"

    def networkd_netdev_section(self, interface_name):
        return f"networkd_{interface_name}_netdev"

    def networkd_network_section(self, interface_name):
        return f"networkd_{interface_name}_network"

    def systemd_unit_file_state(self, dataset, statename, unitpath):
        if len(dataset) > 0:
            self.config[statename] = {
                "file.managed": [
                    {"name":         unitpath},
                    {"user":         "root"},
                    {"group":        "systemd-network"},
                    {"mode":         "0640"},
                    {"require":      self.unit_requires},
                    {"require_in":   self.unit_requires_in},
                    {"onchanges_in": self.unit_onchanges_in},
                    {"contents":     render_dict_to_ini_string(dataset)},
                ]
            }
    def absent_file_with_deps(self, statename, path):
        self.config[statename] = {
            "file.absent": [
                {'name': path},
                {'require_in':   self.unit_requires_in},
                {'onchanges_in': self.unit_onchanges_in},
            ]
        }

    def purge_all_units_for_interface(self, interface_name):
        self.purge_wicked_units(interface_name)
        self.purge_networkd_units(interface_name)

    def purge_wicked_units(self, interface_name):
        self.absent_file_with_deps(self.ifcfg_section(interface_name),            self.ifcfg_path(interface_name))
        self.absent_file_with_deps(self.ifrule_section(interface_name),           self.ifrule_path(interface_name))
        self.absent_file_with_deps(self.ifroute_section(interface_name),          self.ifroute_path(interface_name))

    def purge_networkd_units(self, interface_name):
        self.absent_file_with_deps(self.networkd_link_section(interface_name),    self.networkd_link_file(interface_name))
        self.absent_file_with_deps(self.networkd_netdev_section(interface_name),  self.networkd_netdev_file(interface_name))
        self.absent_file_with_deps(self.networkd_network_section(interface_name), self.networkd_network_file(interface_name))

    def check_if_needs_rule_based_routing(self):
        default_routes_found = 0
        for interface_name, interface_data in __salt__['pillar.get']('network:interfaces', {}).items():
            if interface_data.get('enabled', True) and __salt__['pillar.get'](f'network:default_gateways:{interface_name}'):
                default_routes_found += 1
        return (default_routes_found > 1)

    def strip_extension(self, filename):
        m=re.compile(r'^(?P<nonext>.*?)\.[^\.]+$')
        return m.match(filename).group('nonext')

    def currently_handled_networkd_devices(self):
        devices = []
        for filename in os.listdir('/etc/systemd/network'):
            devicename = self.strip_extension(filename)
            if devicename not in devices:
                devices.append(devicename)
        return devices

    def table_from_interface(self, interface_name):
        return re.sub("_", "-", interface_name)

    def mac_address(self, interface_name, interface_data):
        return interface_data.get('mac_address', self.udev_net_pillar.get(interface_name))

    def mac_address_of_primary_interface_from_bridge(self, bridge_name):
        # bridge_port_interface = __pillar__["network"]["interfaces"][bridge_name]['bridge_ports']

        # if 'etherdevice' in __pillar__["network"]["interfaces"][bridge_port_interface]:
        #    parent_interface = __pillar__["network"]["interfaces"][bridge_port_interface]['etherdevice']
        #    return self.mac_address_of_primary_interface_from_bond(parent_interface)

        # if 'bonding_master' in __pillar__["network"]["interfaces"][bridge_port_interface] and __pillar__["network"]["interfaces"][bridge_port_interface]['bonding_master']:
        #    return self.mac_address_of_primary_interface_from_bond(bridge_port_interface)

        # return __pillar__["udev"]["net"][bridge_port_interface]
        for hw_interface, data in self.interfaces_pillar.items():
            pillar_key = f"network:interfaces:{hw_interface}:network_options:Network:Bridge"
            if bridge_name == __salt__['pillar.get'](pillar_key, ""):
                return self.udev_net_pillar.get(hw_interface)
            pillar_key = f"network:interfaces:{hw_interface}:bridged_to"
            if bridge_name == __salt__['pillar.get'](pillar_key, ""):
                return self.udev_net_pillar.get(hw_interface)
            return self.mac_address_of_primary_interface_from_bond(hw_interface)

    def mac_address_of_primary_interface_from_bond(self, bond_name):
        for hw_interface, data in self.interfaces_pillar.items():
            pillar_key = f"network:interfaces:{hw_interface}:network_options:Network:Bond"
            if bond_name == __salt__['pillar.get'](pillar_key, ""):
                return self.udev_net_pillar.get(hw_interface)
            pillar_key = f"network:interfaces:{hw_interface}:bonded_to"
            if bond_name == __salt__['pillar.get'](pillar_key, ""):
                return self.udev_net_pillar.get(hw_interface)
        return None

    def states(self):
        networkd_packages = ["systemd-networkd"]

        networkd_packages_state = "systemd_networkd_packages"
        networkd_service_state  = "systemd_networkd_service"

        if 'networkd-ng' == __salt__['pillar.get']('network:type', ''):

            self.udev_net_pillar   = __salt__['pillar.get']("udev:net", {})
            self.interfaces_pillar = __salt__['pillar.get']('network:interfaces', {})
            self.unit_requires.append(networkd_packages_state)
            self.unit_requires_in.append(networkd_service_state)
            self.unit_onchanges_in.append(networkd_service_state)
            self.needs_rule_based_routing = self.check_if_needs_rule_based_routing()

            current_devices = self.currently_handled_networkd_devices()

            for interface_name, interface_data in self.interfaces_pillar.items():
                if interface_name in current_devices:
                    current_devices.remove(interface_name)
                tablename = self.table_from_interface(interface_name)
                interface_type = interface_data.get('Kind', 'ether')
                interface_match_type = interface_data.get('Kind', '!bond !vlan !bridge')
                interface_mtu = interface_data.get('mtu', 1500)

                mac_address = None
                network_file_data = {}
                netdev_file_data = {}
                link_file_data = {}
                match interface_type:
                    case 'vlan':
                        netdev_file_data= {
                            'NetDev': {
                                'Name': interface_name,
                                'Kind': 'vlan',
                                'MTUBytes': interface_mtu,
                            },
                        }
                        netdev_file_data = deepmerge(netdev_file_data, interface_data.get('netdev_options', {}))

                    case 'bond':
                        mac_address = self.mac_address_of_primary_interface_from_bond(interface_name)
                        netdev_file_data= {
                            'NetDev': {
                                'Name': interface_name,
                                'Kind': 'bond',
                                'MTUBytes': interface_mtu,
                            },
                            'Bond': {
                                'Mode': '802.3ad',
                                'MIIMonitorSec': '100',
                                'LACPTransmitRate': 'fast',
                            }
                        }
                        if mac_address is not None:
                            netdev_file_data['NetDev']['MACAddress'] = mac_address

                        netdev_file_data = deepmerge(netdev_file_data, interface_data.get('netdev_options', {}))

                    case 'bridge':
                        mac_address = self.mac_address_of_primary_interface_from_bridge(interface_name)
                        netdev_file_data= {
                            'NetDev': {
                                'Name': interface_name,
                                'Kind': 'bridge',
                                'MTUBytes':  interface_mtu,
                            },
                        }
                        if mac_address is not None:
                            netdev_file_data['NetDev']['MACAddress'] = mac_address
                        netdev_file_data = deepmerge(netdev_file_data, interface_data.get('netdev_options', {}))

                    case _:
                        mac_address = __salt__['pillar.get'](f'udev:net:{interface_name}', interface_data.get('mac_address'))
                        link_file_data = {
                            'Match': {
                                'Kind': interface_match_type,
                                'MACAddress': mac_address,
                            },
                            'Link': {
                                'Name': interface_name,
                            }
                        }

                        link_file_data = deepmerge(link_file_data, interface_data.get('link_options', {}))
                network_file_data['Match'] = { 'Kind': interface_match_type }

                if mac_address is None:
                    network_file_data['Match']['Name'] = interface_name
                else:
                    network_file_data['Match']['MACAddress']= mac_address

                addresses = interface_data.get('ipv4_addr', []) + interface_data.get('ipv6_addr', [])

                if len(addresses) > 0:
                    network_file_data['Network'] = {
                        'Address': addresses,
                    }

                    if 0 == pillar.get('net.ipv6.conf.default.accept_ra', 1) or 0 == pillar.get('net.ipv6.conf.all.accept_ra', 1):
                        network_file_data['Network']['IPv6AcceptRA'] = 'no'

                    if 0 == pillar.get('net.ipv6.conf.default.autoconf', 1) or 0 == pillar.get('net.ipv6.conf.all.autoconf', 1):
                        network_file_data['Network']['LinkLocalAddressing'] = 'no'

                    if self.needs_rule_based_routing:
                        network_file_data["RoutingPolicyRule"] = []
                        network_file_data["Route"] = []

                        self.rt_tables.append(tablename)

                        for address in addresses:
                            ip_interface = ipaddress.ip_interface(address)
                            address_without_netmask = ip_interface.ip.__str__()
                            network_range = ip_interface.network.__str__()
                            network_file_data["RoutingPolicyRule"].append({
                                    'From': address_without_netmask,
                                    'Table': tablename

                                }
                            )
                            network_file_data["Route"].append({
                                    'Destination': network_range,
                                    'Table': tablename,
                                }
                            )

                        for protocol, gateway in __salt__['pillar.get'](f"network:default_gateways:{interface_name}", {}).items():
                            network_file_data["Route"].append({
                                    'Gateway': gateway,
                                    'Table': tablename,
                                }
                            )

                if 'bonded_to' in interface_data:
                    ensure_section(network_file_data, 'Network')
                    network_file_data['Network']['Bond'] = interface_data['bonded_to']

                if 'bridged_to' in interface_data:
                    ensure_section(network_file_data, 'Network')
                    network_file_data['Network']['Bridge'] = interface_data['bridged_to']

                if interface_data.get("global_default_route", False):
                    ensure_section(network_file_data, 'Network')
                    network_file_data['Network']['Gateway'] = []

                    for protocol, gateway in __salt__['pillar.get'](f"network:default_gateways:{interface_name}", {}).items():
                        network_file_data['Network']['Gateway'].append(gateway)

                network_file_data = deepmerge(network_file_data, interface_data.get('network_options', {}))

                self.systemd_unit_file_state(link_file_data,    self.networkd_link_section(interface_name),    self.networkd_link_file(interface_name))
                self.systemd_unit_file_state(netdev_file_data,  self.networkd_netdev_section(interface_name),  self.networkd_netdev_file(interface_name))
                self.systemd_unit_file_state(network_file_data, self.networkd_network_section(interface_name), self.networkd_network_file(interface_name))

            for interface_name in current_devices:
                self.purge_all_units_for_interface(interface_name)

            table_index = 1
            rt_tables_list = self.rt_tables_defaults_list
            rt_tables_networkd_list = []

            for table in self.rt_tables:
                rt_tables_list.append(f"{table_index} {table}")
                rt_tables_networkd_list.append(f"{table}:{table_index}")
                table_index += 1

            self.config["rt_tables_dir"] = {
                "file.directory": [
                    {"name": "/etc/iproute2/"},
                    {"user": "root"},
                    {"group": "root"},
                    {"mode": "0755"},
                ]
            }

            self.config["rt_tables"] = {
                "file.managed": [
                    {"name": "/etc/iproute2/rt_tables"},
                    {"user": "root"},
                    {"group": "root"},
                    {"mode": "0640"},
                    {"require": ["rt_tables_dir"]},
                    {"require_in": [networkd_service_state]},
                    {"onchanges_in": [networkd_service_state]},
                    {"contents": "\n".join(rt_tables_list)},
                ]
            }
            rt_tables_networkd_value = render_dict_to_ini_string({'Network': {'RouteTable': " ".join(rt_tables_networkd_list)}})
            self.config["networkd_conf_snippet_file"] = {
                "file.managed": [
                    {'name': '/etc/systemd/networkd.conf.d/routing_tables.conf'},
                    {'user': 'root'},
                    {'group': 'root'},
                    {'mode': '0644'},
                    {"require_in": [networkd_service_state]},
                    {"onchanges_in": [networkd_service_state]},
                    {'contents': rt_tables_networkd_value},
                ]
            }

            self.config[networkd_packages_state] = {
                'pkg.installed': [
                    {'pkgs': networkd_packages},
                ]
            }
            for network_service in ['NetworkManager', 'wicked', 'wickedd']:
                self.config[f"disable_{network_service}"] = {
                    'service.dead': [
                        {'name': network_service},
                        {'enable', False},
                        {'require_in': [networkd_service_state]}
                    ]
                }
            self.config[networkd_service_state] = {
                # 'service.enabled': [
                #     {'name': 'systemd-networkd'},
                #     {'enable': True},
                # ],
                'cmd.run': [
                    {'name': "echo /usr/bin/networkctl reload"},
                ]
            }

        else:
            for interface_name in __salt__['pillar.get']('network:interfaces', {}).keys():
                self.purge_all_units_for_interface(interface_name)

            # self.config[networkd_service_state] = {
            #     'service.dead': [
            #         {'name': 'systemd-networkd'},
            #         {'enable': False},
            #     ],
            #     'pkg.purged': [
            #         {'pkgs': networkd_packages},
            #     ]
            # }
        return self.config

def run():
    networkd_config = NetworkdDeviceConfigs()
    return networkd_config.states()
