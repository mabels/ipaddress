from typing import Optional

from .ipaddress import IPAddress
from .ipv6 import Ipv6

# The loopback  address is a unicast localhost address. If an
# application in a host sends packets to this address, the IPv6 stack
# will loop these packets back on the same virtual interface.
#
# Loopback addresses are expressed in the following form:
#
#   ::1
#
# or, with their appropriate prefix,
#
#   ::1/128
#
# Checking if an address is loopback is easy with the IPv6// loopback?
# method:
#
#   ip.loopback?
#     // => true
#
# The IPv6 loopback address corresponds to 127.0.0.1 in IPv4.


class Ipv6Loopback:
    # Creates a new IPv6 loopback address
    #
    #   ip = IPAddress::IPv6::Loopback.new
    #
    #   ip.to_string
    #     // => "::1/128"
    #
    @staticmethod
    def create() -> Optional[IPAddress]:
        return Ipv6.from_int(1, 128)


__all__ = ["Ipv6Loopback"]
