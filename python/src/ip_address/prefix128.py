from typing import Optional

from .ip_bits import IpBits
from .prefix import Prefix


class Prefix128:
    # Creates a new prefix object for 128 bits IPv6 addresses
    #
    #   prefix = IPAddressPrefix128.new 64
    #     // => 64
    #
    @staticmethod
    def create(num: int) -> Optional[Prefix]:
        if num <= 128:
            ip_bits = IpBits.v6()
            bits = ip_bits.bits
            return Prefix(num, ip_bits, Prefix.new_netmask(num, bits), Prefix128.from_)
        return None

    @staticmethod
    def from_(my: Prefix, num: int) -> Optional[Prefix]:
        return Prefix128.create(num)


__all__ = ["Prefix128"]
