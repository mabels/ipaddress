from ip_address.ipaddress import IPAddress
from ip_address.ipv6_mapped import Ipv6Mapped


class IPv6MappedTest:
    def __init__(self, ip, s, sstr, string, u128, address):
        self.ip = ip
        self.s = s
        self.sstr = sstr
        self.string = string
        self.u128 = u128
        self.address = address
        self.valid_mapped = []
        self.valid_mapped_ipv6 = []
        self.valid_mapped_ipv6_conversion = []


def setup():
    ipv6 = IPv6MappedTest(
        ip=Ipv6Mapped.create("::172.16.10.1"),
        s="::ffff:172.16.10.1",
        sstr="::ffff:172.16.10.1/32",
        string="0000:0000:0000:0000:0000:ffff:ac10:0a01/128",
        u128=int("281473568475649"),
        address="::ffff:ac10:a01/128",
    )
    ipv6.valid_mapped.append(("::13.1.68.3", int("281470899930115")))
    ipv6.valid_mapped.append(("0:0:0:0:0:ffff:129.144.52.38", int("281472855454758")))
    ipv6.valid_mapped.append(("::ffff:129.144.52.38", int("281472855454758")))
    ipv6.valid_mapped_ipv6.append(("::ffff:13.1.68.3", int("281470899930115")))
    ipv6.valid_mapped_ipv6.append(("0:0:0:0:0:ffff:8190:3426", int("281472855454758")))
    ipv6.valid_mapped_ipv6.append(("::ffff:8190:3426", int("281472855454758")))
    ipv6.valid_mapped_ipv6_conversion.append(("::ffff:13.1.68.3", "13.1.68.3"))
    ipv6.valid_mapped_ipv6_conversion.append(("0:0:0:0:0:ffff:8190:3426", "129.144.52.38"))
    ipv6.valid_mapped_ipv6_conversion.append(("::ffff:8190:3426", "129.144.52.38"))
    return ipv6


def test_initialize():
    s = setup()
    assert IPAddress.parse("::172.16.10.1")
    for ip, u128 in s.valid_mapped:
        assert IPAddress.parse(ip)
        assert str(u128) == str(IPAddress.parse(ip).host_address)
    for ip, u128 in s.valid_mapped_ipv6:
        assert IPAddress.parse(ip)
        assert str(u128) == str(IPAddress.parse(ip).host_address)


def test_mapped_from_ipv6_conversion():
    for ip6, ip4 in setup().valid_mapped_ipv6_conversion:
        assert ip4 == IPAddress.parse(ip6).mapped.to_s()


def test_attributes():
    s = setup()
    assert s.address == s.ip.to_string()
    assert 128 == s.ip.prefix.num
    assert s.s == s.ip.to_s_mapped()
    assert s.sstr == s.ip.to_string_mapped()
    assert s.string == s.ip.to_string_uncompressed()
    assert str(s.u128) == str(s.ip.host_address)


def test_method_ipv6():
    assert setup().ip.is_ipv6()


def test_mapped():
    assert setup().ip.is_mapped()
