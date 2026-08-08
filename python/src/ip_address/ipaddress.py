import math
import re
from functools import cmp_to_key
from typing import Callable, List, Optional

from .ip_bits import IpBits
from .ip_version import IpVersion
from .prefix import Prefix

Is = Callable[["IPAddress"], bool]
ToIpv6 = Callable[["IPAddress"], Optional["IPAddress"]]
EachFn = Callable[["IPAddress"], None]


class ResultIntParts:
    def __init__(self, value: int, parts: int):
        self.value = value
        self.parts = parts


class IPAddress:
    def __init__(
        self,
        ip_bits: IpBits,
        host_address: int,
        prefix: Prefix,
        mapped: Optional["IPAddress"] = None,
        vt_is_private: Optional[Is] = None,
        vt_is_loopback: Optional[Is] = None,
        vt_to_ipv6: Optional[ToIpv6] = None,
    ):
        self.ip_bits = ip_bits
        self.host_address = host_address
        self.prefix = prefix
        self.mapped = mapped
        self.vt_is_private = vt_is_private
        self.vt_is_loopback = vt_is_loopback
        self.vt_to_ipv6 = vt_to_ipv6

    def clone(self) -> "IPAddress":
        mapped = self.mapped.clone() if self.mapped else None
        return IPAddress(
            self.ip_bits.clone(),
            self.host_address,
            self.prefix.clone(),
            mapped,
            self.vt_is_private,
            self.vt_is_loopback,
            self.vt_to_ipv6,
        )

    def lt(self, oth: "IPAddress") -> bool:
        return self.cmp(oth) < 0

    def lte(self, oth: "IPAddress") -> bool:
        return self.cmp(oth) <= 0

    def gt(self, oth: "IPAddress") -> bool:
        return self.cmp(oth) > 0

    def gte(self, oth: "IPAddress") -> bool:
        return self.cmp(oth) >= 0

    def cmp(self, oth: "IPAddress") -> int:
        if self.ip_bits.version != oth.ip_bits.version:
            if self.ip_bits.version == IpVersion.V6:
                return 1
            return -1
        if self.host_address != oth.host_address:
            return -1 if self.host_address < oth.host_address else 1
        return self.prefix.cmp(oth.prefix)

    def eq(self, other: "IPAddress") -> bool:
        return (
            self.ip_bits.version == other.ip_bits.version
            and self.prefix.eq(other.prefix)
            and self.host_address == other.host_address
        )

    def ne(self, other: "IPAddress") -> bool:
        return not self.eq(other)

    # Parse the argument string to create a new
    # IPv4, IPv6 or Mapped IP object
    #
    #   ip  = IPAddress.parse "172.16.10.1/24"
    #   ip6 = IPAddress.parse "2001:db8.8:800:200c:417a/64"
    #   ip_mapped = IPAddress.parse ".ffff:172.16.10.1/128"
    #
    # All the object created will be instances of the
    # correct class:
    #
    #  ip.class
    #    //=> IPAddress.IPv4
    #  ip6.class
    #    //=> IPAddress.IPv6
    #  ip_mapped.class
    #    //=> IPAddress.IPv6.Mapped
    #
    @staticmethod
    def parse(s: str) -> Optional["IPAddress"]:
        from .ipv4 import Ipv4
        from .ipv6 import Ipv6
        from .ipv6_mapped import Ipv6Mapped

        if re.search(r":.+\.", s):
            return Ipv6Mapped.create(s)
        if "." in s:
            return Ipv4.create(s)
        if ":" in s:
            return Ipv6.create(s)
        return None

    @staticmethod
    def split_at_slash(s: str) -> "tuple[str, Optional[str]]":
        slash = s.strip().split("/")
        addr = ""
        if slash[0]:
            addr += slash[0].strip()
        if len(slash) > 1 and slash[1]:
            return addr, slash[1].strip()
        return addr, None

    def from_(self, addr: int, prefix: Prefix) -> "IPAddress":
        mapped = self.mapped.clone() if self.mapped else None
        return IPAddress(
            self.ip_bits,
            addr,
            prefix.clone(),
            mapped,
            self.vt_is_private,
            self.vt_is_loopback,
            self.vt_to_ipv6,
        )

    # True if the object is an IPv4 address
    #
    #   ip = IPAddress("192.168.10.100/24")
    #
    #   ip.ipv4?
    #     //-> true
    #
    def is_ipv4(self) -> bool:
        return self.ip_bits.version == IpVersion.V4

    # True if the object is an IPv6 address
    #
    #   ip = IPAddress("192.168.10.100/24")
    #
    #   ip.ipv6?
    #     //-> false
    #
    def is_ipv6(self) -> bool:
        return self.ip_bits.version == IpVersion.V6

    # Checks if the given string is a valid IP address,
    # either IPv4 or IPv6
    #
    # Example:
    #
    #   IPAddress.valid? "2002.1"
    #     //=> true
    #
    #   IPAddress.valid? "10.0.0.256"
    #     //=> false
    #
    @staticmethod
    def is_valid(addr: str) -> bool:
        return IPAddress.is_valid_ipv4(addr) or IPAddress.is_valid_ipv6(addr)

    @staticmethod
    def parse_dec_str(s: str) -> Optional[int]:
        if not re.fullmatch(r"\d+", s):
            return None
        return int(s, 10)

    @staticmethod
    def parse_hex_str(s: str) -> Optional[int]:
        if not re.fullmatch(r"[0-9a-fA-F]+", s):
            return None
        return int(s, 16)

    # Checks if the given string is a valid IPv4 address
    #
    # Example:
    #
    #   IPAddress.valid_ipv4? "2002.1"
    #     //=> false
    #
    #   IPAddress.valid_ipv4? "172.16.10.1"
    #     //=> true
    #
    @staticmethod
    def parse_ipv4_part(i: str) -> Optional[int]:
        part = IPAddress.parse_dec_str(i)
        if part is None or part >= 256:
            return None
        return part

    @staticmethod
    def split_to_u32(addr: str) -> Optional[int]:
        ip = 0
        shift = 24
        split_addr = addr.split(".")
        if len(split_addr) > 4:
            return None
        split_addr_len = len(split_addr)
        if 1 <= split_addr_len < 4:
            part = IPAddress.parse_ipv4_part(split_addr[split_addr_len - 1])
            if part is None:
                return None
            ip = part
            split_addr = split_addr[: split_addr_len - 1]
        for i in split_addr:
            part = IPAddress.parse_ipv4_part(i)
            if part is None:
                return None
            ip = ip + (part << shift)
            shift -= 8
        return ip

    @staticmethod
    def is_valid_ipv4(addr: str) -> bool:
        return IPAddress.split_to_u32(addr) is not None

    # Checks if the given string is a valid IPv6 address
    #
    # Example:
    #
    #   IPAddress.valid_ipv6? "2002.1"
    #     //=> true
    #
    #   IPAddress.valid_ipv6? "2002.DEAD.BEEF"
    #     //=> false
    #
    @staticmethod
    def split_on_colon(addr: str) -> Optional[ResultIntParts]:
        parts = addr.strip().split(":")
        ip = 0
        if len(parts) == 1 and len(parts[0]) == 0:
            return ResultIntParts(ip, 0)
        parts_len = len(parts)
        shift = (parts_len - 1) * 16
        for i in parts:
            part = IPAddress.parse_hex_str(i)
            if part is None or part >= 65536:
                return None
            ip = ip + (part << shift)
            shift -= 16
        return ResultIntParts(ip, parts_len)

    @staticmethod
    def split_to_num(addr: str) -> Optional[ResultIntParts]:
        pre_post = addr.strip().split("::")
        if len(pre_post) > 2:
            return None
        if len(pre_post) == 2:
            pre = IPAddress.split_on_colon(pre_post[0])
            if pre is None:
                return None
            post = IPAddress.split_on_colon(pre_post[1])
            if post is None:
                return None
            return ResultIntParts(
                (pre.value << (128 - pre.parts * 16)) + post.value, 128 // 16
            )
        ret = IPAddress.split_on_colon(addr)
        if ret is None or ret.parts != 128 // 16:
            return None
        return ret

    @staticmethod
    def is_valid_ipv6(addr: str) -> bool:
        return IPAddress.split_to_num(addr) is not None

    # private helper for summarize
    # assumes that networks is output from reduce_networks
    # means it should be sorted lowers first and uniq
    #
    @staticmethod
    def pos_to_idx(pos: int, length: int) -> int:
        return ((pos % length) + length) % length

    @staticmethod
    def aggregate(networks: List["IPAddress"]) -> List["IPAddress"]:
        if len(networks) == 0:
            return []
        if len(networks) == 1:
            return [networks[0].network()]
        stack = sorted(
            (i.network() for i in networks), key=cmp_to_key(lambda a, b: a.cmp(b))
        )
        pos = 0
        while True:
            if pos < 0:
                pos = 0
            stack_len = len(stack)
            if pos >= stack_len:
                break
            first = IPAddress.pos_to_idx(pos, stack_len)
            pos = pos + 1
            if pos >= stack_len:
                break
            second = IPAddress.pos_to_idx(pos, stack_len)
            pos = pos + 1
            if stack[first].includes(stack[second]):
                pos = pos - 2
                pidx = IPAddress.pos_to_idx(pos + 1, stack_len)
                stack = stack[:pidx] + stack[pidx + 1 :]
            else:
                stack[first].prefix = stack[first].prefix.sub(1)
                if stack[first].prefix.num + 1 == stack[second].prefix.num and stack[
                    first
                ].includes(stack[second]):
                    pos = pos - 2
                    idx = IPAddress.pos_to_idx(pos, stack_len)
                    stack[idx] = stack[first].clone()
                    pidx = IPAddress.pos_to_idx(pos + 1, stack_len)
                    stack = stack[:pidx] + stack[pidx + 1 :]
                    pos = pos - 1
                else:
                    stack[first].prefix = stack[first].prefix.add(1)
                    pos = pos - 1
        return stack[:]

    def parts(self) -> List[int]:
        return self.ip_bits.parts(self.host_address)

    def parts_hex_str(self) -> List[str]:
        ret = []
        leading = 1 << self.ip_bits.part_bits
        for i in self.parts():
            ret.append(format(leading + i, "x")[1:])
        return ret

    # Returns the IP address in in-addr.arpa format
    # for DNS Domain definition entries like SOA Records
    #
    #   ip = IPAddress("172.17.100.50/15")
    #
    #   ip.dns_rev_domains
    #     // => ["16.172.in-addr.arpa","17.172.in-addr.arpa"]
    #
    def dns_rev_domains(self) -> List[str]:
        return [net.dns_reverse() for net in self.dns_networks()]

    def dns_reverse(self) -> str:
        ret = ""
        dot = ""
        dns_parts = self.dns_parts()
        i = (
            self.prefix.host_prefix() + (self.ip_bits.dns_bits - 1)
        ) // self.ip_bits.dns_bits
        while i < len(dns_parts):
            ret += dot
            ret += self.ip_bits.dns_part_format(dns_parts[i])
            dot = "."
            i += 1
        ret += dot
        ret += self.ip_bits.rev_domain
        return ret

    def dns_parts(self) -> List[int]:
        ret = []
        num = self.host_address
        mask = 1 << self.ip_bits.dns_bits
        for _ in range(self.ip_bits.bits // self.ip_bits.dns_bits):
            part = num % mask
            num = num >> self.ip_bits.dns_bits
            ret.append(part)
        return ret

    def dns_networks(self) -> List["IPAddress"]:
        next_bit_mask = (
            self.ip_bits.bits
            - (self.prefix.host_prefix() // self.ip_bits.dns_bits)
            * self.ip_bits.dns_bits
        )
        if next_bit_mask <= 0:
            return [self.network()]
        step_bit_net = 1 << (self.ip_bits.bits - next_bit_mask)
        if step_bit_net == 0:
            return [self.network()]
        ret = []
        step = self.network().host_address
        prefix = self.prefix.from_(next_bit_mask)
        last = self.broadcast().host_address
        while step <= last:
            ret.append(self.from_(step, prefix))
            step = step + step_bit_net
        return ret

    # Summarization (or aggregation) is the process when two or more
    # networks are taken together to check if a supernet, including all
    # and only these networks, exists. If it exists then this supernet
    # is called the summarized (or aggregated) network.
    #
    # It is very important to understand that summarization can only
    # occur if there are no holes in the aggregated network, or, in other
    # words, if the given networks fill completely the address space
    # of the supernet. So the two rules are:
    #
    # 1) The aggregate network must contain +all+ the IP addresses of the
    #    original networks;
    # 2) The aggregate network must contain +only+ the IP addresses of the
    #    original networks;
    #
    @staticmethod
    def summarize(networks: List["IPAddress"]) -> List["IPAddress"]:
        return IPAddress.aggregate(networks)

    @staticmethod
    def summarize_str(netstr: List[str]) -> List["IPAddress"]:
        vec = IPAddress.to_ipaddress_vec(netstr)
        if not vec:
            return vec
        return IPAddress.aggregate(vec)

    def ip_same_kind(self, oth: "IPAddress") -> bool:
        return self.ip_bits.version == oth.ip_bits.version

    # Returns true if the address is an unspecified address
    #
    # See IPAddress.IPv6.Unspecified for more information
    #
    def is_unspecified(self) -> bool:
        return self.host_address == 0

    # Returns true if the address is a loopback address
    #
    # See IPAddress.IPv6.Loopback for more information
    #
    def is_loopback(self) -> bool:
        return self.vt_is_loopback(self)

    # Returns true if the address is a mapped address
    #
    # See IPAddress.IPv6.Mapped for more information
    #
    def is_mapped(self) -> bool:
        return self.mapped is not None and (self.host_address >> 32) == ((1 << 16) - 1)

    # Checks if the argument is a valid IPv4 netmask
    # expressed in dotted decimal format.
    #
    #   IPAddress.valid_ipv4_netmask? "255.255.0.0"
    #     //=> true
    #
    @staticmethod
    def is_valid_netmask(addr: str) -> bool:
        return IPAddress.parse_netmask_to_prefix(addr) is not None

    @staticmethod
    def netmask_to_prefix(nm: int, bits: int) -> Optional[int]:
        prefix = 0
        addr = nm
        in_host_part = True
        for _ in range(bits):
            bit = addr % 2
            if in_host_part and bit == 0:
                prefix = prefix + 1
            elif in_host_part and bit == 1:
                in_host_part = False
            elif not in_host_part and bit == 0:
                return None
            addr = addr >> 1
        return bits - prefix

    @staticmethod
    def parse_netmask_to_prefix(netmask: str) -> Optional[int]:
        is_number = IPAddress.parse_dec_str(netmask)
        if is_number is not None:
            return is_number
        my = IPAddress.parse(netmask)
        if my is None:
            return None
        return IPAddress.netmask_to_prefix(my.host_address, my.ip_bits.bits)

    # Set a new prefix number for the object
    #
    # This is useful if you want to change the prefix
    # to an object created with IPv4.parse_u32 or
    # if the object was created using the classful
    # mask.
    #
    #   ip = IPAddress("172.16.100.4")
    #
    #   puts ip
    #     // => 172.16.100.4/16
    #
    #   ip.prefix = 22
    #
    #   puts ip
    #     // => 172.16.100.4/22
    #
    def change_prefix(self, num: int) -> Optional["IPAddress"]:
        prefix = self.prefix.from_(num)
        if not prefix:
            return None
        return self.from_(self.host_address, prefix)

    def change_netmask(self, s: str) -> Optional["IPAddress"]:
        nm = IPAddress.parse_netmask_to_prefix(s)
        if not nm:
            return None
        return self.change_prefix(nm)

    # Returns a string with the IP address in canonical
    # form.
    #
    #   ip = IPAddress("172.16.100.4/22")
    #
    #   ip.to_string
    #     // => "172.16.100.4/22"
    #
    def to_string(self) -> str:
        return f"{self.to_s()}/{self.prefix.to_s()}"

    def to_s(self) -> str:
        return self.ip_bits.as_compressed_string(self.host_address)

    def to_string_uncompressed(self) -> str:
        return f"{self.to_s_uncompressed()}/{self.prefix.to_s()}"

    def to_s_uncompressed(self) -> str:
        return self.ip_bits.as_uncompressed_string(self.host_address)

    def to_s_mapped(self) -> str:
        if self.is_mapped():
            return f"::ffff:{self.mapped.to_s()}"
        return self.to_s()

    def to_string_mapped(self) -> str:
        if self.is_mapped():
            mapped = self.mapped.clone()
            return f"{self.to_s_mapped()}/{mapped.prefix.num}"
        return self.to_string()

    # Returns the address portion of an IP in binary format,
    # as a string containing a sequence of 0 and 1
    #
    #   ip = IPAddress("127.0.0.1")
    #
    #   ip.bits
    #     // => "01111111000000000000000000000001"
    #
    def bits(self) -> str:
        return format(self.host_address, "b").rjust(self.ip_bits.bits, "0")

    def to_hex(self) -> str:
        return format(self.host_address, "x")

    def netmask(self) -> "IPAddress":
        return self.from_(self.prefix.netmask(), self.prefix)

    # Returns the broadcast address for the given IP.
    #
    #   ip = IPAddress("172.16.10.64/24")
    #
    #   ip.broadcast.to_s
    #     // => "172.16.10.255"
    #
    def broadcast(self) -> "IPAddress":
        return self.from_(self.network().host_address + (self.size() - 1), self.prefix)

    # Checks if the IP address is actually a network
    #
    #   ip = IPAddress("172.16.10.64/24")
    #
    #   ip.network?
    #     // => false
    #
    #   ip = IPAddress("172.16.10.64/26")
    #
    #   ip.network?
    #     // => true
    #
    def is_network(self) -> bool:
        return (
            self.prefix.num != self.ip_bits.bits
            and self.host_address == self.network().host_address
        )

    # Returns a new IPv4 object with the network number
    # for the given IP.
    #
    #   ip = IPAddress("172.16.10.64/24")
    #
    #   ip.network.to_s
    #     // => "172.16.10.0"
    #
    def network(self) -> "IPAddress":
        return self.from_(
            IPAddress.to_network(self.host_address, self.prefix.host_prefix()),
            self.prefix,
        )

    @staticmethod
    def to_network(adr: int, host_prefix: int) -> int:
        return (adr >> host_prefix) << host_prefix

    def sub(self, other: "IPAddress") -> int:
        if self.host_address > other.host_address:
            return self.host_address - other.host_address
        return other.host_address - self.host_address

    def add(self, other: "IPAddress") -> List["IPAddress"]:
        return IPAddress.aggregate([self.clone(), other.clone()])

    @staticmethod
    def to_s_vec(vec: List["IPAddress"]) -> List[str]:
        return [i.to_s() for i in vec]

    @staticmethod
    def to_string_vec(vec: List["IPAddress"]) -> List[str]:
        return [i.to_string() for i in vec]

    @staticmethod
    def to_ipaddress_vec(vec: List[str]) -> List["IPAddress"]:
        ret = []
        for ipstr in vec:
            ipa = IPAddress.parse(ipstr)
            if not ipa:
                return []
            ret.append(ipa)
        return ret

    # Returns a new IPv4 object with the
    # first host IP address in the range.
    #
    # Example: given the 192.168.100.0/24 network, the first
    # host IP address is 192.168.100.1.
    #
    #   ip = IPAddress("192.168.100.0/24")
    #
    #   ip.first.to_s
    #     // => "192.168.100.1"
    #
    def first(self) -> "IPAddress":
        return self.from_(
            self.network().host_address + self.ip_bits.host_ofs, self.prefix
        )

    # Like its sibling method IPv4// first, this method
    # returns a new IPv4 object with the
    # last host IP address in the range.
    #
    # Example: given the 192.168.100.0/24 network, the last
    # host IP address is 192.168.100.254
    #
    #   ip = IPAddress("192.168.100.0/24")
    #
    #   ip.last.to_s
    #     // => "192.168.100.254"
    #
    def last(self) -> "IPAddress":
        return self.from_(
            self.broadcast().host_address - self.ip_bits.host_ofs, self.prefix
        )

    # Iterates over all the hosts IP addresses for the given
    # network (or IP address).
    #
    #   ip = IPAddress("10.0.0.1/29")
    #
    #   ip.each_host do |i|
    #     p i.to_s
    #   end
    #
    def each_host(self, func: EachFn) -> None:
        i = self.first().host_address
        last = self.last().host_address
        while i <= last:
            func(self.from_(i, self.prefix))
            i = i + 1

    def inc(self) -> Optional["IPAddress"]:
        ret = self.clone()
        ret.host_address = ret.host_address + 1
        if ret.lte(self.last()):
            return ret
        return None

    def dec(self) -> Optional["IPAddress"]:
        ret = self.clone()
        ret.host_address = ret.host_address - 1
        if ret.gte(self.first()):
            return ret
        return None

    # Iterates over all the IP addresses for the given
    # network (or IP address).
    #
    # The object yielded is a new IPv4 object created
    # from the iteration.
    #
    #   ip = IPAddress("10.0.0.1/29")
    #
    #   ip.each do |i|
    #     p i.address
    #   end
    #
    def each(self, func: EachFn) -> None:
        i = self.network().host_address
        last = self.broadcast().host_address
        while i <= last:
            func(self.from_(i, self.prefix))
            i = i + 1

    # Returns the number of IP addresses included
    # in the network. It also counts the network
    # address and the broadcast address.
    #
    #   ip = IPAddress("10.0.0.1/29")
    #
    #   ip.size
    #     // => 8
    #
    def size(self) -> int:
        return 1 << self.prefix.host_prefix()

    def is_same_kind(self, oth: "IPAddress") -> bool:
        return self.is_ipv4() == oth.is_ipv4() and self.is_ipv6() == oth.is_ipv6()

    # Checks whether a subnet includes the given IP address.
    #
    # Accepts an IPAddress.IPv4 object.
    #
    #   ip = IPAddress("192.168.10.100/24")
    #
    #   addr = IPAddress("192.168.10.102/24")
    #
    #   ip.include? addr
    #     // => true
    #
    #   ip.include? IPAddress("172.16.0.48/16")
    #     // => false
    #
    def includes(self, oth: "IPAddress") -> bool:
        return (
            self.is_same_kind(oth)
            and self.prefix.num <= oth.prefix.num
            and self.network().host_address
            == IPAddress.to_network(oth.host_address, self.prefix.host_prefix())
        )

    # Checks whether a subnet includes all the
    # given IPv4 objects.
    #
    #   ip = IPAddress("192.168.10.100/24")
    #
    #   addr1 = IPAddress("192.168.10.102/24")
    #   addr2 = IPAddress("192.168.10.103/24")
    #
    #   ip.include_all?(addr1,addr2)
    #     // => true
    #
    def includes_all(self, oths: List["IPAddress"]) -> bool:
        return all(self.includes(oth) for oth in oths)

    # Checks if an IPv4 address objects belongs
    # to a private network RFC1918
    #
    # Example:
    #
    #   ip = IPAddress "10.1.1.1/24"
    #   ip.private?
    #     // => true
    #
    def is_private(self) -> bool:
        return self.vt_is_private(self)

    # Splits a network into different subnets
    #
    # If the IP Address is a network, it can be divided into
    # multiple networks. If +self+ is not a network, this
    # method will calculate the network from the IP and then
    # subnet it.
    #
    # If +subnets+ is an power of two number, the resulting
    # networks will be divided evenly from the supernet.
    #
    #   network = IPAddress("172.16.10.0/24")
    #
    #   network / 4   //  implies map{|i| i.to_string}
    #     // => ["172.16.10.0/26",
    #          "172.16.10.64/26",
    #          "172.16.10.128/26",
    #          "172.16.10.192/26"]
    #
    # Returns an array of IPv4 objects
    #
    def sum_first_found(self, arr: List["IPAddress"]) -> List["IPAddress"]:
        dup = arr[:]
        if len(dup) < 2:
            return dup
        for i in range(len(dup) - 2, -1, -1):
            a = IPAddress.summarize([dup[i], dup[i + 1]])
            if len(a) == 1:
                dup[i] = a[0]
                dup = dup[: i + 1] + dup[i + 2 :]
                break
        return dup

    def split(self, subnets: int) -> Optional[List["IPAddress"]]:
        if subnets == 0 or (1 << self.prefix.host_prefix()) <= subnets:
            return None
        newprefix = self.newprefix(subnets)
        if newprefix is None:
            return None
        networks = self.subnet(newprefix.num)
        if not networks:
            return networks
        net = networks
        while len(net) != subnets:
            net = self.sum_first_found(net)
        return net

    # Returns a new IPv4 object from the supernetting
    # of the instance network.
    #
    # Supernetting is similar to subnetting, except
    # that you getting as a result a network with a
    # smaller prefix (bigger host space). For example,
    # given the network
    #
    #   ip = IPAddress("172.16.10.0/24")
    #
    # you can supernet it with a new /23 prefix
    #
    #   ip.supernet(23).to_string
    #     // => "172.16.10.0/23"
    #
    # If +new_prefix+ is less than 1, returns 0.0.0.0/0
    #
    def supernet(self, new_prefix: int) -> Optional["IPAddress"]:
        if new_prefix >= self.prefix.num:
            return None
        return self.from_(self.host_address, self.prefix.from_(new_prefix)).network()

    # This method implements the subnetting function
    # similar to the one described in RFC3531.
    #
    # By specifying a new prefix, the method calculates
    # the network number for the given IPv4 object
    # and calculates the subnets associated to the new
    # prefix.
    #
    #   ip = IPAddress "172.16.10.0/24"
    #
    #   ip.subnets(26).map(:to_string)
    #     // => ["172.16.10.0/26", "172.16.10.64/26",
    #          "172.16.10.128/26", "172.16.10.192/26"]
    #
    def subnet(self, subprefix: int) -> Optional[List["IPAddress"]]:
        if subprefix < self.prefix.num or self.ip_bits.bits < subprefix:
            return None
        ret = []
        net = self.network()
        net.prefix = net.prefix.from_(subprefix)
        for _ in range(1 << (subprefix - self.prefix.num)):
            ret.append(net.clone())
            net = net.from_(net.host_address, net.prefix)
            size = net.size()
            net.host_address = net.host_address + size
        return ret

    # Return the ip address in a format compatible
    # with the IPv6 Mapped IPv4 addresses
    #
    # Example:
    #
    #   ip = IPAddress("172.16.10.1/24")
    #
    #   ip.to_ipv6
    #     // => "ac10:0a01"
    #
    def to_ipv6(self) -> Optional["IPAddress"]:
        return self.vt_to_ipv6(self)

    def newprefix(self, num: int) -> Optional[Prefix]:
        for i in range(num, self.ip_bits.bits):
            if i <= 0:
                continue
            a = int(math.log2(i))
            if a == math.log2(i):
                return self.prefix.add(a)
        return None


__all__ = ["IPAddress", "ResultIntParts", "Is", "ToIpv6", "EachFn"]
