from ip_address.prefix128 import Prefix128


class Prefix128Test:
    def __init__(self):
        self.u128_hash = []


def setup():
    p128t = Prefix128Test()
    p128t.u128_hash.append((32, int("340282366841710300949110269838224261120")))
    p128t.u128_hash.append((64, int("340282366920938463444927863358058659840")))
    p128t.u128_hash.append((96, int("340282366920938463463374607427473244160")))
    p128t.u128_hash.append((126, int("340282366920938463463374607431768211452")))
    return p128t


def test_initialize():
    assert not Prefix128.create(129)
    assert Prefix128.create(64)


def test_method_bits():
    prefix = Prefix128.create(64)
    expected = "1" * 64 + "0" * 64
    assert expected == prefix.bits()


def test_method_to_u32():
    for num, expected in setup().u128_hash:
        assert expected == Prefix128.create(num).netmask()
