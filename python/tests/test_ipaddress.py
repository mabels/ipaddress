from ip_address.ipaddress import IPAddress


class IPAddressTest:
    valid_ipv4 = "172.16.10.1/24"
    valid_ipv6 = "2001:db8::8:800:200c:417a/64"
    valid_mapped = "::13.1.68.3"
    invalid_ipv4 = "10.0.0.256"
    invalid_ipv6 = ":1:2:3:4:5:6:7"
    invalid_mapped = "::1:2.3.4"


def setup():
    return IPAddressTest()


def assert_array_equal(a, b):
    assert len(a) == len(b), "length missmatch"
    for i in range(len(a)):
        assert a[i] == b[i]


def test_method_ipaddress():
    assert IPAddress.parse(setup().valid_ipv4)
    assert IPAddress.parse(setup().valid_ipv6)
    assert IPAddress.parse(setup().valid_mapped)

    assert IPAddress.parse(setup().valid_ipv4).is_ipv4()
    assert IPAddress.parse(setup().valid_ipv6).is_ipv6()
    assert IPAddress.parse(setup().valid_mapped).is_mapped()

    assert IPAddress.parse(setup().invalid_ipv4) is None
    assert IPAddress.parse(setup().invalid_ipv6) is None
    assert IPAddress.parse(setup().invalid_mapped) is None


def test_module_method_valid():
    assert IPAddress.is_valid("10.0.0.1") is True
    assert IPAddress.is_valid("10.0.0.0") is True
    assert IPAddress.is_valid("2002::1") is True
    assert IPAddress.is_valid("dead:beef:cafe:babe::f0ad") is True
    assert IPAddress.is_valid("10.0.0.256") is False
    assert IPAddress.is_valid("10.0.0.0.0") is False
    assert IPAddress.is_valid("10.0.0") is True
    assert IPAddress.is_valid("10.0") is True
    assert IPAddress.is_valid("2002:516:2:200") is False
    assert IPAddress.is_valid("2002:::1") is False


def test_module_method_valid_ipv4_netmark():
    assert IPAddress.is_valid_netmask("255.255.255.0") is True
    assert IPAddress.is_valid_netmask("10.0.0.1") is False


def test_summarize():
    netstr = []
    for start, target in [(1, 10), (11, 127), (128, 169), (170, 172), (173, 192), (193, 224)]:
        for i in range(start, target):
            netstr.append(f"{i}.0.0.0/8")
    for i in range(256):
        if i != 254:
            netstr.append(f"169.{i}.0.0/16")
    for i in range(256):
        if i < 16 or i > 31:
            netstr.append(f"172.{i}.0.0/16")
    for i in range(256):
        if i != 168:
            netstr.append(f"192.{i}.0.0/16")
    ip_addresses = [IPAddress.parse(net) for net in netstr]

    assert len(IPAddress.summarize_str([])) == 0
    assert_array_equal(IPAddress.to_string_vec(IPAddress.summarize_str(["10.1.0.4/24"])), ["10.1.0.0/24"])
    assert_array_equal(IPAddress.to_string_vec(IPAddress.summarize_str(["2000:1::4711/32"])), ["2000:1::/32"])

    assert_array_equal(
        IPAddress.to_string_vec(IPAddress.summarize_str(["10.1.0.4/24", "7.0.0.0/0", "1.2.3.4/4"])), ["0.0.0.0/0"]
    )
    assert_array_equal(
        IPAddress.to_string_vec(
            IPAddress.summarize_str(
                [
                    "2000:1::/32",
                    "3000:1::/32",
                    "2000:2::/32",
                    "2000:3::/32",
                    "2000:4::/32",
                    "2000:5::/32",
                    "2000:6::/32",
                    "2000:7::/32",
                    "2000:8::/32",
                ]
            )
        ),
        ["2000:1::/32", "2000:2::/31", "2000:4::/30", "2000:8::/32", "3000:1::/32"],
    )

    assert_array_equal(
        IPAddress.to_string_vec(
            IPAddress.summarize_str(
                [
                    "10.0.1.1/24",
                    "30.0.1.0/16",
                    "10.0.2.0/24",
                    "10.0.3.0/24",
                    "10.0.4.0/24",
                    "10.0.5.0/24",
                    "10.0.6.0/24",
                    "10.0.7.0/24",
                    "10.0.8.0/24",
                ]
            )
        ),
        ["10.0.1.0/24", "10.0.2.0/23", "10.0.4.0/22", "10.0.8.0/24", "30.0.0.0/16"],
    )

    assert_array_equal(
        IPAddress.to_string_vec(IPAddress.summarize_str(["10.0.0.0/23", "10.0.2.0/24"])),
        ["10.0.0.0/23", "10.0.2.0/24"],
    )
    assert_array_equal(
        IPAddress.to_string_vec(IPAddress.summarize_str(["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/23"])),
        ["10.0.0.0/22"],
    )

    assert_array_equal(IPAddress.to_string_vec(IPAddress.summarize_str(["10.0.0.0/16", "10.0.2.0/24"])), ["10.0.0.0/16"])

    cnt = 10
    for _ in range(cnt):
        assert IPAddress.to_string_vec(IPAddress.summarize(ip_addresses)) == [
            "1.0.0.0/8",
            "2.0.0.0/7",
            "4.0.0.0/6",
            "8.0.0.0/7",
            "11.0.0.0/8",
            "12.0.0.0/6",
            "16.0.0.0/4",
            "32.0.0.0/3",
            "64.0.0.0/3",
            "96.0.0.0/4",
            "112.0.0.0/5",
            "120.0.0.0/6",
            "124.0.0.0/7",
            "126.0.0.0/8",
            "128.0.0.0/3",
            "160.0.0.0/5",
            "168.0.0.0/8",
            "169.0.0.0/9",
            "169.128.0.0/10",
            "169.192.0.0/11",
            "169.224.0.0/12",
            "169.240.0.0/13",
            "169.248.0.0/14",
            "169.252.0.0/15",
            "169.255.0.0/16",
            "170.0.0.0/7",
            "172.0.0.0/12",
            "172.32.0.0/11",
            "172.64.0.0/10",
            "172.128.0.0/9",
            "173.0.0.0/8",
            "174.0.0.0/7",
            "176.0.0.0/4",
            "192.0.0.0/9",
            "192.128.0.0/11",
            "192.160.0.0/13",
            "192.169.0.0/16",
            "192.170.0.0/15",
            "192.172.0.0/14",
            "192.176.0.0/12",
            "192.192.0.0/10",
            "193.0.0.0/8",
            "194.0.0.0/7",
            "196.0.0.0/6",
            "200.0.0.0/5",
            "208.0.0.0/4",
        ]

    # test immutable input parameters
    a1 = IPAddress.parse("10.0.0.1/24")
    a2 = IPAddress.parse("10.0.1.1/24")
    assert_array_equal(IPAddress.to_string_vec(IPAddress.summarize([a1.clone(), a2.clone()])), ["10.0.0.0/23"])
    assert "10.0.0.1/24" == a1.to_string()
    assert "10.0.1.1/24" == a2.to_string()
