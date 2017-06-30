using System;
using System.Numerics;
using System.Collections.Generic;

namespace ipaddress
{

class TestIpv6 {

  static class IPv6Test {
    public HashMap<String, String> compress_addr = new HashMap<String, String>()
    public HashMap<String, BigInteger> valid_ipv6 = new HashMap<String, BigInteger>()
    public List<String> invalid_ipv6
    public HashMap<String, String> networks = new HashMap<String, String>()
    public List<Integer> arr
    public IPAddress ip
    public IPAddress network
    public String hex

    new(List<String> invalid_ipv6, IPAddress ip, IPAddress net, String hex, List<Integer> arr) {
      this.invalid_ipv6 = invalid_ipv6
      this.ip = ip
      this.network = net
      this.hex = hex
      this.arr = arr
    }
  }

  def IPv6Test setup() {
    val ip6t = new IPv6Test(#[":1:2:3:4:5:6:7", ":1:2:3:4:5:6:7", "2002:516:2:200", "dd"],
      IPAddress.parse("2001:db8::8:800:200c:417a/64").unwrap(), IPAddress.parse("2001:db8:8:800::/64").unwrap(),
      "20010db80000000000080800200c417a", #[8193, 3512, 0, 0, 8, 2048, 8204, 16762]);

    ip6t.compress_addr.put("2001:db8:0000:0000:0008:0800:200c:417a", "2001:db8::8:800:200c:417a");
    ip6t.compress_addr.put("2001:db8:0:0:8:800:200c:417a", "2001:db8::8:800:200c:417a");
    ip6t.compress_addr.put("ff01:0:0:0:0:0:0:101", "ff01::101");
    ip6t.compress_addr.put("0:0:0:0:0:0:0:1", "::1");
    ip6t.compress_addr.put("0:0:0:0:0:0:0:0", "::");

    ip6t.valid_ipv6.put("FEDC:BA98:7654:3210:FEDC:BA98:7654:3210",
      new BigInteger("338770000845734292534325025077361652240"));
    ip6t.valid_ipv6.put("1080:0000:0000:0000:0008:0800:200C:417A",
      new BigInteger("21932261930451111902915077091070067066"));
    ip6t.valid_ipv6.put("1080:0:0:0:8:800:200C:417A", new BigInteger("21932261930451111902915077091070067066"));
    ip6t.valid_ipv6.put("1080:0::8:800:200C:417A", new BigInteger("21932261930451111902915077091070067066"));
    ip6t.valid_ipv6.put("1080::8:800:200C:417A", new BigInteger("21932261930451111902915077091070067066"));
    ip6t.valid_ipv6.put("FF01:0:0:0:0:0:0:43", new BigInteger("338958331222012082418099330867817087043"));
    ip6t.valid_ipv6.put("FF01:0:0::0:0:43", new BigInteger("338958331222012082418099330867817087043"));
    ip6t.valid_ipv6.put("FF01::43", new BigInteger("338958331222012082418099330867817087043"));
    ip6t.valid_ipv6.put("0:0:0:0:0:0:0:1", new BigInteger("1"));
    ip6t.valid_ipv6.put("0:0:0::0:0:1", new BigInteger("1"));
    ip6t.valid_ipv6.put("::1", new BigInteger("1"));
    ip6t.valid_ipv6.put("0:0:0:0:0:0:0:0", new BigInteger("0"));
    ip6t.valid_ipv6.put("0:0:0::0:0:0", new BigInteger("0"));
    ip6t.valid_ipv6.put("::", new BigInteger("0"));
    ip6t.valid_ipv6.put("::/0", new BigInteger("0"));
    ip6t.valid_ipv6.put("1080:0:0:0:8:800:200C:417A", new BigInteger("21932261930451111902915077091070067066"));
    ip6t.valid_ipv6.put("1080::8:800:200C:417A", new BigInteger("21932261930451111902915077091070067066"));

    ip6t.networks.put("2001:db8:1:1:1:1:1:1/32", "2001:db8::/32");
    ip6t.networks.put("2001:db8:1:1:1:1:1::/32", "2001:db8::/32");
    ip6t.networks.put("2001:db8::1/64", "2001:db8::/64");
    return ip6t;
  }

  @Test
  def test_attribute_address() {
    val addr = "2001:0db8:0000:0000:0008:0800:200c:417a";
    assertEquals(addr, setup().ip.to_s_uncompressed());
  }

  @Test
  def test_initialize() {
    assertEquals(false, setup().ip.is_ipv4());

    setup().valid_ipv6.forEach [ ip, x |
      assertEquals(true, IPAddress.parse(ip).isOk());
    ]
    setup().invalid_ipv6.forEach [ ip |
      assertEquals(true, IPAddress.parse(ip).isErr());
    ]
    assertEquals(64, setup().ip.prefix.num);

    assertEquals(false, IPAddress.parse("::10.1.1.1").isErr());
  }

  @Test
  def test_attribute_groups() {
    val setup = setup();
    assertArrayEquals(setup.arr, setup.ip.parts())
  }

  @Test
  public def test_method_hexs() {
    assertArrayEquals(setup().ip.parts_hex_str(), #["2001", "0db8", "0000", "0000", "0008", "0800", "200c", "417a"]);
  }

  @Test
  public def test_method_to_i() {
    setup().valid_ipv6.forEach [ ip, num |
      assertEquals(num, IPAddress.parse(ip).unwrap().host_address)
    ]
  }

  // @Test
  // public def test_method_bits() {
  // val bits = "0010000000000001000011011011100000000000000000000" +
  // "000000000000000000000000000100000001000000000000010000" +
  // "0000011000100000101111010";
  // assertEquals(bits, setup().ip.host_address.to_str_radix(2));
  // }
  @Test
  public def test_method_set_prefix() {
    val ip = IPAddress.parse("2001:db8::8:800:200c:417a").unwrap();
    assertEquals(128, ip.prefix.num);
    assertEquals("2001:db8::8:800:200c:417a/128", ip.to_string());
    val nip = ip.change_prefix(64).unwrap();
    assertEquals(64, nip.prefix.num);
    assertEquals("2001:db8::8:800:200c:417a/64", nip.to_string());
  }

  @Test
  public def test_method_mapped() {
    assertEquals(false, setup().ip.is_mapped());
    val ip6 = IPAddress.parse("::ffff:1234:5678").unwrap();
    assertEquals(true, ip6.is_mapped());
  }

  // @Test
  // public def test_method_literal() {
  // val str = "2001-0db8-0000-0000-0008-0800-200c-417a.ipv6-literal.net";
  // assertEquals(str, setup().ip.literal());
  // }
  @Test
  public def test_method_group() {
    val s = setup();
    assertArrayEquals(s.ip.parts(), s.arr);
  }

  @Test
  public def test_method_ipv4() {
    assertEquals(false, setup().ip.is_ipv4());
  }

  @Test
  public def test_method_ipv6() {
    assertEquals(true, setup().ip.is_ipv6());
  }

  @Test
  public def test_method_network_known() {
    assertEquals(true, setup().network.is_network());
    assertEquals(false, setup().ip.is_network());
  }

  @Test
  public def test_method_network_u128() {
    assertEquals(IpV6.from_int(new BigInteger("42540766411282592856903984951653826560"), 64).unwrap(),
      setup().ip.network());
  }

  @Test
  public def test_method_broadcast_u128() {
    assertEquals(IpV6.from_int(new BigInteger("42540766411282592875350729025363378175"), 64).unwrap(),
      setup().ip.broadcast());
  }

  @Test
  public def test_method_size() {
    var ip = IPAddress.parse("2001:db8::8:800:200c:417a/64").unwrap();
    assertEquals(BigInteger.ONE.shiftLeft(64), ip.size());
    ip = IPAddress.parse("2001:db8::8:800:200c:417a/32").unwrap();
    assertEquals(BigInteger.ONE.shiftLeft(96), ip.size());
    ip = IPAddress.parse("2001:db8::8:800:200c:417a/120").unwrap();
    assertEquals(BigInteger.ONE.shiftLeft(8), ip.size());
    ip = IPAddress.parse("2001:db8::8:800:200c:417a/124").unwrap();
    assertEquals(BigInteger.ONE.shiftLeft(4), ip.size());
  }

  @Test
  public def test_method_includes() {
    val ip = setup().ip;
    assertEquals(true, ip.includes(ip));
    // test prefix on same address
    var included = IPAddress.parse("2001:db8::8:800:200c:417a/128").unwrap();
    var not_included = IPAddress.parse("2001:db8::8:800:200c:417a/46").unwrap();
    assertEquals(true, ip.includes(included));
    assertEquals(false, ip.includes(not_included));
    // test address on same prefix
    included = IPAddress.parse("2001:db8::8:800:200c:0/64").unwrap();
    not_included = IPAddress.parse("2001:db8:1::8:800:200c:417a/64").unwrap();
    assertEquals(true, ip.includes(included));
    assertEquals(false, ip.includes(not_included));
    // general test
    included = IPAddress.parse("2001:db8::8:800:200c:1/128").unwrap();
    not_included = IPAddress.parse("2001:db8:1::8:800:200c:417a/76").unwrap();
    assertEquals(true, ip.includes(included));
    assertEquals(false, ip.includes(not_included));
  }

  @Test
  public def test_method_to_hex() {
    assertEquals(setup().hex, setup().ip.to_hex());
  }

  @Test
  public def test_method_to_s() {
    assertEquals("2001:db8::8:800:200c:417a", setup().ip.to_s());
  }

  @Test
  public def test_method_to_string() {
    assertEquals("2001:db8::8:800:200c:417a/64", setup().ip.to_string());
  }

  @Test
  public def test_method_to_string_uncompressed() {
    val str = "2001:0db8:0000:0000:0008:0800:200c:417a/64";
    assertEquals(str, setup().ip.to_string_uncompressed());
  }

  @Test
  public def test_method_reverse() {
    val str = "f.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.2.0.0.0.5.0.5.0.e.f.f.3.ip6.arpa";
    assertEquals(str, IPAddress.parse("3ffe:505:2::f").unwrap().dns_reverse());
  }

  @Test
  public def test_method_dns_rev_domains() {
    assertArrayEquals(IPAddress.parse("f000:f100::/3").unwrap().dns_rev_domains(), #["e.ip6.arpa", "f.ip6.arpa"]);
    assertArrayEquals(IPAddress.parse("fea3:f120::/15").unwrap().dns_rev_domains(),
      #["2.a.e.f.ip6.arpa", "3.a.e.f.ip6.arpa"]);
    assertArrayEquals(IPAddress.parse("3a03:2f80:f::/48").unwrap().dns_rev_domains(),
      #["f.0.0.0.0.8.f.2.3.0.a.3.ip6.arpa"]);

    assertArrayEquals(IPAddress.parse("f000:f100::1234/125").unwrap().dns_rev_domains(),
      #["0.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
        "1.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
        "2.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
        "3.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
        "4.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
        "5.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
        "6.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
        "7.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa"]);
    }

    @Test
    public def test_method_compressed() {
      assertEquals("1:1:1::1", IPAddress.parse("1:1:1:0:0:0:0:1").unwrap().to_s());
      assertEquals("1:0:1::1", IPAddress.parse("1:0:1:0:0:0:0:1").unwrap().to_s());
      assertEquals("1::1:1:1:2:3:1", IPAddress.parse("1:0:1:1:1:2:3:1").unwrap().to_s());
      assertEquals("1::1:1:0:2:3:1", IPAddress.parse("1:0:1:1::2:3:1").unwrap().to_s());
      assertEquals("1:0:0:1::1", IPAddress.parse("1:0:0:1:0:0:0:1").unwrap().to_s());
      assertEquals("1::1:0:0:1", IPAddress.parse("1:0:0:0:1:0:0:1").unwrap().to_s());
      assertEquals("1::1", IPAddress.parse("1:0:0:0:0:0:0:1").unwrap().to_s());
    // assertEquals("1:1::1:2:0:0:1", IPAddress.parse("1:1:0:1:2::1").unwrap().to_s
    }

    @Test
    public def test_method_unspecified() {
      assertEquals(true, IPAddress.parse("::").unwrap().is_unspecified());
      assertEquals(false, setup().ip.is_unspecified());
    }

    @Test
    public def test_method_loopback() {
      assertEquals(true, IPAddress.parse("::1").unwrap().is_loopback());
      assertEquals(false, setup().ip.is_loopback());
    }

    @Test
    public def test_method_network() {
      setup().networks.forEach [ addr, net |
        val ip = IPAddress.parse(addr).unwrap();
        assertEquals(net, ip.network().to_string());
      ]
    }

    @Test
    public def test_method_each() {
      val ip = IPAddress.parse("2001:db8::4/125").unwrap();
      val arr = new Vector<String>()
      ip.each[i|arr.add(i.to_s())];
      assertArrayEquals(arr,
        #["2001:db8::", "2001:db8::1", "2001:db8::2", "2001:db8::3", "2001:db8::4", "2001:db8::5", "2001:db8::6",
          "2001:db8::7"]);
    }

    @Test
    public def test_method_each_net() {
      val test_addrs = #["0000:0000:0000:0000:0000:0000:0000:0000", "1111:1111:1111:1111:1111:1111:1111:1111",
        "2222:2222:2222:2222:2222:2222:2222:2222", "3333:3333:3333:3333:3333:3333:3333:3333",
        "4444:4444:4444:4444:4444:4444:4444:4444", "5555:5555:5555:5555:5555:5555:5555:5555",
        "6666:6666:6666:6666:6666:6666:6666:6666", "7777:7777:7777:7777:7777:7777:7777:7777",
        "8888:8888:8888:8888:8888:8888:8888:8888", "9999:9999:9999:9999:9999:9999:9999:9999",
        "aaaa:aaaa:aaaa:aaaa:aaaa:aaaa:aaaa:aaaa", "bbbb:bbbb:bbbb:bbbb:bbbb:bbbb:bbbb:bbbb",
        "cccc:cccc:cccc:cccc:cccc:cccc:cccc:cccc", "dddd:dddd:dddd:dddd:dddd:dddd:dddd:dddd",
        "eeee:eeee:eeee:eeee:eeee:eeee:eeee:eeee", "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff"];
      for (var prefix = 0; prefix < 128; prefix++) {
        val nr_networks = 1 << ((128 - prefix) % 4);
        for (adr : test_addrs) {
          val net_adr = IPAddress.parse(String.format("%s/%d", adr, prefix)).unwrap();
          val ret = net_adr.dns_networks();
          assertEquals(ret.get(0).prefix.num % 4, 0);
          assertEquals(ret.length(), nr_networks);
          assertEquals(net_adr.network().to_s(), ret.get(0).network().to_s());
          assertEquals(net_adr.broadcast().to_s(), ret.get(ret.length - 1).broadcast().to_s());
        // puts "//{adr}///{prefix} //{nr_networks} //{ret}"
        }
      }
      var ret0 = IPAddress.parse("fd01:db8::4/3").unwrap().dns_networks().map [ i |
        i.to_string()
      ]
      assertArrayEquals(ret0, #["e000::/4", "f000::/4"]);
      var ret1 = IPAddress.parse("3a03:2f80:f::/48").unwrap().dns_networks().map [ i |
        i.to_string()
      ]
      assertArrayEquals(ret1, #["3a03:2f80:f::/48"]);
    }

    @Test
    public def test_method_compare() {
      val ip1 = IPAddress.parse("2001:db8:1::1/64").unwrap();
      val ip2 = IPAddress.parse("2001:db8:2::1/64").unwrap();
      val ip3 = IPAddress.parse("2001:db8:1::2/64").unwrap();
      val ip4 = IPAddress.parse("2001:db8:1::1/65").unwrap();

      // ip2 should be greater than ip1
      assertEquals(true, ip2.gt(ip1));
      assertEquals(false, ip1.gt(ip2));
      assertEquals(false, ip2.lt(ip1));
      // ip3 should be less than ip2
      assertEquals(true, ip2.gt(ip3));
      assertEquals(false, ip2.lt(ip3));
      // ip1 should be less than ip3
      assertEquals(true, ip1.lt(ip3));
      assertEquals(false, ip1.gt(ip3));
      assertEquals(false, ip3.lt(ip1));
      // ip1 should be equal to itself
      assertEquals(true, ip1.equal(ip1));
      // ip4 should be greater than ip1
      assertEquals(true, ip1.lt(ip4));
      assertEquals(false, ip1.gt(ip4));
      // test sorting
      var r = IPAddress.sort(#[ip1, ip2, ip3, ip4]);
      var ret = r.map[i|i.to_string()]
      assertArrayEquals(ret, #["2001:db8:1::1/64", "2001:db8:1::1/65", "2001:db8:1::2/64", "2001:db8:2::1/64"]);
    }

    // public def test_classmethod_expand() {
    // val compressed = "2001:db8:0:cd30::";
    // val expanded = "2001:0db8:0000:cd30:0000:0000:0000:0000";
    // assertEquals(expanded, @klass.expand(compressed));
    // assertEquals(expanded, @klass.expand("2001:0db8:0::cd3"));
    // assertEquals(expanded, @klass.expand("2001:0db8::cd30"));
    // assertEquals(expanded, @klass.expand("2001:0db8::cd3"));
    // }
    @Test
    public def test_classmethod_compress() {
      val compressed = "2001:db8:0:cd30::";
      val expanded = "2001:0db8:0000:cd30:0000:0000:0000:0000";
      assertEquals(compressed, IPAddress.parse(expanded).unwrap().to_s());
      assertEquals("2001:db8::cd3", IPAddress.parse("2001:0db8:0::cd3").unwrap().to_s());
      assertEquals("2001:db8::cd30", IPAddress.parse("2001:0db8::cd30").unwrap().to_s());
      assertEquals("2001:db8::cd3", IPAddress.parse("2001:0db8::cd3").unwrap().to_s());
    }

    @Test
    public def test_classhmethod_parse_u128() {
      setup().valid_ipv6.forEach [ ip, num |
        // println!(">>>{}==={}", ip, num);
        assertEquals(IPAddress.parse(ip).unwrap().to_s(), IpV6.from_int(num, 128).unwrap().to_s());
      ]
    }

    @Test
    public def test_classmethod_parse_hex() {
      assertEquals(setup().ip.to_string(), IpV6.from_str(setup().hex, 16, 64).unwrap().to_string());
    }
  }
  
}
