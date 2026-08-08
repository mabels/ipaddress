from typing import Optional

from .ip_bits import IpBits
from .prefix import Prefix


class Prefix32:
    @staticmethod
    def from_(my: Prefix, num: int) -> Optional[Prefix]:
        return Prefix32.create(num)

    @staticmethod
    def create(num: int) -> Optional[Prefix]:
        if 0 <= num <= 32:
            ip_bits = IpBits.v4()
            bits = ip_bits.bits
            return Prefix(num, ip_bits, Prefix.new_netmask(num, bits), Prefix32.from_)
        return None


__all__ = ["Prefix32"]
