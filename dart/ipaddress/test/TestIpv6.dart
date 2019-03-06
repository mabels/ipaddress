import 'package:test/test.dart';

  import '../IPAddress.dart';
import '../IpV6.dart';

class IPv6Test {
    Map<String, String> compress_addr = Map<String, String>();
    Map<String, BigInt> valid_ipv6 = Map<String, BigInt>();
    List<String> invalid_ipv6;
    Map<String, String> networks = Map<String, String>();
    List<int> arr;
    IPAddress ip;
    IPAddress network;
    String hex;

    IPv6Test(List<String> invalid_ipv6, IPAddress ip, IPAddress net, String hex, List<int> arr) {
      this.invalid_ipv6 = invalid_ipv6;
      this.ip = ip;
      this.network = net;
      this.hex = hex;
      this.arr = arr;
    }
  }

  IPv6Test setup() {
    final ip6t = IPv6Test([":1:2:3:4:5:6:7", ":1:2:3:4:5:6:7", "2002:516:2:200", "dd"],
      IPAddress.parse("2001:db8::8:800:200c:417a/64").unwrap(), IPAddress.parse("2001:db8:8:800::/64").unwrap(),
      "20010db80000000000080800200c417a", [8193, 3512, 0, 0, 8, 2048, 8204, 16762]);

    ip6t.compress_addr["2001:db8:0000:0000:0008:0800:200c:417a"] = "2001:db8::8:800:200c:417a";
    ip6t.compress_addr["2001:db8:0:0:8:800:200c:417a"] = "2001:db8::8:800:200c:417a";
    ip6t.compress_addr["ff01:0:0:0:0:0:0:101"] = "ff01::101";
    ip6t.compress_addr["0:0:0:0:0:0:0:1"] = "::1";
    ip6t.compress_addr["0:0:0:0:0:0:0:0"] = "::";

    ip6t.valid_ipv6["FEDC:BA98:7654:3210:FEDC:BA98:7654:3210"] =
      BigInt.parse(("338770000845734292534325025077361652240"));
    ip6t.valid_ipv6["1080:0000:0000:0000:0008:0800:200C:417A"] =
      BigInt.parse(("21932261930451111902915077091070067066"));
    ip6t.valid_ipv6["1080:0:0:0:8:800:200C:417A"] = BigInt.parse(("21932261930451111902915077091070067066"));
    ip6t.valid_ipv6["1080:0::8:800:200C:417A"] = BigInt.parse(("21932261930451111902915077091070067066"));
    ip6t.valid_ipv6["1080::8:800:200C:417A"] = BigInt.parse(("21932261930451111902915077091070067066"));
    ip6t.valid_ipv6["FF01:0:0:0:0:0:0:43"] = BigInt.parse(("338958331222012082418099330867817087043"));
    ip6t.valid_ipv6["FF01:0:0::0:0:43"] = BigInt.parse(("338958331222012082418099330867817087043"));
    ip6t.valid_ipv6["FF01::43"] = BigInt.parse(("338958331222012082418099330867817087043"));
    ip6t.valid_ipv6["0:0:0:0:0:0:0:1"] = BigInt.parse(("1"));
    ip6t.valid_ipv6["0:0:0::0:0:1"] = BigInt.parse(("1"));
    ip6t.valid_ipv6["::1"] = BigInt.parse(("1"));
    ip6t.valid_ipv6["0:0:0:0:0:0:0:0"] = BigInt.parse(("0"));
    ip6t.valid_ipv6["0:0:0::0:0:0"] = BigInt.parse(("0"));
    ip6t.valid_ipv6["::"] = BigInt.parse(("0"));
    ip6t.valid_ipv6["::/0"] = BigInt.parse(("0"));
    ip6t.valid_ipv6["1080:0:0:0:8:800:200C:417A"] = BigInt.parse(("21932261930451111902915077091070067066"));
    ip6t.valid_ipv6["1080::8:800:200C:417A"] = BigInt.parse(("21932261930451111902915077091070067066"));

    ip6t.networks["2001:db8:1:1:1:1:1:1/32"] = "2001:db8::/32";
    ip6t.networks["2001:db8:1:1:1:1:1::/32"] = "2001:db8::/32";
    ip6t.networks["2001:db8::1/64"] = "2001:db8::/64";
    return ip6t;
  }

void main() {
  test("test_attribute_address", () {
    final addr = "2001:0db8:0000:0000:0008:0800:200c:417a";
    expect(addr, setup().ip.to_s_uncompressed());
  });

  test("test_initialize", () {
    expect(false, setup().ip.is_ipv4());

    setup().valid_ipv6.forEach((ip, x) => expect(true, IPAddress.parse(ip).isOk()));
    setup().invalid_ipv6.forEach((ip) => expect(true, IPAddress.parse(ip).isErr()));
    expect(64, setup().ip.prefix.num);

    expect(false, IPAddress.parse("::10.1.1.1").isErr());
  });

  test("def test_attribute_groups", () {
    final _setup = setup();
    expect(_setup.arr, _setup.ip.parts());
  });

  test("test_method_hexs", () {
    expect(setup().ip.parts_hex_str(), ["2001", "0db8", "0000", "0000", "0008", "0800", "200c", "417a"]);
  });

  test("test_method_to_i", () {
    setup().valid_ipv6.forEach((ip, num) =>
      expect(num, IPAddress.parse(ip).unwrap().host_address));
  });

  // 
  // test_method_bits() {
  // final bits = "0010000000000001000011011011100000000000000000000" +
  // "000000000000000000000000000100000001000000000000010000" +
  // "0000011000100000101111010";
  // expect(bits, setup().ip.host_address.to_str_radix(2));
  // }
  test("test_method_set_prefix", () {
    final ip = IPAddress.parse("2001:db8::8:800:200c:417a").unwrap();
    expect(128, ip.prefix.num);
    expect("2001:db8::8:800:200c:417a/128", ip.to_string());
    final nip = ip.change_prefix_int(64).unwrap();
    expect(64, nip.prefix.num);
    expect("2001:db8::8:800:200c:417a/64", nip.to_string());
  });

  test("test_method_mapped", () {
    expect(false, setup().ip.is_mapped());
    final ip6 = IPAddress.parse("::ffff:1234:5678").unwrap();
    expect(true, ip6.is_mapped());
  });

  // 
  // test_method_literal() {
  // final str = "2001-0db8-0000-0000-0008-0800-200c-417a.ipv6-literal.net";
  // expect(str, setup().ip.literal());
  // }
  test("test_method_group", () {
    final s = setup();
    expect(s.ip.parts(), s.arr);
  });

  test("test_method_ipv4", () {
    expect(false, setup().ip.is_ipv4());
  });

  test("test_method_ipv6", () {
    expect(true, setup().ip.is_ipv6());
  });

  test("test_method_network_known", () {
    expect(true, setup().network.is_network());
    expect(false, setup().ip.is_network());
  });

  test("test_method_network_u128", () {
    expect(IpV6.from_int(
      BigInt.parse("42540766411282592856903984951653826560"), 64).unwrap(),
      setup().ip.network());
  });

  test("test_method_broadcast_u128", () {
    expect(IpV6.from_int(BigInt.parse("42540766411282592875350729025363378175"), 64).unwrap(),
      setup().ip.broadcast());
  });

  test("test_method_size", () {
    var ip = IPAddress.parse("2001:db8::8:800:200c:417a/64").unwrap();
    expect(BigInt.from(1) << 64, ip.size());
    ip = IPAddress.parse("2001:db8::8:800:200c:417a/32").unwrap();
    expect(BigInt.from(1) << 96, ip.size());
    ip = IPAddress.parse("2001:db8::8:800:200c:417a/120").unwrap();
    expect(BigInt.from(1) << 8, ip.size());
    ip = IPAddress.parse("2001:db8::8:800:200c:417a/124").unwrap();
    expect(BigInt.from(1) << 4, ip.size());
  });

  test("test_method_includes", () {
    final ip = setup().ip;
    expect(true, ip.includes(ip));
    // test prefix on same address
    var included = IPAddress.parse("2001:db8::8:800:200c:417a/128").unwrap();
    var not_included = IPAddress.parse("2001:db8::8:800:200c:417a/46").unwrap();
    expect(true, ip.includes(included));
    expect(false, ip.includes(not_included));
    // test address on same prefix
    included = IPAddress.parse("2001:db8::8:800:200c:0/64").unwrap();
    not_included = IPAddress.parse("2001:db8:1::8:800:200c:417a/64").unwrap();
    expect(true, ip.includes(included));
    expect(false, ip.includes(not_included));
    // general test
    included = IPAddress.parse("2001:db8::8:800:200c:1/128").unwrap();
    not_included = IPAddress.parse("2001:db8:1::8:800:200c:417a/76").unwrap();
    expect(true, ip.includes(included));
    expect(false, ip.includes(not_included));
  });

  test("test_method_to_hex", () {
    expect(setup().hex, setup().ip.to_hex());
  });

  test("test_method_to_s", () {
    expect("2001:db8::8:800:200c:417a", setup().ip.to_s());
  });

  test("test_method_to_string", () {
    expect("2001:db8::8:800:200c:417a/64", setup().ip.to_string());
  });

  test("test_method_to_string_uncompressed", () {
    final str = "2001:0db8:0000:0000:0008:0800:200c:417a/64";
    expect(str, setup().ip.to_string_uncompressed());
  });

  test("test_method_reverse", () {
    final str = "f.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.2.0.0.0.5.0.5.0.e.f.f.3.ip6.arpa";
    expect(str, IPAddress.parse("3ffe:505:2::f").unwrap().dns_reverse());
  });

  test("test_method_dns_rev_domains", () {
    expect(IPAddress.parse("f000:f100::/3").unwrap().dns_rev_domains(), ["e.ip6.arpa", "f.ip6.arpa"]);
    expect(IPAddress.parse("fea3:f120::/15").unwrap().dns_rev_domains(),
      ["2.a.e.f.ip6.arpa", "3.a.e.f.ip6.arpa"]);
    expect(IPAddress.parse("3a03:2f80:f::/48").unwrap().dns_rev_domains(),
      ["f.0.0.0.0.8.f.2.3.0.a.3.ip6.arpa"]);

    expect(IPAddress.parse("f000:f100::1234/125").unwrap().dns_rev_domains(),
      ["0.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
        "1.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
        "2.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
        "3.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
        "4.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
        "5.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
        "6.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
        "7.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa"]);
    });

    test("test_method_compressed", () {
      expect("1:1:1::1", IPAddress.parse("1:1:1:0:0:0:0:1").unwrap().to_s());
      expect("1:0:1::1", IPAddress.parse("1:0:1:0:0:0:0:1").unwrap().to_s());
      expect("1::1:1:1:2:3:1", IPAddress.parse("1:0:1:1:1:2:3:1").unwrap().to_s());
      expect("1::1:1:0:2:3:1", IPAddress.parse("1:0:1:1::2:3:1").unwrap().to_s());
      expect("1:0:0:1::1", IPAddress.parse("1:0:0:1:0:0:0:1").unwrap().to_s());
      expect("1::1:0:0:1", IPAddress.parse("1:0:0:0:1:0:0:1").unwrap().to_s());
      expect("1::1", IPAddress.parse("1:0:0:0:0:0:0:1").unwrap().to_s());
    // expect("1:1::1:2:0:0:1", IPAddress.parse("1:1:0:1:2::1").unwrap().to_s
    });

    test("test_method_unspecified", () {
      expect(true, IPAddress.parse("::").unwrap().is_unspecified());
      expect(false, setup().ip.is_unspecified());
    });

    test("test_method_loopback", () {
      expect(true, IPAddress.parse("::1").unwrap().is_loopback());
      expect(false, setup().ip.is_loopback());
    });

    test("test_method_network", () {
      setup().networks.forEach((addr, net) {
        final ip = IPAddress.parse(addr).unwrap();
        expect(net, ip.network().to_string());
      });
    });

    test("test_method_each", () {
      final ip = IPAddress.parse("2001:db8::4/125").unwrap();
      final arr = List<String>();
      ip.each((i) => arr.add(i.to_s()));
      expect(arr,
        ["2001:db8::", "2001:db8::1", "2001:db8::2", "2001:db8::3", "2001:db8::4", "2001:db8::5", "2001:db8::6",
          "2001:db8::7"]);
    });

    test("test_method_each_net", () {
      final test_addrs = ["0000:0000:0000:0000:0000:0000:0000:0000", "1111:1111:1111:1111:1111:1111:1111:1111",
        "2222:2222:2222:2222:2222:2222:2222:2222", "3333:3333:3333:3333:3333:3333:3333:3333",
        "4444:4444:4444:4444:4444:4444:4444:4444", "5555:5555:5555:5555:5555:5555:5555:5555",
        "6666:6666:6666:6666:6666:6666:6666:6666", "7777:7777:7777:7777:7777:7777:7777:7777",
        "8888:8888:8888:8888:8888:8888:8888:8888", "9999:9999:9999:9999:9999:9999:9999:9999",
        "aaaa:aaaa:aaaa:aaaa:aaaa:aaaa:aaaa:aaaa", "bbbb:bbbb:bbbb:bbbb:bbbb:bbbb:bbbb:bbbb",
        "cccc:cccc:cccc:cccc:cccc:cccc:cccc:cccc", "dddd:dddd:dddd:dddd:dddd:dddd:dddd:dddd",
        "eeee:eeee:eeee:eeee:eeee:eeee:eeee:eeee", "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff"];
      for (var prefix = 0; prefix < 128; prefix++) {
        final nr_networks = 1 << ((128 - prefix) % 4);
        for (var adr in test_addrs) {
          final net_adr = IPAddress.parse("${adr}/${prefix}").unwrap();
          final ret = net_adr.dns_networks();
          expect(ret[0].prefix.num % 4, 0);
          expect(ret.length, nr_networks);
          expect(net_adr.network().to_s(), ret[0].network().to_s());
          expect(net_adr.broadcast().to_s(), ret[ret.length - 1].broadcast().to_s());
        // puts "//{adr}///{prefix} //{nr_networks} //{ret}"
        }
      }
      var ret0 = IPAddress.parse("fd01:db8::4/3").unwrap().dns_networks().map((i) =>
        i.to_string()
      );
      expect(ret0, ["e000::/4", "f000::/4"]);
      var ret1 = IPAddress.parse("3a03:2f80:f::/48").unwrap().dns_networks().map((i) =>
        i.to_string()
      );
      expect(ret1, ["3a03:2f80:f::/48"]);
    });

    test("test_method_compare", () {
      final ip1 = IPAddress.parse("2001:db8:1::1/64").unwrap();
      final ip2 = IPAddress.parse("2001:db8:2::1/64").unwrap();
      final ip3 = IPAddress.parse("2001:db8:1::2/64").unwrap();
      final ip4 = IPAddress.parse("2001:db8:1::1/65").unwrap();

      // ip2 should be greater than ip1
      expect(true, ip2.gt(ip1));
      expect(false, ip1.gt(ip2));
      expect(false, ip2.lt(ip1));
      // ip3 should be less than ip2
      expect(true, ip2.gt(ip3));
      expect(false, ip2.lt(ip3));
      // ip1 should be less than ip3
      expect(true, ip1.lt(ip3));
      expect(false, ip1.gt(ip3));
      expect(false, ip3.lt(ip1));
      // ip1 should be equal to itself
      expect(true, ip1.equal(ip1));
      // ip4 should be greater than ip1
      expect(true, ip1.lt(ip4));
      expect(false, ip1.gt(ip4));
      // test sorting
      var r = IPAddress.sort([ip1, ip2, ip3, ip4]);
      var ret = r.map((i) => i.to_string());
      expect(ret, ["2001:db8:1::1/64", "2001:db8:1::1/65", "2001:db8:1::2/64", "2001:db8:2::1/64"]);
    });

    // test_classmethod_expand() {
    // final compressed = "2001:db8:0:cd30::";
    // final expanded = "2001:0db8:0000:cd30:0000:0000:0000:0000";
    // expect(expanded, @klass.expand(compressed));
    // expect(expanded, @klass.expand("2001:0db8:0::cd3"));
    // expect(expanded, @klass.expand("2001:0db8::cd30"));
    // expect(expanded, @klass.expand("2001:0db8::cd3"));
    // }
    
    test("test_classmethod_compress", () {
      final compressed = "2001:db8:0:cd30::";
      final expanded = "2001:0db8:0000:cd30:0000:0000:0000:0000";
      expect(compressed, IPAddress.parse(expanded).unwrap().to_s());
      expect("2001:db8::cd3", IPAddress.parse("2001:0db8:0::cd3").unwrap().to_s());
      expect("2001:db8::cd30", IPAddress.parse("2001:0db8::cd30").unwrap().to_s());
      expect("2001:db8::cd3", IPAddress.parse("2001:0db8::cd3").unwrap().to_s());
    });

    test("test_classhmethod_parse_u128", () {
      setup().valid_ipv6.forEach((ip, num) =>
        // println!(">>>{}==={}", ip, num);
        expect(IPAddress.parse(ip).unwrap().to_s(), IpV6.from_int(num, 128).unwrap().to_s())
      );
    });

    
    test("test_classmethod_parse_hex", () {
      expect(setup().ip.to_string(), IpV6.from_str(setup().hex, 16, 64).unwrap().to_string());
    });
  }
  
