from typing import Optional

from .ip_bits import IpBits
from .ipaddress import IPAddress
from .prefix128 import Prefix128

# =Name
#
# IPAddress::IPv6 - IP version 6 address manipulation library
#
# =Synopsis
#
#    require 'ipaddress'
#
# =Description
#
# Class IPAddress::IPv6 is used to handle IPv6 type addresses.
#
# == IPv6 addresses
#
# IPv6 addresses are 128 bits long, in contrast with IPv4 addresses
# which are only 32 bits long. An IPv6 address is generally written as
# eight groups of four hexadecimal digits, each group representing 16
# bits or two octect. For example, the following is a valid IPv6
# address:
#
#   2001:0db8:0000:0000:0008:0800:200c:417a
#
# === Compression
#
# Since IPv6 addresses are very long to write, there are some
# semplifications and compressions that you can use to shorten them.
#
# * Leading zeroes: all the leading zeroes within a group can be
#   omitted: "0008" would become "8"
#
# * A string of consecutive zeroes can be replaced by the string
#   "::". This can be only applied once.
#
# === Network Mask
#
# As we used to do with IPv4 addresses, an IPv6 address can be written
# using the prefix notation to specify the subnet mask:
#
#   2001:db8::8:800:200c:417a/64
#


class Ipv6:
    @staticmethod
    def from_str(s: str, radix: int, prefix: int) -> Optional[IPAddress]:
        try:
            num = int(s, radix)
        except ValueError:
            return None
        return Ipv6.from_int(num, prefix)

    @staticmethod
    def enhance_if_mapped(ip: IPAddress) -> Optional[IPAddress]:
        if ip.is_mapped():
            return ip
        ipv6_top_96bit = ip.host_address >> 32
        if ipv6_top_96bit == 0xFFFF:
            num = ip.host_address % (1 << 32)
            if num == 0:
                return ip
            ipv4_bits = IpBits.v4()
            if ipv4_bits.bits < ip.prefix.host_prefix():
                return None
            from .ipv4 import Ipv4

            mapped = Ipv4.from_number(num, ipv4_bits.bits - ip.prefix.host_prefix())
            if mapped is None:
                return mapped
            ip.mapped = mapped
        return ip

    @staticmethod
    def from_int(adr: int, prefix_num: int) -> Optional[IPAddress]:
        prefix = Prefix128.create(prefix_num)
        if prefix is None:
            return None
        return Ipv6.enhance_if_mapped(
            IPAddress(
                IpBits.v6(),
                adr,
                prefix,
                None,
                Ipv6.ipv6_is_private,
                Ipv6.ipv6_is_loopback,
                Ipv6.to_ipv6,
            )
        )

    # Creates a new IPv6 address object.
    #
    # An IPv6 address can be expressed in any of the following forms:
    #
    # * "2001:0db8:0000:0000:0008:0800:200C:417A": IPv6 address with no compression
    # * "2001:db8:0:0:8:800:200C:417A": IPv6 address with leading zeros compression
    # * "2001:db8::8:800:200C:417A": IPv6 address with full compression
    #
    # In all these 3 cases, a new IPv6 address object will be created, using the default
    # subnet mask /128
    #
    # You can also specify the subnet mask as with IPv4 addresses:
    #
    #   ip6 = IPAddress "2001:db8::8:800:200c:417a/64"
    #
    @staticmethod
    def create(s: str) -> Optional[IPAddress]:
        ip, o_netmask = IPAddress.split_at_slash(s)
        if IPAddress.is_valid_ipv6(ip):
            o_num = IPAddress.split_to_num(ip)
            if o_num is None:
                return None
            netmask = 128
            if o_netmask is not None:
                netmask = IPAddress.parse_dec_str(o_netmask)
                if netmask is None:
                    return None
            prefix = Prefix128.create(netmask)
            if prefix is None:
                return None
            return Ipv6.enhance_if_mapped(
                IPAddress(
                    IpBits.v6(),
                    o_num.value,
                    prefix,
                    None,
                    Ipv6.ipv6_is_private,
                    Ipv6.ipv6_is_loopback,
                    Ipv6.to_ipv6,
                )
            )
        return None

    @staticmethod
    def to_ipv6(ia: IPAddress) -> IPAddress:
        return ia.clone()

    @staticmethod
    def ipv6_is_loopback(my: IPAddress) -> bool:
        return my.host_address == 1

    @staticmethod
    def ipv6_is_private(my: IPAddress) -> bool:
        return IPAddress.parse("fd00::/8").includes(my)


__all__ = ["Ipv6"]
