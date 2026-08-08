from typing import Callable

from .ip_bits import IpBits

From = Callable[["Prefix", int], "Prefix"]


class Prefix:
    def __init__(self, num: int, ip_bits: IpBits, net_mask: int, vt_from: From):
        self.num = num
        self.ip_bits = ip_bits
        self.net_mask = net_mask
        self.vt_from = vt_from

    def clone(self) -> "Prefix":
        return Prefix(self.num, self.ip_bits, self.net_mask, self.vt_from)

    def eq(self, other: "Prefix") -> bool:
        return self.ip_bits.version == other.ip_bits.version and self.num == other.num

    def ne(self, other: "Prefix") -> bool:
        return not self.eq(other)

    def cmp(self, oth: "Prefix") -> int:
        if self.ip_bits.version < oth.ip_bits.version:
            return -1
        if self.ip_bits.version > oth.ip_bits.version:
            return 1
        if self.num < oth.num:
            return -1
        if self.num > oth.num:
            return 1
        return 0

    def from_(self, num: int) -> "Prefix":
        return self.vt_from(self, num)

    def to_ip_str(self) -> str:
        return self.ip_bits.vt_as_compressed_string(self.ip_bits, self.net_mask)

    def size(self) -> int:
        return 1 << (self.ip_bits.bits - self.num)

    @staticmethod
    def new_netmask(prefix: int, bits: int) -> int:
        mask = 0
        host_prefix = bits - prefix
        for i in range(prefix):
            mask += 1 << (host_prefix + i)
        return mask

    def netmask(self) -> int:
        return self.net_mask

    def get_prefix(self) -> int:
        return self.num

    # The hostmask is the contrary of the subnet mask,
    # as it shows the bits that can change within the
    # hosts
    #
    #   prefix = IPAddress::Prefix32.new 24
    #
    #   prefix.hostmask
    #     // => "0.0.0.255"
    #
    def host_mask(self) -> int:
        ret = 0
        for _ in range(self.ip_bits.bits - self.num):
            ret = (ret << 1) + 1
        return ret

    # Returns the length of the host portion
    # of a netmask.
    #
    #   prefix = Prefix128.new 96
    #
    #   prefix.host_prefix
    #     // => 128
    #
    def host_prefix(self) -> int:
        return self.ip_bits.bits - self.num

    # Transforms the prefix into a string of bits
    # representing the netmask
    #
    #   prefix = IPAddress::Prefix128.new 64
    #
    #   prefix.bits
    #     // => "1111111111111111111111111111111111111111111111111111111111111111"
    #         "0000000000000000000000000000000000000000000000000000000000000000"
    #
    def bits(self) -> str:
        return format(self.netmask(), "b")

    def to_s(self) -> str:
        return str(self.get_prefix())

    def to_i(self) -> int:
        return self.get_prefix()

    def add_prefix(self, other: "Prefix") -> "Prefix":
        return self.from_(self.get_prefix() + other.get_prefix())

    def add(self, other: int) -> "Prefix":
        return self.from_(self.get_prefix() + other)

    def sub_prefix(self, other: "Prefix") -> "Prefix":
        return self.sub(other.get_prefix())

    def sub(self, other: int) -> "Prefix":
        if other > self.get_prefix():
            return self.from_(other - self.get_prefix())
        return self.from_(self.get_prefix() - other)


__all__ = ["Prefix", "From"]
