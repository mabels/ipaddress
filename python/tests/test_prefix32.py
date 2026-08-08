from ip_address.ipaddress import IPAddress
from ip_address.ipv4 import Ipv4
from ip_address.prefix32 import Prefix32


class Prefix32Test:
    def __init__(self):
        self.netmask0 = "0.0.0.0"
        self.netmask8 = "255.0.0.0"
        self.netmask16 = "255.255.0.0"
        self.netmask24 = "255.255.255.0"
        self.netmask30 = "255.255.255.252"
        self.netmasks = []
        self.prefix_hash = []
        self.octets_hash = []
        self.u32_hash = []


def assert_array_equal(a, b):
    assert len(a) == len(b), "length missmatch"
    for i in range(len(a)):
        assert a[i] == b[i]


def setup():
    p32t = Prefix32Test()
    p32t.netmasks.append(p32t.netmask0)
    p32t.netmasks.append(p32t.netmask8)
    p32t.netmasks.append(p32t.netmask16)
    p32t.netmasks.append(p32t.netmask24)
    p32t.netmasks.append(p32t.netmask30)
    p32t.prefix_hash.append(("0.0.0.0", 0))
    p32t.prefix_hash.append(("255.0.0.0", 8))
    p32t.prefix_hash.append(("255.255.0.0", 16))
    p32t.prefix_hash.append(("255.255.255.0", 24))
    p32t.prefix_hash.append(("255.255.255.252", 30))
    p32t.octets_hash.append(([0, 0, 0, 0], 0))
    p32t.octets_hash.append(([255, 0, 0, 0], 8))
    p32t.octets_hash.append(([255, 255, 0, 0], 16))
    p32t.octets_hash.append(([255, 255, 255, 0], 24))
    p32t.octets_hash.append(([255, 255, 255, 252], 30))
    p32t.u32_hash.append((0, 0))
    p32t.u32_hash.append((8, int("4278190080")))
    p32t.u32_hash.append((16, int("4294901760")))
    p32t.u32_hash.append((24, int("4294967040")))
    p32t.u32_hash.append((30, int("4294967292")))
    return p32t


def test_attributes():
    for netmask, num in setup().prefix_hash:
        prefix = Prefix32.create(num)
        assert num == prefix.num


def test_parse_netmask_to_prefix():
    for netmask, num in setup().prefix_hash:
        prefix = IPAddress.parse_netmask_to_prefix(netmask)
        assert num == prefix


def test_method_to_ip():
    for netmask, num in setup().prefix_hash:
        prefix = Prefix32.create(num)
        assert netmask == prefix.to_ip_str()


def test_method_to_s():
    prefix = Prefix32.create(8)
    assert "8" == prefix.to_s()


def test_method_bits():
    prefix = Prefix32.create(16)
    assert "11111111111111110000000000000000" == prefix.bits()


def test_method_to_u32():
    for num, ip32 in setup().u32_hash:
        assert ip32 == Prefix32.create(num).netmask()


def test_method_plus():
    p1 = Prefix32.create(8)
    p2 = Prefix32.create(10)
    assert 18 == p1.add_prefix(p2).num
    assert 12 == p1.add(4).num


def test_method_minus():
    p1 = Prefix32.create(8)
    p2 = Prefix32.create(24)
    assert 16 == p1.sub_prefix(p2).num
    assert 16 == p2.sub_prefix(p1).num
    assert 20 == p2.sub(4).num


def test_initialize():
    assert Prefix32.create(33) is None
    assert Prefix32.create(8)


def test_method_octets():
    for arr, pref in setup().octets_hash:
        prefix = Prefix32.create(pref)
        assert_array_equal(prefix.ip_bits.parts(prefix.netmask()), arr)


def test_method_brackets():
    for arr, pref in setup().octets_hash:
        prefix = Prefix32.create(pref)
        for index in range(len(arr)):
            assert prefix.ip_bits.parts(prefix.netmask())[index] == arr[index]


def test_method_hostmask():
    prefix = Prefix32.create(8)
    assert "0.255.255.255" == Ipv4.from_number(prefix.host_mask(), 0).to_s()
