from typing import Callable, List, Optional

from .ip_version import IpVersion
from .rle import Rle

ToString = Callable[["IpBits", int], str]


class IpBits:
    _v4: Optional["IpBits"] = None
    _v6: Optional["IpBits"] = None

    def __init__(self) -> None:
        self.version: IpVersion
        self.vt_as_compressed_string: ToString
        self.vt_as_uncompressed_string: ToString
        self.bits: int = 0
        self.part_bits: int = 0
        self.dns_bits: int = 0
        self.rev_domain: str = ""
        self.part_mod: int = 0
        self.host_ofs: int = 0  # ipv4=1, ipv6=0

    def clone(self) -> "IpBits":
        return self

    def parts(self, bu: int) -> List[int]:
        vec: List[int] = []
        my = bu
        part_mod = 1 << self.part_bits
        for _ in range(self.bits // self.part_bits):
            vec.append(my % part_mod)
            my = my >> self.part_bits
        vec.reverse()
        return vec

    def as_compressed_string(self, bu: int) -> str:
        return self.vt_as_compressed_string(self, bu)

    def as_uncompressed_string(self, bu: int) -> str:
        return self.vt_as_uncompressed_string(self, bu)

    def dns_part_format(self, i: int) -> str:
        if self.version == IpVersion.V4:
            return f"{i}"
        return format(i, "x")

    @staticmethod
    def v4() -> "IpBits":
        if IpBits._v4:
            return IpBits._v4
        my = IpBits()
        IpBits._v4 = my
        my.version = IpVersion.V4
        my.vt_as_compressed_string = IpBits.ipv4_as_compressed
        my.vt_as_uncompressed_string = IpBits.ipv4_as_compressed
        my.bits = 32
        my.part_bits = 8
        my.dns_bits = 8
        my.rev_domain = "in-addr.arpa"
        my.part_mod = 1 << 8
        my.host_ofs = 1
        return my

    @staticmethod
    def v6() -> "IpBits":
        if IpBits._v6:
            return IpBits._v6
        my = IpBits()
        IpBits._v6 = my
        my.version = IpVersion.V6
        my.vt_as_compressed_string = IpBits.ipv6_as_compressed
        my.vt_as_uncompressed_string = IpBits.ipv6_as_uncompressed
        my.bits = 128
        my.part_bits = 16
        my.dns_bits = 4
        my.rev_domain = "ip6.arpa"
        my.part_mod = 1 << 16
        my.host_ofs = 0
        return my

    @staticmethod
    def ipv4_as_compressed(ip_bits: "IpBits", host_address: int) -> str:
        ret = ""
        sep = ""
        for part in ip_bits.parts(host_address):
            ret += sep
            ret += f"{part}"
            sep = "."
        return ret

    @staticmethod
    def ipv6_as_compressed(ip_bits: "IpBits", host_address: int) -> str:
        ret = ""
        colon = ""
        done = False
        for rle in Rle.code(ip_bits.parts(host_address)):
            for _ in range(rle.cnt):
                if done or not (rle.part == 0 and rle.max):
                    ret += f"{colon}{format(rle.part, 'x')}"
                    colon = ":"
                elif rle.part == 0 and rle.max:
                    ret += "::"
                    colon = ""
                    done = True
                    break
        return ret

    @staticmethod
    def ipv6_as_uncompressed(ip_bits: "IpBits", host_address: int) -> str:
        ret = ""
        sep = ""
        for part in ip_bits.parts(host_address):
            ret += sep
            ret += format(0x10000 + part, "x")[1:]
            sep = ":"
        return ret


__all__ = ["IpBits", "ToString"]
