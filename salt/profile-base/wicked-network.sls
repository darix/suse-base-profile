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

#!py
#
from salt._compat import ipaddress
import re
import logging

log = logging.getLogger(__name__)

class WickedBaseInterface:
    def __init__(self, interface_name, interface_data):
        self.interface_name = interface_name
        self.interface_data = interface_data

        self.ifcfg_our_keywords = [
            "setup_ifrules_only",
            "local_default_route",
            "global_default_route",
            "ipv4_addr",
            "ipv6_addr",
            "enabled"
        ]

        self.config = {}
        self.reload_deps = []

        self.routes = []
        self.table_name = None

        self.ifcfg_section = "ifcfg_{interface_name}".format(
            interface_name=interface_name
        )
        self.ifcfg_path = "/etc/sysconfig/network/ifcfg-{interface_name}".format(
            interface_name=interface_name
        )

        self.ifrule_section = "ifrule_{interface_name}".format(
            interface_name=interface_name
        )
        self.ifrule_path = "/etc/sysconfig/network/ifrule-{interface_name}".format(
            interface_name=interface_name
        )

        self.ifroute_section = "ifroute_{interface_name}".format(
            interface_name=interface_name
        )
        self.ifroute_path = "/etc/sysconfig/network/ifroute-{interface_name}".format(
            interface_name=interface_name
        )

        def routes(self):
            return self.routes

        def table_name(self):
            return self.table_name

        def states(self):
            return self.config

        def reload_deps(self):
            return self.reload_deps

class WickedDisabledInterface(WickedBaseInterface):
    def __init__(self, interface_name, interface_data):
        super().__init__(interface_name, interface_data)

        self.config[self.ifcfg_section] = {
            "file.absent": [
                {"name": self.ifcfg_path},
            ]
        }
        self.config[self.ifrule_section] = {
            "file.absent": [
                {"name": self.ifrule_path},
            ]
        }
        self.config[self.ifroute_section] = {
            "file.absent": [
                {"name": self.ifroute_path},
            ]
        }
        self.reload_deps = [self.ifcfg_section, self.ifrule_section, self.ifroute_section]

class WickedActiveInterface(WickedBaseInterface):
    def __init__(self, interface_name, interface_data, needs_rule_based_routing):
        super().__init__(interface_name, interface_data)

        self.table_name = self.table_from_interface()
        self.needs_rule_based_routing = needs_rule_based_routing

        self.ifcfg_data_list = []
        self.ifrule_data_list = []
        self.ifroute_data_list = []

        global_default_route = (
            ( "global_default_route" in interface_data and interface_data["global_default_route"] ) or
            not (self.needs_rule_based_routing)
        )

        if global_default_route:
            self.add_global_default_routes()

        ip_counter = 0
        local_ips = []

        if not ("startmode" in interface_data):
            self.ifcfg_data_list.append("STARTMODE='auto'")

        if not ("bootproto" in interface_data):
            self.ifcfg_data_list.append("BOOTPROTO='static'")

        for key, value in interface_data.items():
            if key in self.ifcfg_our_keywords:
                if key in ["ipv4_addr", "ipv6_addr"]:

                    protocol = key[0:4]

                    for address in value:
                        ip_interface = ipaddress.ip_interface(address)
                        address_without_netmask = ip_interface.ip.__str__()
                        network_range = ip_interface.network.__str__()

                        local_ips.append(address_without_netmask)

                        self.ifcfg_data_list.append(
                            "IPADDR_{index}='{value}'".format(
                                index=ip_counter, value=address
                            )
                        )
                        ip_counter += 1

                        if self.needs_rule_based_routing:
                            self.ifrule_data_list.append(
                                "{protocol} from {address} table {table_name}".format(
                                    protocol=protocol,
                                    address=address_without_netmask,
                                    table_name=self.table_name,
                                )
                            )
                            self.ifroute_data_list.append(
                                "{network_range} - - {interface_name} table {table_name} src {address} scope link".format(
                                    network_range=network_range,
                                    interface_name=self.interface_name,
                                    table_name=self.table_name,
                                    address=address_without_netmask,
                                )
                            )
            else:
                self.ifcfg_data_list.append(
                    "{key}='{value}'".format(key=key.upper(), value=value)
                )

        if 'bonding_master' in interface_data and interface_data['bonding_master']:
            mac_address = self.mac_address_of_primary_interface_from_bond(interface_name)
            log.debug("Found mac address from parent {interface_name}: {mac_address}".format(interface_name=interface_name, mac_address=mac_address))
            self.ifcfg_data_list.append("LLADDR='{mac_address}'".format(mac_address=mac_address))

        if 'bridge' in interface_data and interface_data['bridge']:
            mac_address = self.mac_address_of_primary_interface_from_bridge(interface_name)
            log.debug("Found mac address from parent {interface_name}: {mac_address}".format(interface_name=interface_name, mac_address=mac_address))
            self.ifcfg_data_list.append("LLADDR='{mac_address}'".format(mac_address=mac_address))

        if 'interfaces_shared_settings' in __pillar__['network']:
           for key, value in __pillar__['network']['interfaces_shared_settings'].items():
                self.ifcfg_data_list.append(
                    "{key}='{value}'".format(key=key.upper(), value=value)
                )

        if self.needs_rule_based_routing:
            self.add_local_default_routes(local_ips)

        ifcfg_data = "\n".join(self.ifcfg_data_list)

        self.reload_deps.append(self.ifcfg_section)

        self.config[self.ifcfg_section] = {
            "file.managed": [
                {"name": self.ifcfg_path},
                {"user": "root"},
                {"group": "root"},
                {"mode": "0640"},
                {"contents": ifcfg_data},
            ]
        }

        if self.needs_rule_based_routing:
            if len(self.ifrule_data_list) > 0:

                self.reload_deps.append(self.ifrule_section)

                ifrule_data = "\n".join(self.ifrule_data_list)

                self.config[self.ifrule_section] = {
                    "file.managed": [
                        {"name": self.ifrule_path},
                        {"user": "root"},
                        {"group": "root"},
                        {"mode": "0640"},
                        {"contents": ifrule_data},
                    ]
                }
            else:
                self.config[self.ifrule_section] = {
                    "file.absent": [
                        {"name": self.ifrule_path},
                    ]
                }

            if len(self.ifroute_data_list) > 0 and ip_counter > 0:

                self.reload_deps.append(self.ifroute_section)

                ifroute_data = "\n".join(self.ifroute_data_list)

                self.config[self.ifroute_section] = {
                    "file.managed": [
                        {"name": self.ifroute_path},
                        {"user": "root"},
                        {"group": "root"},
                        {"mode": "0640"},
                        {"contents": ifroute_data},
                    ]
                }
            else:
                self.config[self.ifroute_section] = {
                    "file.absent": [
                        {"name": self.ifroute_path},
                    ]
                }
        else:
           self.config[self.ifrule_section] = {
               "file.absent": [
                   {"name": self.ifrule_path},
               ]
           }
           self.config[self.ifroute_section] = {
               "file.absent": [
                   {"name": self.ifroute_path},
               ]
           }

    def table_from_interface(self):
        return re.sub("_", "-", self.interface_name)

    def mac_address_of_primary_interface_from_bridge(self, bridge_name):
        bridge_port_interface = __pillar__["network"]["interfaces"][bridge_name]['bridge_ports']

        if 'etherdevice' in __pillar__["network"]["interfaces"][bridge_port_interface]:
           parent_interface = __pillar__["network"]["interfaces"][bridge_port_interface]['etherdevice']
           return self.mac_address_of_primary_interface_from_bond(parent_interface)

        if 'bonding_master' in __pillar__["network"]["interfaces"][bridge_port_interface] and __pillar__["network"]["interfaces"][bridge_port_interface]['bonding_master']:
           return self.mac_address_of_primary_interface_from_bond(bridge_port_interface)

        return __pillar__["udev"]["net"][bridge_port_interface]

    def mac_address_of_primary_interface_from_bond(self, bond_name):
        hw_interface = __pillar__["network"]["interfaces"][bond_name]['bonding_slave0']
        mac_address = __pillar__["udev"]["net"][hw_interface]
        return mac_address


    def add_local_default_routes(self, local_ips):
        if (
            "default_gateways" in __pillar__["network"] and
            self.interface_name in __pillar__["network"]["default_gateways"]
        ):
            for protocol_type, address in __pillar__["network"]["default_gateways"][self.interface_name].items():
                if not(address in local_ips):
                    self.ifroute_data_list.append(
                        "default {gateway_address} - {interface_name} table {table_name}".format(
                            gateway_address=address,
                            interface_name=self.interface_name,
                            table_name=self.table_name,
                        )
                    )


    def add_global_default_routes(self):
        if (
            "default_gateways" in __pillar__["network"] and
            self.interface_name in __pillar__["network"]["default_gateways"]
        ):
            for protocol_type, address in __pillar__["network"]["default_gateways"][self.interface_name].items():
                self.routes.append(
                    "default {gateway_address} - {interface_name}".format(
                        gateway_address=address,
                        interface_name=self.interface_name,
                    )
                )


class WickedNetworkConfig:
    def __init__(self):

        self.config = {}

        self.rt_tables = []
        self.routes = []

        self.needs_rule_based_routing = False

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


    def check_if_needs_rule_based_routing(self):
        default_routes_found = 0
        for interface, interface_data in __pillar__["network"]["interfaces"].items():

            interface_is_active = True

            if "enabled" in interface_data:
                interface_is_active = interface_data["enabled"]

            if (
                interface_is_active and
                "default_gateways" in __pillar__["network"] and
                interface in __pillar__["network"]["default_gateways"]
            ):
               default_routes_found += 1
        return (default_routes_found > 1)

    def states(self):

        if (
            "network" in __pillar__ and
            "type" in __pillar__["network"] and
            __pillar__["network"]["type"] == "wicked"
        ):

            reload_deps = []

            if "routes" in __pillar__["network"]:
                self.routes = __pillar__["network"]["routes"]

            if "interfaces" in __pillar__["network"]:
                self.needs_rule_based_routing = self.check_if_needs_rule_based_routing()

                for interface_name, interface_data in __pillar__["network"]["interfaces"].items():

                    interface_is_active = True

                    if "enabled" in interface_data:
                        interface_is_active = interface_data["enabled"]

                    wicked_interface=None

                    if interface_is_active:
                        wicked_interface = WickedActiveInterface(interface_name, interface_data, self.needs_rule_based_routing)
                    else:
                        wicked_interface = WickedDisabledInterface(interface_name, interface_data)

                    if wicked_interface:
                        table_name = wicked_interface.table_name
                        if self.needs_rule_based_routing and table_name:
                            self.rt_tables.append(table_name)
                        self.routes += wicked_interface.routes
                        reload_deps += wicked_interface.reload_deps
                        # https://stackoverflow.com/questions/38987/how-do-i-merge-two-dictionaries-in-a-single-expression
                        self.config={ **self.config, **wicked_interface.config }

            reload_deps.append("sysconfig_network_routes")

            if self.needs_rule_based_routing:
                self.routes.insert(0, "# all interface specific routes are in the respective ifroute-* file. This file only contains global routes")

            self.config["sysconfig_network_routes"] = {
                "file.managed": [
                    {"name": "/etc/sysconfig/network/routes"},
                    {"user": "root"},
                    {"group": "root"},
                    {"mode": "0640"},
                    {"contents": "\n".join(self.routes)},
                ]
            }

            self.config["remove_iprule_service_script"] = {
                "file.absent": [
                    {"name": "/usr/local/sbin/iproute-add-rules"},
                ],
            }

            self.config["remove_iprule_service_file"] = {
                "service.disabled": [
                    {"name": "add-ip-rules.service"},
                    {"enable": False},
                ],
                "file.absent": [
                    {"name": "/etc/systemd/system/add-ip-rules.service"},
                ],
                "cmd.run": [
                    {"name": "/usr/bin/systemctl daemon-reload"},
                    {"onchanges": ["/etc/systemd/system/add-ip-rules.service"]},
                ],
            }

            table_index = 1
            rt_tables_list = self.rt_tables_defaults_list

            for table in self.rt_tables:
                rt_tables_list.append("{index} {table}".format(index=table_index, table=table))
                table_index += 1

            reload_deps.append("rt_tables")

            self.config["rt_tables"] = {
                "file.managed": [
                    {"name": "/etc/iproute2/rt_tables"},
                    {"user": "root"},
                    {"group": "root"},
                    {"mode": "0640"},
                    {"contents": "\n".join(rt_tables_list)},
                ]
            }
            if not(__pillar__["prepare_datacenter_switch"]):
                self.config["reload_network"] = {
                    "cmd.run": [
                        {"name": "/usr/bin/systemctl reload network"},
                        {"require": reload_deps},
                        {"onchanges": reload_deps},
                    ]
                }

        return self.config


def run():
    wicked_config = WickedNetworkConfig()
    return wicked_config.states()
