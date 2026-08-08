from typing import Optional

from .ip_bits import IpBits
from .ipaddress import IPAddress

# It is usually identified as a IPv4 mapped IPv6 address, a particular
# IPv6 address which aids the transition from IPv4 to IPv6. The
# structure of the address is
#
#   ::ffff:w.y.x.z
#
# where w.x.y.z is a normal IPv4 address. For example, the following is
# a mapped IPv6 address:
#
#   ::ffff:192.168.100.1
#
# A mapped IPv6 can also be created just by specify the address in the
# following format:
#
#   ip6 = IPAddress "::172.16.10.1"
#
# That is, two colons and the IPv4 address. However, as by RFC, the ffff
# group will be automatically added at the beginning
#
#   ip6.to_string
#     => "::ffff:172.16.10.1/128"


class Ipv6Mapped:
    # Creates a new IPv6 IPv4-mapped address
    #
    #   ip6 = IPAddress::IPv6::Mapped.new "::ffff:172.16.10.1/128"
    #
    #   ipv6.ipv4.class
    #     // => IPAddress::IPv4
    #
    @staticmethod
    def create(s: str) -> Optional[IPAddress]:
        ip, o_netmask = IPAddress.split_at_slash(s)
        split_colon = ip.split(":")
        if len(split_colon) <= 1:
            return None
        netmask = ""
        if o_netmask is not None:
            netmask = f"/{o_netmask}"
        ipv4_str = split_colon[-1]
        if not IPAddress.is_valid_ipv4(ipv4_str):
            return None

        ipv4 = IPAddress.parse(f"{ipv4_str}{netmask}")
        if ipv4 is None:
            return None
        addr = ipv4
        ipv6_bits = IpBits.v6()
        part_mod = ipv6_bits.part_mod
        up_addr = addr.host_address
        down_addr = addr.host_address

        rebuild_ipv6 = ""
        colon = ""
        for i in range(len(split_colon) - 1):
            rebuild_ipv6 += colon
            rebuild_ipv6 += split_colon[i]
            colon = ":"
        rebuild_ipv6 += colon
        high_part = format((up_addr >> ipv6_bits.part_bits) % part_mod, "x")
        low_part = format(down_addr % part_mod, "x")
        bits = ipv6_bits.bits - addr.prefix.host_prefix()
        rebuild_ipv4 = f"{high_part}:{low_part}/{bits}"
        rebuild_ipv6 += rebuild_ipv4

        r_ipv6 = IPAddress.parse(rebuild_ipv6)
        if r_ipv6 is None:
            return None
        if r_ipv6.is_mapped():
            return r_ipv6
        ipv6 = r_ipv6
        p96bit = ipv6.host_address >> 32
        if p96bit != 0:
            return None
        r_ipv6 = IPAddress.parse(f"::ffff:{rebuild_ipv4}")
        if r_ipv6 is None:
            return None
        return r_ipv6


__all__ = ["Ipv6Mapped"]
