from typing import Optional

from .ip_bits import IpBits
from .ipaddress import IPAddress
from .prefix128 import Prefix128
from .prefix32 import Prefix32


class Ipv4:
    @staticmethod
    def from_number(addr: int, prefix_num: int) -> Optional[IPAddress]:
        prefix = Prefix32.create(prefix_num)
        if prefix is None:
            return None
        return IPAddress(
            IpBits.v4(),
            addr,
            prefix,
            None,
            Ipv4.ipv4_is_private,
            Ipv4.ipv4_is_loopback,
            Ipv4.to_ipv6,
        )

    @staticmethod
    def create(s: str) -> Optional[IPAddress]:
        ip, netmask = IPAddress.split_at_slash(s)
        if not IPAddress.is_valid_ipv4(ip):
            return None
        ip_prefix_num = 32
        if netmask:
            ip_prefix_num = IPAddress.parse_netmask_to_prefix(netmask)
            if ip_prefix_num is None:
                return None
        ip_prefix = Prefix32.create(ip_prefix_num)
        if ip_prefix is None:
            return None
        split_number = IPAddress.split_to_u32(ip)
        if split_number is None:
            return None
        return IPAddress(
            IpBits.v4(),
            split_number,
            ip_prefix,
            None,
            Ipv4.ipv4_is_private,
            Ipv4.ipv4_is_loopback,
            Ipv4.to_ipv6,
        )

    @staticmethod
    def ipv4_is_private(my: IPAddress) -> bool:
        return any(
            net.includes(my)
            for net in [
                IPAddress.parse("10.0.0.0/8"),
                IPAddress.parse("169.254.0.0/16"),
                IPAddress.parse("172.16.0.0/12"),
                IPAddress.parse("192.168.0.0/16"),
            ]
        )

    @staticmethod
    def ipv4_is_loopback(my: IPAddress) -> bool:
        return IPAddress.parse("127.0.0.0/8").includes(my)

    @staticmethod
    def to_ipv6(ia: IPAddress) -> Optional[IPAddress]:
        from .ipv6 import Ipv6

        return IPAddress(
            IpBits.v6(),
            ia.host_address,
            Prefix128.create(ia.prefix.num),
            None,
            Ipv6.ipv6_is_private,
            Ipv6.ipv6_is_loopback,
            Ipv6.to_ipv6,
        )

    # Checks whether the ip address belongs to a
    # RFC 791 CLASS A network, no matter
    # what the subnet mask is.
    #
    # Example:
    #
    #   ip = IPAddress("10.0.0.1/24")
    #
    #   ip.a?
    #     // => true
    #
    @staticmethod
    def is_class_a(my: IPAddress) -> bool:
        return my.is_ipv4() and my.host_address < int("80000000", 16)

    # Checks whether the ip address belongs to a
    # RFC 791 CLASS B network, no matter
    # what the subnet mask is.
    #
    # Example:
    #
    #   ip = IPAddress("172.16.10.1/24")
    #
    #   ip.b?
    #     // => true
    #
    @staticmethod
    def is_class_b(my: IPAddress) -> bool:
        return my.is_ipv4() and int("80000000", 16) <= my.host_address < int(
            "c0000000", 16
        )

    # Checks whether the ip address belongs to a
    # RFC 791 CLASS C network, no matter
    # what the subnet mask is.
    #
    # Example:
    #
    #   ip = IPAddress("192.168.1.1/30")
    #
    #   ip.c?
    #     // => true
    #
    @staticmethod
    def is_class_c(my: IPAddress) -> bool:
        return my.is_ipv4() and int("c0000000", 16) <= my.host_address < int(
            "e0000000", 16
        )

    # Creates a new IPv4 address object by parsing the
    # address in a classful way.
    #
    # Classful addresses have a fixed netmask based on the
    # class they belong to:
    #
    # * Class A, from 0.0.0.0 to 127.255.255.255
    # * Class B, from 128.0.0.0 to 191.255.255.255
    # * Class C, D and E, from 192.0.0.0 to 255.255.255.254
    #
    # Example:
    #
    #   ip = IPAddress::IPv4.parse_classful "10.0.0.1"
    #
    #   ip.netmask
    #     // => "255.0.0.0"
    #   ip.a?
    #     // => true
    #
    # Note that classes C, D and E will all have a default
    # prefix of /24 or 255.255.255.0
    #
    @staticmethod
    def parse_classful(ip_si: str) -> Optional[IPAddress]:
        if not IPAddress.is_valid_ipv4(ip_si):
            return None
        o_ip = IPAddress.parse(ip_si)
        if o_ip is None:
            return None
        ip = o_ip
        if Ipv4.is_class_a(ip):
            ip.prefix = Prefix32.create(8)
        elif Ipv4.is_class_b(ip):
            ip.prefix = Prefix32.create(16)
        elif Ipv4.is_class_c(ip):
            ip.prefix = Prefix32.create(24)
        return ip


__all__ = ["Ipv4"]
