import functools

from ip_address.ipaddress import IPAddress
from ip_address.ipv6 import Ipv6


class IPv6Test:
    def __init__(self):
        self.compress_addr = []
        self.valid_ipv6 = []
        self.invalid_ipv6 = [":1:2:3:4:5:6:7", ":1:2:3:4:5:6:7", "2002:516:2:200", "dd"]
        self.networks = []
        self.ip = IPAddress.parse("2001:db8::8:800:200c:417a/64")
        self.network = IPAddress.parse("2001:db8:8:800::/64")
        self.arr = [8193, 3512, 0, 0, 8, 2048, 8204, 16762]
        self.hex = "20010db80000000000080800200c417a"


def assert_array_equal(a, b):
    assert len(a) == len(b), "length missmatch"
    for i in range(len(a)):
        assert a[i] == b[i]


def setup():
    ip6t = IPv6Test()
    ip6t.compress_addr.append(("2001:db8:0000:0000:0008:0800:200c:417a", "2001:db8::8:800:200c:417a"))
    ip6t.compress_addr.append(("2001:db8:0:0:8:800:200c:417a", "2001:db8::8:800:200c:417a"))
    ip6t.compress_addr.append(("ff01:0:0:0:0:0:0:101", "ff01::101"))
    ip6t.compress_addr.append(("0:0:0:0:0:0:0:1", "::1"))
    ip6t.compress_addr.append(("0:0:0:0:0:0:0:0", "::"))

    ip6t.valid_ipv6.append(("FEDC:BA98:7654:3210:FEDC:BA98:7654:3210", int("338770000845734292534325025077361652240")))
    ip6t.valid_ipv6.append(("1080:0000:0000:0000:0008:0800:200C:417A", int("21932261930451111902915077091070067066")))
    ip6t.valid_ipv6.append(("1080:0:0:0:8:800:200C:417A", int("21932261930451111902915077091070067066")))
    ip6t.valid_ipv6.append(("1080:0::8:800:200C:417A", int("21932261930451111902915077091070067066")))
    ip6t.valid_ipv6.append(("1080::8:800:200C:417A", int("21932261930451111902915077091070067066")))
    ip6t.valid_ipv6.append(("FF01:0:0:0:0:0:0:43", int("338958331222012082418099330867817087043")))
    ip6t.valid_ipv6.append(("FF01:0::0:0:43", int("338958331222012082418099330867817087043")))
    ip6t.valid_ipv6.append(("FF01::43", int("338958331222012082418099330867817087043")))
    ip6t.valid_ipv6.append(("0:0:0:0:0:0:0:1", int("1")))
    ip6t.valid_ipv6.append(("0:0:0::0:0:1", int("1")))
    ip6t.valid_ipv6.append(("::1", int("1")))
    ip6t.valid_ipv6.append(("0:0:0:0:0:0:0:0", int("0")))
    ip6t.valid_ipv6.append(("0:0:0::0:0:0", int("0")))
    ip6t.valid_ipv6.append(("::", int("0")))
    ip6t.valid_ipv6.append(("::/0", int("0")))
    ip6t.valid_ipv6.append(("1080:0:0:0:8:800:200C:417A", int("21932261930451111902915077091070067066")))
    ip6t.valid_ipv6.append(("1080::8:800:200C:417A", int("21932261930451111902915077091070067066")))

    ip6t.networks.append(("2001:db8:1:1:1:1:1:1/32", "2001:db8::/32"))
    ip6t.networks.append(("2001:db8:1:1:1:1:1::/32", "2001:db8::/32"))
    ip6t.networks.append(("2001:db8::1/64", "2001:db8::/64"))
    return ip6t


def test_attribute_address():
    addr = "2001:0db8:0000:0000:0008:0800:200c:417a"
    assert addr == setup().ip.to_s_uncompressed()


def test_initialize():
    assert setup().ip.is_ipv4() is False

    for ip, _num in setup().valid_ipv6:
        assert IPAddress.parse(ip)
    for ip in setup().invalid_ipv6:
        assert not IPAddress.parse(ip)
    assert 64 == setup().ip.prefix.num

    assert IPAddress.parse("::10.1.1.1")


def test_attribute_groups():
    assert_array_equal(setup().arr, setup().ip.parts())


def test_method_hexs():
    assert_array_equal(setup().ip.parts_hex_str(), ["2001", "0db8", "0000", "0000", "0008", "0800", "200c", "417a"])


def test_method_to_i():
    for ip, num in setup().valid_ipv6:
        assert num == IPAddress.parse(ip).host_address


def test_method_set_prefix():
    ip = IPAddress.parse("2001:db8::8:800:200c:417a")
    assert 128 == ip.prefix.num
    assert "2001:db8::8:800:200c:417a/128" == ip.to_string()
    nip = ip.change_prefix(64)
    assert 64 == nip.prefix.num
    assert "2001:db8::8:800:200c:417a/64" == nip.to_string()


def test_method_mapped():
    assert setup().ip.is_mapped() is False
    ip6 = IPAddress.parse("::ffff:1234:5678")
    assert ip6.is_mapped() is True


def test_method_group():
    s = setup()
    assert_array_equal(s.ip.parts(), s.arr)


def test_method_ipv4():
    assert setup().ip.is_ipv4() is False


def test_method_ipv6():
    assert setup().ip.is_ipv6() is True


def test_method_network_known():
    assert setup().network.is_network() is True
    assert setup().ip.is_network() is False


def test_method_network_u128():
    assert Ipv6.from_int(int("42540766411282592856903984951653826560"), 64).eq(setup().ip.network())


def test_method_broadcast_u128():
    assert Ipv6.from_int(int("42540766411282592875350729025363378175"), 64).eq(setup().ip.broadcast())


def test_method_size():
    ip = IPAddress.parse("2001:db8::8:800:200c:417a/64")
    assert (1 << 64) == ip.size()
    ip = IPAddress.parse("2001:db8::8:800:200c:417a/32")
    assert (1 << 96) == ip.size()
    ip = IPAddress.parse("2001:db8::8:800:200c:417a/120")
    assert (1 << 8) == ip.size()
    ip = IPAddress.parse("2001:db8::8:800:200c:417a/124")
    assert (1 << 4) == ip.size()


def test_method_includes():
    ip = setup().ip
    assert ip.includes(ip) is True
    included = IPAddress.parse("2001:db8::8:800:200c:417a/128")
    not_included = IPAddress.parse("2001:db8::8:800:200c:417a/46")
    assert ip.includes(included) is True
    assert ip.includes(not_included) is False
    included = IPAddress.parse("2001:db8::8:800:200c:0/64")
    not_included = IPAddress.parse("2001:db8:1::8:800:200c:417a/64")
    assert ip.includes(included) is True
    assert ip.includes(not_included) is False
    included = IPAddress.parse("2001:db8::8:800:200c:1/128")
    not_included = IPAddress.parse("2001:db8:1::8:800:200c:417a/76")
    assert ip.includes(included) is True
    assert ip.includes(not_included) is False


def test_method_to_hex():
    assert setup().hex
    assert setup().ip.to_hex()


def test_method_to_s():
    assert "2001:db8::8:800:200c:417a" == setup().ip.to_s()


def test_method_to_string():
    assert "2001:db8::8:800:200c:417a/64" == setup().ip.to_string()


def test_method_to_string_uncompressed():
    s = "2001:0db8:0000:0000:0008:0800:200c:417a/64"
    assert s == setup().ip.to_string_uncompressed()


def test_method_reverse():
    s = "f.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.2.0.0.0.5.0.5.0.e.f.f.3.ip6.arpa"
    assert s == IPAddress.parse("3ffe:505:2::f").dns_reverse()


def test_method_dns_rev_domains():
    assert_array_equal(IPAddress.parse("f000:f100::/3").dns_rev_domains(), ["e.ip6.arpa", "f.ip6.arpa"])
    assert_array_equal(IPAddress.parse("fea3:f120::/15").dns_rev_domains(), ["2.a.e.f.ip6.arpa", "3.a.e.f.ip6.arpa"])
    assert_array_equal(IPAddress.parse("3a03:2f80:f::/48").dns_rev_domains(), ["f.0.0.0.0.8.f.2.3.0.a.3.ip6.arpa"])

    assert_array_equal(
        IPAddress.parse("f000:f100::1234/125").dns_rev_domains(),
        [
            "0.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
            "1.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
            "2.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
            "3.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
            "4.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
            "5.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
            "6.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
            "7.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
        ],
    )


def test_method_compressed():
    assert "1:1:1::1" == IPAddress.parse("1:1:1:0:0:0:0:1").to_s()
    assert "1:0:1::1" == IPAddress.parse("1:0:1:0:0:0:0:1").to_s()
    assert "1::1:1:1:2:3:1" == IPAddress.parse("1:0:1:1:1:2:3:1").to_s()
    assert "1::1:1:0:2:3:1" == IPAddress.parse("1:0:1:1::2:3:1").to_s()
    assert "1:0:0:1::1" == IPAddress.parse("1:0:0:1:0:0:0:1").to_s()
    assert "1::1:0:0:1" == IPAddress.parse("1:0:0:0:1:0:0:1").to_s()
    assert "1::1" == IPAddress.parse("1:0:0:0:0:0:0:1").to_s()


def test_method_unspecified():
    assert IPAddress.parse("::").is_unspecified() is True
    assert setup().ip.is_unspecified() is False


def test_method_loopback():
    assert IPAddress.parse("::1").is_loopback() is True
    assert setup().ip.is_loopback() is False


def test_method_network():
    for addr, net in setup().networks:
        ip = IPAddress.parse(addr)
        assert net == ip.network().to_string()


def test_method_each():
    ip = IPAddress.parse("2001:db8::4/125")
    arr = []
    ip.each(lambda i: arr.append(i.to_s()))
    assert_array_equal(
        arr,
        [
            "2001:db8::",
            "2001:db8::1",
            "2001:db8::2",
            "2001:db8::3",
            "2001:db8::4",
            "2001:db8::5",
            "2001:db8::6",
            "2001:db8::7",
        ],
    )


def test_method_each_net():
    test_addrs = [
        "0000:0000:0000:0000:0000:0000:0000:0000",
        "1111:1111:1111:1111:1111:1111:1111:1111",
        "2222:2222:2222:2222:2222:2222:2222:2222",
        "3333:3333:3333:3333:3333:3333:3333:3333",
        "4444:4444:4444:4444:4444:4444:4444:4444",
        "5555:5555:5555:5555:5555:5555:5555:5555",
        "6666:6666:6666:6666:6666:6666:6666:6666",
        "7777:7777:7777:7777:7777:7777:7777:7777",
        "8888:8888:8888:8888:8888:8888:8888:8888",
        "9999:9999:9999:9999:9999:9999:9999:9999",
        "aaaa:aaaa:aaaa:aaaa:aaaa:aaaa:aaaa:aaaa",
        "bbbb:bbbb:bbbb:bbbb:bbbb:bbbb:bbbb:bbbb",
        "cccc:cccc:cccc:cccc:cccc:cccc:cccc:cccc",
        "dddd:dddd:dddd:dddd:dddd:dddd:dddd:dddd",
        "eeee:eeee:eeee:eeee:eeee:eeee:eeee:eeee",
        "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff",
    ]
    for prefix in range(128):
        nr_networks = 1 << ((128 - prefix) % 4)
        for adr in test_addrs:
            net_adr = IPAddress.parse(f"{adr}/{prefix}")
            ret = net_adr.dns_networks()
            assert ret[0].prefix.num % 4 == 0
            assert len(ret) == nr_networks
            assert net_adr.network().to_s() == ret[0].network().to_s()
            assert net_adr.broadcast().to_s() == ret[-1].broadcast().to_s()

    ret0 = [i.to_string() for i in IPAddress.parse("fd01:db8::4/3").dns_networks()]
    assert_array_equal(ret0, ["e000::/4", "f000::/4"])
    ret1 = [i.to_string() for i in IPAddress.parse("3a03:2f80:f::/48").dns_networks()]
    assert_array_equal(ret1, ["3a03:2f80:f::/48"])


def test_method_compare():
    ip1 = IPAddress.parse("2001:db8:1::1/64")
    ip2 = IPAddress.parse("2001:db8:2::1/64")
    ip3 = IPAddress.parse("2001:db8:1::2/64")
    ip4 = IPAddress.parse("2001:db8:1::1/65")

    assert ip2.gt(ip1) is True
    assert ip1.gt(ip2) is False
    assert ip2.lt(ip1) is False
    assert ip2.gt(ip3) is True
    assert ip2.lt(ip3) is False
    assert ip1.lt(ip3) is True
    assert ip1.gt(ip3) is False
    assert ip3.lt(ip1) is False
    assert ip1.eq(ip1) is True
    assert ip1.lt(ip4) is True
    assert ip1.gt(ip4) is False

    r = sorted([ip1, ip2, ip3, ip4], key=functools.cmp_to_key(lambda a, b: a.cmp(b)))
    ret = [i.to_string() for i in r]
    assert_array_equal(ret, ["2001:db8:1::1/64", "2001:db8:1::1/65", "2001:db8:1::2/64", "2001:db8:2::1/64"])


def test_classmethod_compress():
    compressed = "2001:db8:0:cd30::"
    expanded = "2001:0db8:0000:cd30:0000:0000:0000:0000"
    assert compressed == IPAddress.parse(expanded).to_s()
    assert "2001:db8::cd3" == IPAddress.parse("2001:0db8:0::cd3").to_s()
    assert "2001:db8::cd30" == IPAddress.parse("2001:0db8::cd30").to_s()
    assert "2001:db8::cd3" == IPAddress.parse("2001:0db8::cd3").to_s()


def test_classhmethod_parse_u128():
    for ip, num in setup().valid_ipv6:
        assert IPAddress.parse(ip).to_s() == Ipv6.from_int(num, 128).to_s()


def test_classmethod_parse_hex():
    assert setup().ip.to_string() == Ipv6.from_str(setup().hex, 16, 64).to_string()
