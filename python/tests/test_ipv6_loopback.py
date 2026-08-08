from ip_address.ipv6_loopback import Ipv6Loopback


class IPv6LoopbackTest:
    def __init__(self, ip, s, n, string, one):
        self.ip = ip
        self.s = s
        self.n = n
        self.string = string
        self.one = one


def setup():
    return IPv6LoopbackTest(
        ip=Ipv6Loopback.create(),
        s="::1",
        n="::1/128",
        string="0000:0000:0000:0000:0000:0000:0000:0001/128",
        one=1,
    )


def test_attributes():
    s = setup()
    assert 128 == s.ip.prefix.num
    assert s.ip.is_loopback() is True
    assert s.s == s.ip.to_s()
    assert s.n == s.ip.to_string()
    assert s.string == s.ip.to_string_uncompressed()
    assert str(s.one) == str(s.ip.host_address)


def test_method_ipv6():
    assert setup().ip.is_ipv6() is True
