from enum import IntEnum


class IpVersion(IntEnum):
    V4 = 4
    V6 = 6


__all__ = ["IpVersion"]
