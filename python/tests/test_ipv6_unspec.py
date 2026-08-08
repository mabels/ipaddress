from ip_address.ipv6_unspec import Ipv6Unspec


class IPv6UnspecifiedTest:
    def __init__(self, ip, to_s, to_string, to_string_uncompressed, num):
        self.ip = ip
        self.to_s = to_s
        self.to_string = to_string
        self.to_string_uncompressed = to_string_uncompressed
        self.num = num


def setup():
    return IPv6UnspecifiedTest(
        ip=Ipv6Unspec.create(),
        to_s="::",
        to_string="::/128",
        to_string_uncompressed="0000:0000:0000:0000:0000:0000:0000:0000/128",
        num=0,
    )


def test_attributes():
    assert setup().ip.host_address == setup().num
    assert 128 == setup().ip.prefix.num
    assert setup().ip.is_unspecified() is True
    assert setup().to_s == setup().ip.to_s()
    assert setup().to_string == setup().ip.to_string()
    assert setup().to_string_uncompressed == setup().ip.to_string_uncompressed()


def test_method_ipv6():
    assert setup().ip.is_ipv6() is True
