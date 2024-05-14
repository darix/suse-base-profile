import salt.utils.network
import ipaddress

def all_global_addresses(interfaces=None):
    if interfaces is None:
        interfaces = salt.utils.network.interfaces()

    good_addresses = {}

    for interface, interface_data in interfaces.items():
        if interface == 'lo':
            continue

        address_count = 0

        for address_type in ['inet', 'inet6']:
            if address_type not in interface_data:
                continue

            tmp_list = [i['address'] for i in interface_data[address_type] if ('scope' not in i) or ('scope' in i and i['scope'] != 'link')]
            address_count += len(tmp_list)

        if address_count > 0:
            good_addresses+=tmp_list

    return good_addresses

def interface_names_with_global_addresses(interfaces=None):
    return list(interfaces_with_global_addresses(interfaces).keys())


def interfaces_with_global_addresses(interfaces=None):
    if interfaces is None:
        interfaces = salt.utils.network.interfaces()

    interfaces_with_good_addresses = {}

    for interface, interface_data in interfaces.items():
        if interface == 'lo':
            continue

        address_count = 0

        for address_type in ['inet', 'inet6']:
            if address_type not in interface_data:
                continue

            interface_data[address_type] = [i for i in interface_data[address_type] if ('scope' not in i) or ('scope' in i and i['scope'] != 'link')]
            address_count += len(interface_data[address_type])

        if address_count > 0:
            interfaces_with_good_addresses[interface] = interface_data

    return interfaces_with_good_addresses

def is_not_our_private(address_record, address_type):
    private_networks = [
            ipaddress.ip_network('192.168.0.0/16'),
            ipaddress.ip_network('172.16.0.0/12'),
    ]

    matched_networks = 0

    if address_type == 'inet':

        for private_network in private_networks:

            if ipaddress.ip_address(address_record["address"]) in private_network:
                matched_networks += 1

    return (matched_networks == 0)

def is_not_link_local(i):
    return (('scope' not in i) or ('scope' in i and i['scope'] != 'link'))


def interfaces_with_non_private_addresses(interfaces=None):
    if interfaces is None:
        interfaces = salt.utils.network.interfaces()

    interfaces_with_good_addresses = {}

    for interface, interface_data in interfaces.items():
        if interface == 'lo':
            continue

        address_count = 0
        new_interface_data = []

        for address_type in ['inet', 'inet6']:
            if address_type not in interface_data:
                continue

            for i in interface_data[address_type]:
                if is_not_link_local(i) and is_not_our_private(i, address_type):
                    new_interface_data.append(i["address"])

            # interface_data[address_type] = [i for i in interface_data[address_type] if ('scope' not in i) or ('scope' in i and i['scope'] != 'link')]
            address_count += len(new_interface_data)

        if address_count > 0:
            interfaces_with_good_addresses[interface] = ", ".join(new_interface_data)

    return interfaces_with_good_addresses

def only_has_interfaces_with_non_private_addresses(interfaces=None):
    if interfaces is None:
        interfaces = salt.utils.network.interfaces()

    interface_nonprivate = 0
    interface_count = 0

    for interface, interface_data in interfaces.items():
        if interface == 'lo':
            continue

        address_count = 0
        interface_count += 1

        for address_type in ['inet', 'inet6']:
            if address_type not in interface_data:
                continue

            for i in interface_data[address_type]:
                if not(is_not_link_local(i) and is_not_our_private(i, address_type)):
                    interface_nonprivate += 1


    return (interface_count == interface_nonprivate)

def only_link_local_addresses(interfaces=None):
    all_interfaces = salt.utils.network.interfaces()

    interfaces_with_good_addresses = {}

    for interface, interface_data in all_interfaces.items():
        if interface == 'lo':
            continue

        if interface not in interfaces:
            continue

        link_local_address = None

        for address_type in ['inet6']:
            if address_type not in interface_data:
                continue

            new_interface_data = [i['address'] for i in interface_data[address_type] if 'scope' in i and (i['scope'] == 'link')]
            if new_interface_data:
                link_local_address = new_interface_data[0]
                interfaces_with_good_addresses[interface] = link_local_address

    return interfaces_with_good_addresses
