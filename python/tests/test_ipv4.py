from ip_address.ipaddress import IPAddress
from ip_address.ipv4 import Ipv4


class IPv4Prefix:
    def __init__(self, ip, prefix):
        self.ip = ip
        self.prefix = prefix


class IPv4Test:
    def __init__(self):
        self.valid_ipv4 = []
        self.invalid_ipv4 = ["10.0.0.256", "10.0.0.0.0"]
        self.valid_ipv4_range = ["10.0.0.1-254", "10.0.1-254.0", "10.1-254.0.0"]
        self.netmask_values = []
        self.decimal_values = []
        self.ip = IPAddress.parse("172.16.10.1/24")
        self.network = IPAddress.parse("172.16.10.0/24")
        self.networks = []
        self.broadcast = []
        self.class_a = IPAddress.parse("10.0.0.1/8")
        self.class_b = IPAddress.parse("172.16.0.1/16")
        self.class_c = IPAddress.parse("192.168.0.1/24")
        self.classful = []


def assert_array_equal(a, b):
    assert len(a) == len(b), "length missmatch"
    for i in range(len(a)):
        assert a[i] == b[i]


def setup():
    ipv4t = IPv4Test()
    ipv4t.valid_ipv4.append(("9.9/17", IPv4Prefix("9.0.0.9", 17)))
    ipv4t.valid_ipv4.append(("100.1.100", IPv4Prefix("100.1.0.100", 32)))
    ipv4t.valid_ipv4.append(("0.0.0.0/0", IPv4Prefix("0.0.0.0", 0)))
    ipv4t.valid_ipv4.append(("10.0.0.0", IPv4Prefix("10.0.0.0", 32)))
    ipv4t.valid_ipv4.append(("10.0.0.1", IPv4Prefix("10.0.0.1", 32)))
    ipv4t.valid_ipv4.append(("10.0.0.1/24", IPv4Prefix("10.0.0.1", 24)))
    ipv4t.valid_ipv4.append(("10.0.0.9/255.255.255.0", IPv4Prefix("10.0.0.9", 24)))

    ipv4t.netmask_values.append(("0.0.0.0/0", "0.0.0.0"))
    ipv4t.netmask_values.append(("10.0.0.0/8", "255.0.0.0"))
    ipv4t.netmask_values.append(("172.16.0.0/16", "255.255.0.0"))
    ipv4t.netmask_values.append(("192.168.0.0/24", "255.255.255.0"))
    ipv4t.netmask_values.append(("192.168.100.4/30", "255.255.255.252"))

    ipv4t.decimal_values.append(("0.0.0.0/0", int("0")))
    ipv4t.decimal_values.append(("10.0.0.0/8", int("167772160")))
    ipv4t.decimal_values.append(("172.16.0.0/16", int("2886729728")))
    ipv4t.decimal_values.append(("192.168.0.0/24", int("3232235520")))
    ipv4t.decimal_values.append(("192.168.100.4/30", int("3232261124")))

    ipv4t.broadcast.append(("10.0.0.0/8", "10.255.255.255/8"))
    ipv4t.broadcast.append(("172.16.0.0/16", "172.16.255.255/16"))
    ipv4t.broadcast.append(("192.168.0.0/24", "192.168.0.255/24"))
    ipv4t.broadcast.append(("192.168.100.4/30", "192.168.100.7/30"))

    ipv4t.networks.append(("10.5.4.3/8", "10.0.0.0/8"))
    ipv4t.networks.append(("172.16.5.4/16", "172.16.0.0/16"))
    ipv4t.networks.append(("192.168.4.3/24", "192.168.4.0/24"))
    ipv4t.networks.append(("192.168.100.5/30", "192.168.100.4/30"))

    ipv4t.classful.append(("10.1.1.1", 8))
    ipv4t.classful.append(("150.1.1.1", 16))
    ipv4t.classful.append(("200.1.1.1", 24))
    return ipv4t


def test_initialize():
    for arg, _attr in setup().valid_ipv4:
        ip = IPAddress.parse(arg)
        assert ip.is_ipv4() and not ip.is_ipv6()
    assert 32 == setup().ip.prefix.ip_bits.bits
    assert IPAddress.parse("1.f.13.1/-3") is None
    assert IPAddress.parse("10.0.0.0/8")


def test_initialize_format_error():
    for i in setup().invalid_ipv4:
        assert IPAddress.parse(i) is None
    assert IPAddress.parse("10.0.0.0/asd") is None


def test_initialize_without_prefix():
    assert IPAddress.parse("10.10.0.0")
    ip = IPAddress.parse("10.10.0.0")
    assert not ip.is_ipv6() and ip.is_ipv4()
    assert 32 == ip.prefix.num


def test_attributes():
    for arg, attr in setup().valid_ipv4:
        ip = IPAddress.parse(arg)
        assert attr.ip == ip.to_s()
        assert attr.prefix == ip.prefix.num


def test_octets():
    ip = IPAddress.parse("10.1.2.3/8")
    assert_array_equal(ip.parts(), [10, 1, 2, 3])


def test_method_to_string():
    for arg, attr in setup().valid_ipv4:
        ip = IPAddress.parse(arg)
        assert f"{attr.ip}/{attr.prefix}" == ip.to_string()


def test_method_to_s():
    for arg, attr in setup().valid_ipv4:
        ip = IPAddress.parse(arg)
        assert attr.ip == ip.to_s()


def test_netmask():
    for addr, mask in setup().netmask_values:
        ip = IPAddress.parse(addr)
        assert ip.netmask().to_s() == mask


def test_method_to_u32():
    for addr, num in setup().decimal_values:
        ip = IPAddress.parse(addr)
        assert ip.host_address == num


def test_method_is_network():
    assert setup().network.is_network() is True
    assert setup().ip.is_network() is False


def test_one_address_network():
    network = IPAddress.parse("172.16.10.1/32")
    assert network.is_network() is False


def test_method_broadcast():
    for addr, bcast in setup().broadcast:
        ip = IPAddress.parse(addr)
        assert bcast == ip.broadcast().to_string()


def test_method_network():
    for addr, net in setup().networks:
        ip = IPAddress.parse(addr)
        assert net == ip.network().to_string()


def test_method_bits():
    ip = IPAddress.parse("127.0.0.1")
    assert "01111111000000000000000000000001" == ip.bits()


def test_method_first():
    ip = IPAddress.parse("192.168.100.0/24")
    assert "192.168.100.1" == ip.first().to_s()
    ip = IPAddress.parse("192.168.100.50/24")
    assert "192.168.100.1" == ip.first().to_s()


def test_method_last():
    ip = IPAddress.parse("192.168.100.0/24")
    assert "192.168.100.254" == ip.last().to_s()
    ip = IPAddress.parse("192.168.100.50/24")
    assert "192.168.100.254" == ip.last().to_s()


def test_method_each_host():
    ip = IPAddress.parse("10.0.0.1/29")
    arr = []
    ip.each_host(lambda i: arr.append(i.to_s()))
    assert_array_equal(arr, ["10.0.0.1", "10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6"])


def test_method_each():
    ip = IPAddress.parse("10.0.0.1/29")
    arr = []
    ip.each(lambda i: arr.append(i.to_s()))
    assert_array_equal(arr, ["10.0.0.0", "10.0.0.1", "10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6", "10.0.0.7"])


def test_method_size():
    ip = IPAddress.parse("10.0.0.1/29")
    assert ip.size() == int("8")


def test_method_network_u32():
    assert "2886732288" == str(setup().ip.network().host_address)


def test_method_broadcast_u32():
    assert "2886732543" == str(setup().ip.broadcast().host_address)


def test_method_include():
    ip = IPAddress.parse("192.168.10.100/24")
    addr = IPAddress.parse("192.168.10.102/24")
    assert ip.includes(addr) is True
    assert ip.includes(IPAddress.parse("172.16.0.48")) is False
    ip = IPAddress.parse("10.0.0.0/8")
    assert ip.includes(IPAddress.parse("10.0.0.0/9")) is True
    assert ip.includes(IPAddress.parse("10.1.1.1/32")) is True
    assert ip.includes(IPAddress.parse("10.1.1.1/9")) is True
    assert ip.includes(IPAddress.parse("172.16.0.0/16")) is False
    assert ip.includes(IPAddress.parse("10.0.0.0/7")) is False
    assert ip.includes(IPAddress.parse("5.5.5.5/32")) is False
    assert ip.includes(IPAddress.parse("11.0.0.0/8")) is False
    ip = IPAddress.parse("13.13.0.0/13")
    assert ip.includes(IPAddress.parse("13.16.0.0/32")) is False


def test_method_include_all():
    ip = IPAddress.parse("192.168.10.100/24")
    addr1 = IPAddress.parse("192.168.10.102/24")
    addr2 = IPAddress.parse("192.168.10.103/24")
    assert ip.includes_all([addr1, addr2]) is True
    assert ip.includes_all([addr1, IPAddress.parse("13.16.0.0/32")]) is False


def test_method_ipv4():
    assert setup().ip.is_ipv4() is True


def test_method_ipv6():
    assert setup().ip.is_ipv6() is False


def test_method_private():
    assert IPAddress.parse("169.254.99.4/24").is_private() is True
    assert IPAddress.parse("192.168.10.50/24").is_private() is True
    assert IPAddress.parse("192.168.10.50/16").is_private() is True
    assert IPAddress.parse("172.16.77.40/24").is_private() is True
    assert IPAddress.parse("172.16.10.50/14").is_private() is True
    assert IPAddress.parse("10.10.10.10/10").is_private() is True
    assert IPAddress.parse("10.0.0.0/8").is_private() is True
    assert IPAddress.parse("192.168.10.50/12").is_private() is False
    assert IPAddress.parse("3.3.3.3").is_private() is False
    assert IPAddress.parse("10.0.0.0/7").is_private() is False
    assert IPAddress.parse("172.32.0.0/12").is_private() is False
    assert IPAddress.parse("172.16.0.0/11").is_private() is False
    assert IPAddress.parse("192.0.0.2/24").is_private() is False


def test_method_octet():
    assert setup().ip.parts()[0] == 172
    assert setup().ip.parts()[1] == 16
    assert setup().ip.parts()[2] == 10
    assert setup().ip.parts()[3] == 1


def test_method_a():
    assert Ipv4.is_class_a(setup().class_a) is True
    assert Ipv4.is_class_a(setup().class_b) is False
    assert Ipv4.is_class_a(setup().class_c) is False


def test_method_b():
    assert Ipv4.is_class_b(setup().class_b) is True
    assert Ipv4.is_class_b(setup().class_a) is False
    assert Ipv4.is_class_b(setup().class_c) is False


def test_method_c():
    assert Ipv4.is_class_c(setup().class_c) is True
    assert Ipv4.is_class_c(setup().class_a) is False
    assert Ipv4.is_class_c(setup().class_b) is False


def test_method_to_ipv6():
    assert "::ac10:a01" == setup().ip.to_ipv6().to_s()


def test_method_reverse():
    assert setup().ip.dns_reverse() == "10.16.172.in-addr.arpa"


def test_method_dns_rev_domains():
    assert_array_equal(
        IPAddress.parse("173.17.5.1/23").dns_rev_domains(), ["4.17.173.in-addr.arpa", "5.17.173.in-addr.arpa"]
    )
    assert_array_equal(IPAddress.parse("173.17.1.1/15").dns_rev_domains(), ["16.173.in-addr.arpa", "17.173.in-addr.arpa"])
    assert_array_equal(IPAddress.parse("173.17.1.1/7").dns_rev_domains(), ["172.in-addr.arpa", "173.in-addr.arpa"])
    assert_array_equal(
        IPAddress.parse("173.17.1.1/29").dns_rev_domains(),
        [
            "0.1.17.173.in-addr.arpa",
            "1.1.17.173.in-addr.arpa",
            "2.1.17.173.in-addr.arpa",
            "3.1.17.173.in-addr.arpa",
            "4.1.17.173.in-addr.arpa",
            "5.1.17.173.in-addr.arpa",
            "6.1.17.173.in-addr.arpa",
            "7.1.17.173.in-addr.arpa",
        ],
    )
    assert_array_equal(IPAddress.parse("174.17.1.1/24").dns_rev_domains(), ["1.17.174.in-addr.arpa"])
    assert_array_equal(IPAddress.parse("175.17.1.1/16").dns_rev_domains(), ["17.175.in-addr.arpa"])
    assert_array_equal(IPAddress.parse("176.17.1.1/8").dns_rev_domains(), ["176.in-addr.arpa"])
    assert_array_equal(IPAddress.parse("177.17.1.1/0").dns_rev_domains(), ["in-addr.arpa"])
    assert_array_equal(IPAddress.parse("178.17.1.1/32").dns_rev_domains(), ["1.1.17.178.in-addr.arpa"])


def test_method_compare():
    ip1 = IPAddress.parse("10.1.1.1/8")
    ip2 = IPAddress.parse("10.1.1.1/16")
    ip3 = IPAddress.parse("172.16.1.1/14")
    ip4 = IPAddress.parse("10.1.1.1/8")

    assert ip1.lt(ip2) is True
    assert ip1.gt(ip2) is False
    assert ip2.lt(ip1) is False
    assert ip2.lt(ip3) is True
    assert ip2.gt(ip3) is False
    assert ip1.lt(ip3) is True
    assert ip1.gt(ip3) is False
    assert ip3.lt(ip1) is False
    assert ip1.eq(ip1) is True
    assert ip1.eq(ip4) is True

    import functools

    res = sorted([ip1, ip2, ip3], key=functools.cmp_to_key(lambda a, b: a.cmp(b)))
    assert_array_equal(IPAddress.to_string_vec(res), ["10.1.1.1/8", "10.1.1.1/16", "172.16.1.1/14"])

    ip1 = IPAddress.parse("10.0.0.0/24")
    ip2 = IPAddress.parse("10.0.0.0/16")
    ip3 = IPAddress.parse("10.0.0.0/8")
    res = sorted([ip1, ip2, ip3], key=functools.cmp_to_key(lambda a, b: a.cmp(b)))
    assert_array_equal(IPAddress.to_string_vec(res), ["10.0.0.0/8", "10.0.0.0/16", "10.0.0.0/24"])


def test_method_minus():
    ip1 = IPAddress.parse("10.1.1.1/8")
    ip2 = IPAddress.parse("10.1.1.10/8")
    assert "9" == str(ip2.sub(ip1))
    assert "9" == str(ip1.sub(ip2))


def test_method_plus():
    ip1 = IPAddress.parse("172.16.10.1/24")
    ip2 = IPAddress.parse("172.16.11.2/24")
    assert_array_equal(IPAddress.to_string_vec(ip1.add(ip2)), ["172.16.10.0/23"])

    ip2 = IPAddress.parse("172.16.12.2/24")
    assert_array_equal(IPAddress.to_string_vec(ip1.add(ip2)), [ip1.network().to_string(), ip2.network().to_string()])

    ip1 = IPAddress.parse("10.0.0.0/23")
    ip2 = IPAddress.parse("10.0.2.0/24")
    assert_array_equal(IPAddress.to_string_vec(ip1.add(ip2)), ["10.0.0.0/23", "10.0.2.0/24"])

    ip1 = IPAddress.parse("10.0.0.0/23")
    ip2 = IPAddress.parse("10.0.2.0/24")
    assert_array_equal(IPAddress.to_string_vec(ip1.add(ip2)), ["10.0.0.0/23", "10.0.2.0/24"])

    ip1 = IPAddress.parse("10.0.0.0/16")
    ip2 = IPAddress.parse("10.0.2.0/24")
    assert_array_equal(IPAddress.to_string_vec(ip1.add(ip2)), ["10.0.0.0/16"])

    ip1 = IPAddress.parse("10.0.0.0/23")
    ip2 = IPAddress.parse("10.1.0.0/24")
    assert_array_equal(IPAddress.to_string_vec(ip1.add(ip2)), ["10.0.0.0/23", "10.1.0.0/24"])


def test_method_netmask_equal():
    ip = IPAddress.parse("10.1.1.1/16")
    assert 16 == ip.prefix.num
    ip2 = ip.change_netmask("255.255.255.0")
    assert 24 == ip2.prefix.num


def test_method_split():
    assert setup().ip.split(0) is None
    assert setup().ip.split(257) is None

    assert_array_equal(IPAddress.to_string_vec(setup().ip.split(1)), [setup().ip.network().to_string()])

    assert_array_equal(
        IPAddress.to_string_vec(setup().network.split(8)),
        [
            "172.16.10.0/27",
            "172.16.10.32/27",
            "172.16.10.64/27",
            "172.16.10.96/27",
            "172.16.10.128/27",
            "172.16.10.160/27",
            "172.16.10.192/27",
            "172.16.10.224/27",
        ],
    )

    assert_array_equal(
        IPAddress.to_string_vec(setup().network.split(7)),
        [
            "172.16.10.0/27",
            "172.16.10.32/27",
            "172.16.10.64/27",
            "172.16.10.96/27",
            "172.16.10.128/27",
            "172.16.10.160/27",
            "172.16.10.192/26",
        ],
    )

    assert_array_equal(
        IPAddress.to_string_vec(setup().network.split(6)),
        [
            "172.16.10.0/27",
            "172.16.10.32/27",
            "172.16.10.64/27",
            "172.16.10.96/27",
            "172.16.10.128/26",
            "172.16.10.192/26",
        ],
    )
    assert_array_equal(
        IPAddress.to_string_vec(setup().network.split(5)),
        [
            "172.16.10.0/27",
            "172.16.10.32/27",
            "172.16.10.64/27",
            "172.16.10.96/27",
            "172.16.10.128/25",
        ],
    )
    assert_array_equal(
        IPAddress.to_string_vec(setup().network.split(4)),
        ["172.16.10.0/26", "172.16.10.64/26", "172.16.10.128/26", "172.16.10.192/26"],
    )
    assert_array_equal(
        IPAddress.to_string_vec(setup().network.split(3)), ["172.16.10.0/26", "172.16.10.64/26", "172.16.10.128/25"]
    )
    assert_array_equal(IPAddress.to_string_vec(setup().network.split(2)), ["172.16.10.0/25", "172.16.10.128/25"])
    assert_array_equal(IPAddress.to_string_vec(setup().network.split(1)), ["172.16.10.0/24"])


def test_method_subnet():
    assert setup().network.subnet(23) is None
    assert setup().network.subnet(33) is None
    assert setup().ip.subnet(30)
    assert_array_equal(
        IPAddress.to_string_vec(setup().network.subnet(26)),
        ["172.16.10.0/26", "172.16.10.64/26", "172.16.10.128/26", "172.16.10.192/26"],
    )
    assert_array_equal(IPAddress.to_string_vec(setup().network.subnet(25)), ["172.16.10.0/25", "172.16.10.128/25"])
    assert_array_equal(IPAddress.to_string_vec(setup().network.subnet(24)), ["172.16.10.0/24"])


def test_method_supernet():
    assert setup().ip.supernet(24) is None
    assert "0.0.0.0/0" == setup().ip.supernet(0).to_string()
    assert "172.16.10.0/23" == setup().ip.supernet(23).to_string()
    assert "172.16.8.0/22" == setup().ip.supernet(22).to_string()


def test_classmethod_parse_u32():
    for addr, num in setup().decimal_values:
        ip = Ipv4.from_number(num, 32)
        splitted = addr.split("/")
        ip2 = ip.change_prefix(int(splitted[1]))
        assert ip2.to_string() == addr


def test_classmethod_summarize():
    assert_array_equal(IPAddress.to_string_vec(IPAddress.summarize([setup().ip])), [setup().ip.network().to_string()])

    ip1 = IPAddress.parse("172.16.10.1/24")
    ip2 = IPAddress.parse("172.16.11.2/24")
    assert_array_equal(IPAddress.to_string_vec(IPAddress.summarize([ip1, ip2])), ["172.16.10.0/23"])

    ip1 = IPAddress.parse("10.0.0.1/24")
    ip2 = IPAddress.parse("10.0.1.1/24")
    ip3 = IPAddress.parse("10.0.2.1/24")
    ip4 = IPAddress.parse("10.0.3.1/24")
    assert_array_equal(IPAddress.to_string_vec(IPAddress.summarize([ip1, ip2, ip3, ip4])), ["10.0.0.0/22"])
    assert_array_equal(IPAddress.to_string_vec(IPAddress.summarize([ip4, ip3, ip2, ip1])), ["10.0.0.0/22"])

    ip1 = IPAddress.parse("10.0.0.0/23")
    ip2 = IPAddress.parse("10.0.2.0/24")
    assert_array_equal(IPAddress.to_string_vec(IPAddress.summarize([ip1, ip2])), ["10.0.0.0/23", "10.0.2.0/24"])

    ip1 = IPAddress.parse("10.0.0.0/16")
    ip2 = IPAddress.parse("10.0.2.0/24")
    assert_array_equal(IPAddress.to_string_vec(IPAddress.summarize([ip1, ip2])), ["10.0.0.0/16"])

    ip1 = IPAddress.parse("10.0.0.0/23")
    ip2 = IPAddress.parse("10.1.0.0/24")
    assert_array_equal(IPAddress.to_string_vec(IPAddress.summarize([ip1, ip2])), ["10.0.0.0/23", "10.1.0.0/24"])

    ip1 = IPAddress.parse("10.0.0.0/23")
    ip2 = IPAddress.parse("10.0.2.0/23")
    ip3 = IPAddress.parse("10.0.4.0/24")
    ip4 = IPAddress.parse("10.0.6.0/24")
    assert_array_equal(
        IPAddress.to_string_vec(IPAddress.summarize([ip1, ip2, ip3, ip4])),
        ["10.0.0.0/22", "10.0.4.0/24", "10.0.6.0/24"],
    )

    ip1 = IPAddress.parse("10.0.1.1/24")
    ip2 = IPAddress.parse("10.0.2.1/24")
    ip3 = IPAddress.parse("10.0.3.1/24")
    ip4 = IPAddress.parse("10.0.4.1/24")
    assert_array_equal(
        IPAddress.to_string_vec(IPAddress.summarize([ip1, ip2, ip3, ip4])),
        ["10.0.1.0/24", "10.0.2.0/23", "10.0.4.0/24"],
    )
    assert_array_equal(
        IPAddress.to_string_vec(IPAddress.summarize([ip4, ip3, ip2, ip1])),
        ["10.0.1.0/24", "10.0.2.0/23", "10.0.4.0/24"],
    )

    ip1 = IPAddress.parse("10.0.1.1/24")
    ip2 = IPAddress.parse("10.10.2.1/24")
    ip3 = IPAddress.parse("172.16.0.1/24")
    ip4 = IPAddress.parse("172.16.1.1/24")
    assert_array_equal(
        IPAddress.to_string_vec(IPAddress.summarize([ip1, ip2, ip3, ip4])),
        ["10.0.1.0/24", "10.10.2.0/24", "172.16.0.0/23"],
    )

    ips = [IPAddress.parse("10.0.0.12/30"), IPAddress.parse("10.0.100.0/24")]
    assert_array_equal(IPAddress.to_string_vec(IPAddress.summarize(ips)), ["10.0.0.12/30", "10.0.100.0/24"])

    ips = [IPAddress.parse("172.16.0.0/31"), IPAddress.parse("10.10.2.1/32")]
    assert_array_equal(IPAddress.to_string_vec(IPAddress.summarize(ips)), ["10.10.2.1/32", "172.16.0.0/31"])

    ips = [IPAddress.parse("172.16.0.0/32"), IPAddress.parse("10.10.2.1/32")]
    assert_array_equal(IPAddress.to_string_vec(IPAddress.summarize(ips)), ["10.10.2.1/32", "172.16.0.0/32"])


def test_classmethod_parse_classful():
    for ip, prefix in setup().classful:
        res = Ipv4.parse_classful(ip)
        assert prefix == res.prefix.num
        assert f"{ip}/{prefix}" == res.to_string()
    assert Ipv4.parse_classful("192.168.256.257") is None
