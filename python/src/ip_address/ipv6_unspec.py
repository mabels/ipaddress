from typing import Optional

from .ipaddress import IPAddress

# The address with all zero bits is called the +unspecified+ address
# (corresponding to 0.0.0.0 in IPv4). It should be something like this:
#
#   0000:0000:0000:0000:0000:0000:0000:0000
#
# but, with the use of compression, it is usually written as just two
# colons:
#
#   ::
#
# or, specifying the netmask:
#
#   ::/128
#
# You can easily check if an IPv6 object is an unspecified address by
# using the IPv6// unspecified? method
#
#   ip.unspecified?
#     // => true
#
# This address must never be assigned to an interface and is to be used
# only in software before the application has learned its host's source
# address appropriate for a pending connection. Routers must not forward
# packets with the unspecified address.


class Ipv6Unspec:
    # Creates a new IPv6 unspecified address
    #
    #   ip = IPAddress::IPv6::Unspecified.new
    #
    #   ip.to_s
    #      // => => "::/128"
    #
    @staticmethod
    def create() -> Optional[IPAddress]:
        return IPAddress.parse("::")


__all__ = ["Ipv6Unspec"]
