using System;
using System.Numerics;
using System.Collections.Generic;
using NUnit.Framework;

namespace ipaddress.test
{

  class IPv6Test
  {
    public Dictionary<String, String> compress_addr = new Dictionary<String, String>();
    public Dictionary<String, BigInteger> valid_ipv6 = new Dictionary<String, BigInteger>();
    public List<String> invalid_ipv6;
    public Dictionary<String, String> networks = new Dictionary<String, String>();
    public List<int> arr;
    public IPAddress ip;
    public IPAddress network;
    public String hex;

    public IPv6Test(List<String> invalid_ipv6, IPAddress ip, IPAddress net, String hex, List<int> arr)
    {
      this.invalid_ipv6 = invalid_ipv6;
      this.ip = ip;
      this.network = net;
      this.hex = hex;
      this.arr = arr;
    }
  }

  class TestIpv6 {


  IPv6Test setup() {
      var ip6t = new IPv6Test(new List<string> { ":1:2:3:4:5:6:7", ":1:2:3:4:5:6:7", "2002:516:2:200", "dd" },
      IPAddress.parse("2001:db8::8:800:200c:417a/64").unwrap(), IPAddress.parse("2001:db8:8:800::/64").unwrap(),
                              "20010db80000000000080800200c417a", new List<int> { 8193, 3512, 0, 0, 8, 2048, 8204, 16762 });

    ip6t.compress_addr.Add("2001:db8:0000:0000:0008:0800:200c:417a", "2001:db8::8:800:200c:417a");
    ip6t.compress_addr.Add("2001:db8:0:0:8:800:200c:417a", "2001:db8::8:800:200c:417a");
    ip6t.compress_addr.Add("ff01:0:0:0:0:0:0:101", "ff01::101");
    ip6t.compress_addr.Add("0:0:0:0:0:0:0:1", "::1");
    ip6t.compress_addr.Add("0:0:0:0:0:0:0:0", "::");

    ip6t.valid_ipv6.Add("FEDC:BA98:7654:3210:FEDC:BA98:7654:3210",
      BigInteger.Parse("338770000845734292534325025077361652240"));
    ip6t.valid_ipv6.Add("1080:0000:0000:0000:0008:0800:200C:417A",
      BigInteger.Parse("21932261930451111902915077091070067066"));
    ip6t.valid_ipv6.Add("1080:0:0:0:8:800:200C:417A", BigInteger.Parse("21932261930451111902915077091070067066"));
    ip6t.valid_ipv6.Add("1080:0::8:800:200C:417A", BigInteger.Parse("21932261930451111902915077091070067066"));
    ip6t.valid_ipv6.Add("1080::8:800:200C:417A", BigInteger.Parse("21932261930451111902915077091070067066"));
    ip6t.valid_ipv6.Add("FF01:0:0:0:0:0:0:43", BigInteger.Parse("338958331222012082418099330867817087043"));
    ip6t.valid_ipv6.Add("FF01:0:0::0:0:43", BigInteger.Parse("338958331222012082418099330867817087043"));
    ip6t.valid_ipv6.Add("FF01::43", BigInteger.Parse("338958331222012082418099330867817087043"));
    ip6t.valid_ipv6.Add("0:0:0:0:0:0:0:1", BigInteger.Parse("1"));
    ip6t.valid_ipv6.Add("0:0:0::0:0:1", BigInteger.Parse("1"));
    ip6t.valid_ipv6.Add("::1", BigInteger.Parse("1"));
    ip6t.valid_ipv6.Add("0:0:0:0:0:0:0:0", BigInteger.Parse("0"));
    ip6t.valid_ipv6.Add("0:0:0::0:0:0", BigInteger.Parse("0"));
    ip6t.valid_ipv6.Add("::", BigInteger.Parse("0"));
    ip6t.valid_ipv6.Add("::/0", BigInteger.Parse("0"));
    ip6t.valid_ipv6.Add("1080:0:0:0:8:800:200C:417A", BigInteger.Parse("21932261930451111902915077091070067066"));
    ip6t.valid_ipv6.Add("1080::8:800:200C:417A", BigInteger.Parse("21932261930451111902915077091070067066"));

    ip6t.networks.Add("2001:db8:1:1:1:1:1:1/32", "2001:db8::/32");
    ip6t.networks.Add("2001:db8:1:1:1:1:1::/32", "2001:db8::/32");
    ip6t.networks.Add("2001:db8::1/64", "2001:db8::/64");
    return ip6t;
  }

  [Test]
  void test_attribute_address() {
    var addr = "2001:0db8:0000:0000:0008:0800:200c:417a";
    Assert.AreEqual(addr, setup().ip.to_s_uncompressed());
  }

  [Test]
  void test_initialize() {
    Assert.AreEqual(false, setup().ip.is_ipv4());

      foreach (var kp in setup().valid_ipv6)
      {
        var ip = kp.Key;
        Assert.AreEqual(true, IPAddress.parse(ip).isOk());
      }
      foreach (var ip in setup().invalid_ipv6)
      {
        Assert.AreEqual(true, IPAddress.parse(ip).isErr());
      } 
    Assert.AreEqual(64, setup().ip.prefix.num);

    Assert.AreEqual(false, IPAddress.parse("::10.1.1.1").isErr());
  }

  [Test]
  void test_attribute_groups() {
      Assert.AreEqual(setup().arr, setup().ip.parts());
  }

  [Test]
  public void test_method_hexs() {
      Assert.AreEqual(setup().ip.parts_hex_str(), new List<String> { "2001", "0db8", "0000", "0000", "0008", "0800", "200c", "417a" });
  }

  [Test]
  public void test_method_to_i() {
      foreach (var kp in setup().valid_ipv6)
      {
        var ip = kp.Key;
        var num = kp.Value;
        Assert.AreEqual(num, IPAddress.parse(ip).unwrap().host_address);
      } 
  }

  // [Test]
  // public void test_method_bits() {
  // var bits = "0010000000000001000011011011100000000000000000000" +
  // "000000000000000000000000000100000001000000000000010000" +
  // "0000011000100000101111010";
  // Assert.AreEqual(bits, setup().ip.host_address.to_str_radix(2));
  // }
  [Test]
  public void test_method_set_prefix() {
    var ip = IPAddress.parse("2001:db8::8:800:200c:417a").unwrap();
    Assert.AreEqual(128, ip.prefix.num);
    Assert.AreEqual("2001:db8::8:800:200c:417a/128", ip.to_string());
    var nip = ip.change_prefix(64).unwrap();
    Assert.AreEqual(64, nip.prefix.num);
    Assert.AreEqual("2001:db8::8:800:200c:417a/64", nip.to_string());
  }

  [Test]
  public void test_method_mapped() {
    Assert.AreEqual(false, setup().ip.is_mapped());
    var ip6 = IPAddress.parse("::ffff:1234:5678").unwrap();
    Assert.AreEqual(true, ip6.is_mapped());
  }

  // [Test]
  // public void test_method_literal() {
  // var str = "2001-0db8-0000-0000-0008-0800-200c-417a.ipv6-literal.net";
  // Assert.AreEqual(str, setup().ip.literal());
  // }
  [Test]
  public void test_method_group() {
    var s = setup();
    Assert.AreEqual(s.ip.parts(), s.arr);
  }

  [Test]
  public void test_method_ipv4() {
    Assert.AreEqual(false, setup().ip.is_ipv4());
  }

  [Test]
  public void test_method_ipv6() {
    Assert.AreEqual(true, setup().ip.is_ipv6());
  }

  [Test]
  public void test_method_network_known() {
    Assert.AreEqual(true, setup().network.is_network());
    Assert.AreEqual(false, setup().ip.is_network());
  }

  [Test]
  public void test_method_network_u128() {
      Assert.AreEqual(IpV6.from_int(BigInteger.Parse("42540766411282592856903984951653826560"), 64).unwrap(),
      setup().ip.network());
  }

  [Test]
  public void test_method_broadcast_u128() {
      Assert.AreEqual(IpV6.from_int(BigInteger.Parse("42540766411282592875350729025363378175"), 64).unwrap(),
      setup().ip.broadcast());
  }

  [Test]
  public void test_method_size() {
    var ip = IPAddress.parse("2001:db8::8:800:200c:417a/64").unwrap();
      Assert.AreEqual(new BigInteger(1) <<(64), ip.size());
    ip = IPAddress.parse("2001:db8::8:800:200c:417a/32").unwrap();
    Assert.AreEqual(new BigInteger(1) <<(96), ip.size());
    ip = IPAddress.parse("2001:db8::8:800:200c:417a/120").unwrap();
    Assert.AreEqual(new BigInteger(1) <<(8), ip.size());
    ip = IPAddress.parse("2001:db8::8:800:200c:417a/124").unwrap();
    Assert.AreEqual(new BigInteger(1) <<(4), ip.size());
  }

  [Test]
  public void test_method_includes() {
    var ip = setup().ip;
    Assert.AreEqual(true, ip.includes(ip));
    // test prefix on same address
    var included = IPAddress.parse("2001:db8::8:800:200c:417a/128").unwrap();
    var not_included = IPAddress.parse("2001:db8::8:800:200c:417a/46").unwrap();
    Assert.AreEqual(true, ip.includes(included));
    Assert.AreEqual(false, ip.includes(not_included));
    // test address on same prefix
    included = IPAddress.parse("2001:db8::8:800:200c:0/64").unwrap();
    not_included = IPAddress.parse("2001:db8:1::8:800:200c:417a/64").unwrap();
    Assert.AreEqual(true, ip.includes(included));
    Assert.AreEqual(false, ip.includes(not_included));
    // general test
    included = IPAddress.parse("2001:db8::8:800:200c:1/128").unwrap();
    not_included = IPAddress.parse("2001:db8:1::8:800:200c:417a/76").unwrap();
    Assert.AreEqual(true, ip.includes(included));
    Assert.AreEqual(false, ip.includes(not_included));
  }

  [Test]
  public void test_method_to_hex() {
    Assert.AreEqual(setup().hex, setup().ip.to_hex());
  }

  [Test]
  public void test_method_to_s() {
    Assert.AreEqual("2001:db8::8:800:200c:417a", setup().ip.to_s());
  }

  [Test]
  public void test_method_to_string() {
    Assert.AreEqual("2001:db8::8:800:200c:417a/64", setup().ip.to_string());
  }

  [Test]
  public void test_method_to_string_uncompressed() {
    var str = "2001:0db8:0000:0000:0008:0800:200c:417a/64";
    Assert.AreEqual(str, setup().ip.to_string_uncompressed());
  }

  [Test]
  public void test_method_reverse() {
    var str = "f.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.2.0.0.0.5.0.5.0.e.f.f.3.ip6.arpa";
    Assert.AreEqual(str, IPAddress.parse("3ffe:505:2::f").unwrap().dns_reverse());
  }

  [Test]
  public void test_method_dns_rev_domains() {
      Assert.AreEqual(IPAddress.parse("f000:f100::/3").unwrap().dns_rev_domains(), new List<String> { "e.ip6.arpa", "f.ip6.arpa" });
    Assert.AreEqual(IPAddress.parse("fea3:f120::/15").unwrap().dns_rev_domains(),
                    new List<String> { "2.a.e.f.ip6.arpa", "3.a.e.f.ip6.arpa" });
    Assert.AreEqual(IPAddress.parse("3a03:2f80:f::/48").unwrap().dns_rev_domains(),
                    new List<String> { "f.0.0.0.0.8.f.2.3.0.a.3.ip6.arpa" });

    Assert.AreEqual(IPAddress.parse("f000:f100::1234/125").unwrap().dns_rev_domains(),
      new List<String>
      {
        "0.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
        "1.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
        "2.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
        "3.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
        "4.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
        "5.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
        "6.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
            "7.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa" });
    }

    [Test]
    public void test_method_compressed() {
      Assert.AreEqual("1:1:1::1", IPAddress.parse("1:1:1:0:0:0:0:1").unwrap().to_s());
      Assert.AreEqual("1:0:1::1", IPAddress.parse("1:0:1:0:0:0:0:1").unwrap().to_s());
      Assert.AreEqual("1::1:1:1:2:3:1", IPAddress.parse("1:0:1:1:1:2:3:1").unwrap().to_s());
      Assert.AreEqual("1::1:1:0:2:3:1", IPAddress.parse("1:0:1:1::2:3:1").unwrap().to_s());
      Assert.AreEqual("1:0:0:1::1", IPAddress.parse("1:0:0:1:0:0:0:1").unwrap().to_s());
      Assert.AreEqual("1::1:0:0:1", IPAddress.parse("1:0:0:0:1:0:0:1").unwrap().to_s());
      Assert.AreEqual("1::1", IPAddress.parse("1:0:0:0:0:0:0:1").unwrap().to_s());
    // Assert.AreEqual("1:1::1:2:0:0:1", IPAddress.parse("1:1:0:1:2::1").unwrap().to_s
    }

    [Test]
    public void test_method_unspecified() {
      Assert.AreEqual(true, IPAddress.parse("::").unwrap().is_unspecified());
      Assert.AreEqual(false, setup().ip.is_unspecified());
    }

    [Test]
    public void test_method_loopback() {
      Assert.AreEqual(true, IPAddress.parse("::1").unwrap().is_loopback());
      Assert.AreEqual(false, setup().ip.is_loopback());
    }

    [Test]
    public void test_method_network()
    {
      foreach (var kp in setup().networks) {
        var addr = kp.Key;
        var net = kp.Value;
        var ip = IPAddress.parse(addr).unwrap();
      Assert.AreEqual(net, ip.network().to_string());
    } 
    }

    [Test]
    public void test_method_each()
    {
      var ip = IPAddress.parse("2001:db8::4/125").unwrap();
      var arr = new List<String>();
      ip.each(i => arr.Add(i.to_s()) ) ;
      Assert.AreEqual(arr,
                      new List<String> {"2001:db8::", "2001:db8::1", "2001:db8::2", "2001:db8::3", "2001:db8::4", "2001:db8::5", "2001:db8::6",
        "2001:db8::7"});
    }

    [Test]
    public void test_method_each_net() {
      var test_addrs = new List<String> {"0000:0000:0000:0000:0000:0000:0000:0000", "1111:1111:1111:1111:1111:1111:1111:1111",
        "2222:2222:2222:2222:2222:2222:2222:2222", "3333:3333:3333:3333:3333:3333:3333:3333",
        "4444:4444:4444:4444:4444:4444:4444:4444", "5555:5555:5555:5555:5555:5555:5555:5555",
        "6666:6666:6666:6666:6666:6666:6666:6666", "7777:7777:7777:7777:7777:7777:7777:7777",
        "8888:8888:8888:8888:8888:8888:8888:8888", "9999:9999:9999:9999:9999:9999:9999:9999",
        "aaaa:aaaa:aaaa:aaaa:aaaa:aaaa:aaaa:aaaa", "bbbb:bbbb:bbbb:bbbb:bbbb:bbbb:bbbb:bbbb",
        "cccc:cccc:cccc:cccc:cccc:cccc:cccc:cccc", "dddd:dddd:dddd:dddd:dddd:dddd:dddd:dddd",
        "eeee:eeee:eeee:eeee:eeee:eeee:eeee:eeee", "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff"};
      for (var prefix = 0; prefix < 128; prefix++) {
        var nr_networks = 1 << ((128 - prefix) % 4);
        foreach (var adr in test_addrs) {
          var net_adr = IPAddress.parse(string.Format("%s/%d", adr, prefix)).unwrap();
          var ret = net_adr.dns_networks();
          Assert.AreEqual(ret[0].prefix.num % 4, 0);
          Assert.AreEqual(ret.Count, nr_networks);
          Assert.AreEqual(net_adr.network().to_s(), ret[0].network().to_s());
          Assert.AreEqual(net_adr.broadcast().to_s(), ret[ret.Count - 1].broadcast().to_s());
        // puts "//{adr}///{prefix} //{nr_networks} //{ret}"
        }
      }
      var ret0 = IPAddress.to_string_vec(IPAddress.parse("fd01:db8::4/3").unwrap().dns_networks());
      Assert.AreEqual(ret0, new List<String> {"e000::/4", "f000::/4" });
      var ret1 = IPAddress.to_string_vec(IPAddress.parse("3a03:2f80:f::/48").unwrap().dns_networks());
                              Assert.AreEqual(ret1, new List<String> {"3a03:2f80:f::/48" });
    }

    [Test]
    public void test_method_compare() {
      var ip1 = IPAddress.parse("2001:db8:1::1/64").unwrap();
      var ip2 = IPAddress.parse("2001:db8:2::1/64").unwrap();
      var ip3 = IPAddress.parse("2001:db8:1::2/64").unwrap();
      var ip4 = IPAddress.parse("2001:db8:1::1/65").unwrap();

      // ip2 should be greater than ip1
      Assert.AreEqual(true, ip2.gt(ip1));
      Assert.AreEqual(false, ip1.gt(ip2));
      Assert.AreEqual(false, ip2.lt(ip1));
      // ip3 should be less than ip2
      Assert.AreEqual(true, ip2.gt(ip3));
      Assert.AreEqual(false, ip2.lt(ip3));
      // ip1 should be less than ip3
      Assert.AreEqual(true, ip1.lt(ip3));
      Assert.AreEqual(false, ip1.gt(ip3));
      Assert.AreEqual(false, ip3.lt(ip1));
      // ip1 should be equal to itself
      Assert.AreEqual(true, ip1.equal(ip1));
      // ip4 should be greater than ip1
      Assert.AreEqual(true, ip1.lt(ip4));
      Assert.AreEqual(false, ip1.gt(ip4));
      // test sorting
      var r = IPAddress.to_string_vec(IPAddress.sort(new List<IPAddress> { ip1, ip2, ip3, ip4 }));
      Assert.AreEqual(r, new List<String> { "2001:db8:1::1/64", "2001:db8:1::1/65", "2001:db8:1::2/64", "2001:db8:2::1/64" });
    }

    // public void test_classmethod_expand() {
    // var compressed = "2001:db8:0:cd30::";
    // var expanded = "2001:0db8:0000:cd30:0000:0000:0000:0000";
    // Assert.AreEqual(expanded, @klass.expand(compressed));
    // Assert.AreEqual(expanded, @klass.expand("2001:0db8:0::cd3"));
    // Assert.AreEqual(expanded, @klass.expand("2001:0db8::cd30"));
    // Assert.AreEqual(expanded, @klass.expand("2001:0db8::cd3"));
    // }
    [Test]
    public void test_classmethod_compress() {
      var compressed = "2001:db8:0:cd30::";
      var expanded = "2001:0db8:0000:cd30:0000:0000:0000:0000";
      Assert.AreEqual(compressed, IPAddress.parse(expanded).unwrap().to_s());
      Assert.AreEqual("2001:db8::cd3", IPAddress.parse("2001:0db8:0::cd3").unwrap().to_s());
      Assert.AreEqual("2001:db8::cd30", IPAddress.parse("2001:0db8::cd30").unwrap().to_s());
      Assert.AreEqual("2001:db8::cd3", IPAddress.parse("2001:0db8::cd3").unwrap().to_s());
    }

    [Test]
    public void test_classhmethod_parse_u128() {
      foreach (var kp in setup().valid_ipv6)
      {
        var ip = kp.Key;
        var num = kp.Value;
        // println!(">>>{}==={}", ip, num);
        Assert.AreEqual(IPAddress.parse(ip).unwrap().to_s(), IpV6.from_int(num, 128).unwrap().to_s());
      } 
    }

    [Test]
    public void test_classmethod_parse_hex() {
      Assert.AreEqual(setup().ip.to_string(), IpV6.from_str(setup().hex, 16, 64).unwrap().to_string());
    }
  }
  
}
