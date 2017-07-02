
using System;
using System.Numerics;
using System.Collections.Generic;
using NUnit.Framework;

namespace ipaddress
{

  class IPv4Prefix
  {
    public String ip;
    public int prefix;
    public IPv4Prefix(String ip, int prefix)
    {
      this.ip = ip;
      this.prefix = prefix;
    }

  }

  class IPv4Test
  {
    public Dictionary<String, IPv4Prefix> valid_ipv4 = new Dictionary<String, IPv4Prefix>();
    public List<String> invalid_ipv4;
    public List<String> valid_ipv4_range;
    public Dictionary<String, String> netmask_values = new Dictionary<String, String>();
    public Dictionary<String, UInt32> decimal_values = new Dictionary<String, UInt32>();
    public IPAddress ip;
    public IPAddress network;
    public Dictionary<String, String> networks = new Dictionary<String, String>();
    public Dictionary<String, String> broadcast = new Dictionary<String, String>();
    public IPAddress class_a;
    public IPAddress class_b;
    public IPAddress class_c;
    public Dictionary<String, UInt32> classful = new Dictionary<String, UInt32>();
    public IPv4Test(List<String> invalid_ipv4, List<String> valid_ipv4_range,
          IPAddress ip, IPAddress network, IPAddress class_a,
          IPAddress class_b, IPAddress class_c)
    {
      this.invalid_ipv4 = invalid_ipv4;
      this.valid_ipv4_range = valid_ipv4_range;
      this.ip = ip;
      this.network = network;
      this.class_a = class_a;
      this.class_b = class_b;
      this.class_c = class_c;
    }
  }


  class TestIpv4
  {

    static IPv4Test setup()
    {
      var ipv4t = new IPv4Test(
      new List<String> { "10.0.0.256", "10.0.0.0.0" },
      new List<String> { "10.0.0.1-254", "10.0.1-254.0", "10.1-254.0.0" },
          IpV4.create("172.16.10.1/24").unwrap(),
          IpV4.create("172.16.10.0/24").unwrap(),
          IpV4.create("10.0.0.1/8").unwrap(),
          IpV4.create("172.16.0.1/16").unwrap(),
          IpV4.create("192.168.0.1/24").unwrap());
      ipv4t.valid_ipv4.Add("9.9/17",
                              new IPv4Prefix(
                                  "9.0.0.9",
                                   17
                              ));
      ipv4t.valid_ipv4.Add("100.1.100",
                              new IPv4Prefix(
                                  "100.1.0.100",
                                   32
                              ));
      ipv4t.valid_ipv4.Add("0.0.0.0/0",
                              new IPv4Prefix(
                                  "0.0.0.0",
                                   0
                              ));
      ipv4t.valid_ipv4.Add("10.0.0.0",
                              new IPv4Prefix(
                                  "10.0.0.0",
                                   32
                              ));
      ipv4t.valid_ipv4.Add("10.0.0.1",
                              new IPv4Prefix(
                                  "10.0.0.1",
                                   32
                              ));
      ipv4t.valid_ipv4.Add("10.0.0.1/24",
                              new IPv4Prefix(
                                  "10.0.0.1",
                                   24
                              ));
      ipv4t.valid_ipv4.Add("10.0.0.9/255.255.255.0",
                              new IPv4Prefix(
                                  "10.0.0.9",
                                   24
                              ));

      ipv4t.netmask_values.Add("0.0.0.0/0", "0.0.0.0");
      ipv4t.netmask_values.Add("10.0.0.0/8", "255.0.0.0");
      ipv4t.netmask_values.Add("172.16.0.0/16", "255.255.0.0");
      ipv4t.netmask_values.Add("192.168.0.0/24", "255.255.255.0");
      ipv4t.netmask_values.Add("192.168.100.4/30", "255.255.255.252");

      ipv4t.decimal_values.Add("0.0.0.0/0", 0);
      ipv4t.decimal_values.Add("10.0.0.0/8", 167772160);
      ipv4t.decimal_values.Add("172.16.0.0/16", 2886729728);
      ipv4t.decimal_values.Add("192.168.0.0/24", 3232235520);
      ipv4t.decimal_values.Add("192.168.100.4/30", 3232261124);

      ipv4t.ip = IPAddress.parse("172.16.10.1/24").unwrap();
      ipv4t.network = IPAddress.parse("172.16.10.0/24").unwrap();

      ipv4t.broadcast.Add("10.0.0.0/8", "10.255.255.255/8");
      ipv4t.broadcast.Add("172.16.0.0/16", "172.16.255.255/16");
      ipv4t.broadcast.Add("192.168.0.0/24", "192.168.0.255/24");
      ipv4t.broadcast.Add("192.168.100.4/30", "192.168.100.7/30");

      ipv4t.networks.Add("10.5.4.3/8", "10.0.0.0/8");
      ipv4t.networks.Add("172.16.5.4/16", "172.16.0.0/16");
      ipv4t.networks.Add("192.168.4.3/24", "192.168.4.0/24");
      ipv4t.networks.Add("192.168.100.5/30", "192.168.100.4/30");

      ipv4t.class_a = IPAddress.parse("10.0.0.1/8").unwrap();
      ipv4t.class_b = IPAddress.parse("172.16.0.1/16").unwrap();
      ipv4t.class_c = IPAddress.parse("192.168.0.1/24").unwrap();

      ipv4t.classful.Add("10.1.1.1", 8);
      ipv4t.classful.Add("150.1.1.1", 16);
      ipv4t.classful.Add("200.1.1.1", 24);
      return ipv4t;
    }


    [Test]
    void test_initialize()
    {
      var s = setup();
      foreach (var kp in s.valid_ipv4)
      {
        var i = kp.Key;
        var x = kp.Value;
        var ip = IPAddress.parse(i).unwrap();
        Assert.IsTrue(ip.is_ipv4() && !ip.is_ipv6());
      }

      Assert.AreEqual(32, s.ip.prefix.ip_bits.bits);
      Assert.IsTrue(IPAddress.parse("1.f.13.1/-3").isErr());
      Assert.IsTrue(IPAddress.parse("10.0.0.0/8").isOk());
    }
    [Test]
    void test_initialize_format_error()
    {
      foreach (var i in setup().invalid_ipv4)
      {
        Assert.IsTrue(IPAddress.parse(i).isErr());
      }
      Assert.IsTrue(IPAddress.parse("10.0.0.0/asd").isErr());
    }
    [Test]
    void test_initialize_without_prefix()
    {
      Assert.IsTrue(IPAddress.parse("10.10.0.0").isOk());
      var ip = IPAddress.parse("10.10.0.0").unwrap();
      Assert.IsTrue(!ip.is_ipv6() && ip.is_ipv4());
      Assert.AreEqual(32, ip.prefix.num);
    }
    [Test]
    void test_attributes()
    {
      foreach (var kp in setup().valid_ipv4)
      {
        var arg = kp.Key;
        var attr = kp.Value;
        var ip = IPAddress.parse(arg).unwrap();
        // println!("test_attributes:{}:{:?}", arg, attr);
        Assert.AreEqual(attr.ip, ip.to_s());
        Assert.AreEqual(attr.prefix, ip.prefix.num);
      }

    }

    [Test]
    void test_octets()
    {
      var ip = IPAddress.parse("10.1.2.3/8").unwrap();
      Assert.AreEqual(ip.parts(), new List<int> { 10, 1, 2, 3 });
    }

    [Test]
    void test_method_to_string()
    {
      foreach (var kp in setup().valid_ipv4)
      {
        var arg = kp.Key;
        var attr = kp.Value;
        var ip = IPAddress.parse(arg).unwrap();
        Assert.AreEqual(string.Format("%s/%d", attr.ip, attr.prefix), ip.to_string());
      }

    }
    [Test]
    void test_method_to_s()
    {
      foreach (var kp in setup().valid_ipv4)
      {
        var arg = kp.Key;
        var attr = kp.Value;
        var ip = IPAddress.parse(arg).unwrap();
        Assert.AreEqual(attr.ip, ip.to_s());
            // var ip_c = IPAddress.parse(arg).unwrap();
        // Assert.AreEqual(attr.ip, ip.to_s());
      }

    }
    [Test]
    void test_netmask()
    {
      foreach (var kp in setup().netmask_values)
      {
        var addr = kp.Key;
        var mask = kp.Value;
        var ip = IPAddress.parse(addr).unwrap();
        Assert.AreEqual(ip.netmask().to_s(), mask);
      }
    }
    [Test]
    void test_method_to_u32()
    {
      foreach (var kp in setup().decimal_values)
      {
        var addr = kp.Key;
        var val = kp.Value;
        var ip = IPAddress.parse(addr).unwrap();
        Assert.AreEqual(ip.host_address, val);
      }
    }
    [Test]
    void test_method_is_network()
    {
      Assert.AreEqual(true, setup().network.is_network());
      Assert.AreEqual(false, setup().ip.is_network());
    }
    [Test]
    void test_one_address_network()
    {
      var network = IPAddress.parse("172.16.10.1/32").unwrap();
      Assert.AreEqual(false, network.is_network());
    }
    [Test]
    void test_method_broadcast()
    {
      foreach (var kp in setup().broadcast)
      {
        var addr = kp.Key;
        var bcast = kp.Value;
        var ip = IPAddress.parse(addr).unwrap();
        Assert.AreEqual(bcast, ip.broadcast().to_string());
      }
    }
    [Test]
    void test_method_network()
    {
      foreach (var kp in setup().networks)
      {
        var addr = kp.Key;
        var net = kp.Value;
        var ip = IPAddress.parse(addr).unwrap();
        Assert.AreEqual(net, ip.network().to_string());
      }

    }

    [Test]
    void test_method_bits()
    {
      var ip = IPAddress.parse("127.0.0.1").unwrap();
      Assert.AreEqual("01111111000000000000000000000001", ip.bits());
    }
    [Test]
    void test_method_first()
    {
      var ip = IPAddress.parse("192.168.100.0/24").unwrap();
      Assert.AreEqual("192.168.100.1", ip.first().to_s());
      ip = IPAddress.parse("192.168.100.50/24").unwrap();
      Assert.AreEqual("192.168.100.1", ip.first().to_s());
    }
    [Test]
    void test_method_last()
    {
      var ip = IPAddress.parse("192.168.100.0/24").unwrap();
      Assert.AreEqual("192.168.100.254", ip.last().to_s());
      ip = IPAddress.parse("192.168.100.50/24").unwrap();
      Assert.AreEqual("192.168.100.254", ip.last().to_s());
    }
    [Test]
    void test_method_each_host()
    {
      var ip = IPAddress.parse("10.0.0.1/29").unwrap();
      var arr = new List<String>();
      ip.each_host(i =>  arr.Add(i.to_s()) );
      Assert.AreEqual(arr, new List<String> { "10.0.0.1", "10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6" });
    }
    [Test]
    void test_method_each()
    {
      var ip = IPAddress.parse("10.0.0.1/29").unwrap();
      var arr = new List<String>();
      ip.each(i => arr.Add(i.to_s()) );
      Assert.AreEqual(arr,
                      new List<String> {"10.0.0.0", "10.0.0.1", "10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5",
          "10.0.0.6", "10.0.0.7" });
    }
    [Test]
    void test_method_size()
    {
      var ip = IPAddress.parse("10.0.0.1/29").unwrap();
      Assert.AreEqual(ip.size(), new BigInteger(8));
    }
    [Test]
    void test_method_network_u32()
    {
      Assert.AreEqual(2886732288, setup().ip.network().host_address);
     }

    [Test]
    void test_method_broadcast_u32()
    {
      Assert.AreEqual(2886732543, setup().ip.broadcast().host_address);
     }

    [Test]
    void test_method_include()
    {
      var ip = IPAddress.parse("192.168.10.100/24").unwrap();
      var addr = IPAddress.parse("192.168.10.102/24").unwrap();
      Assert.AreEqual(true, ip.includes(addr));
      Assert.AreEqual(false,
                 ip.includes(IPAddress.parse("172.16.0.48").unwrap()));
      ip = IPAddress.parse("10.0.0.0/8").unwrap();
      Assert.AreEqual(true, ip.includes(IPAddress.parse("10.0.0.0/9").unwrap()));
      Assert.AreEqual(true, ip.includes(IPAddress.parse("10.1.1.1/32").unwrap()));
      Assert.AreEqual(true, ip.includes(IPAddress.parse("10.1.1.1/9").unwrap()));
      Assert.AreEqual(false,
                 ip.includes(IPAddress.parse("172.16.0.0/16").unwrap()));
      Assert.AreEqual(false, ip.includes(IPAddress.parse("10.0.0.0/7").unwrap()));
      Assert.AreEqual(false, ip.includes(IPAddress.parse("5.5.5.5/32").unwrap()));
      Assert.AreEqual(false, ip.includes(IPAddress.parse("11.0.0.0/8").unwrap()));
      ip = IPAddress.parse("13.13.0.0/13").unwrap();
      Assert.AreEqual(false,
                 ip.includes(IPAddress.parse("13.16.0.0/32").unwrap()));
    }
    [Test]
    void test_method_include_all()
    {
      var ip = IPAddress.parse("192.168.10.100/24").unwrap();
      var addr1 = IPAddress.parse("192.168.10.102/24").unwrap();
      var addr2 = IPAddress.parse("192.168.10.103/24").unwrap();
        Assert.AreEqual(true, ip.includes_all(new List<IPAddress> { addr1, addr2 }));
        Assert.AreEqual(false,
                        ip.includes_all(new List<IPAddress> { addr1, IPAddress.parse("13.16.0.0/32").unwrap() }));
    }

    [Test]
    void test_method_ipv4()
    {
      Assert.AreEqual(true, setup().ip.is_ipv4());
    }
    [Test]
    void test_method_ipv6()
    {
      Assert.AreEqual(false, setup().ip.is_ipv6());
    }
    [Test]
    void test_method_private()
    {
      Assert.AreEqual(true,
                 IPAddress.parse("169.254.10.50/24").unwrap().is_private());
      Assert.AreEqual(true,
                 IPAddress.parse("192.168.10.50/24").unwrap().is_private());
      Assert.AreEqual(true,
                 IPAddress.parse("192.168.10.50/16").unwrap().is_private());
      Assert.AreEqual(true,
                 IPAddress.parse("172.16.77.40/24").unwrap().is_private());
      Assert.AreEqual(true,
                 IPAddress.parse("172.16.10.50/14").unwrap().is_private());
      Assert.AreEqual(true,
                 IPAddress.parse("10.10.10.10/10").unwrap().is_private());
      Assert.AreEqual(true, IPAddress.parse("10.0.0.0/8").unwrap().is_private());
      Assert.AreEqual(false,
                 IPAddress.parse("192.168.10.50/12").unwrap().is_private());
      Assert.AreEqual(false, IPAddress.parse("3.3.3.3").unwrap().is_private());
      Assert.AreEqual(false, IPAddress.parse("10.0.0.0/7").unwrap().is_private());
      Assert.AreEqual(false,
                 IPAddress.parse("172.32.0.0/12").unwrap().is_private());
      Assert.AreEqual(false,
                 IPAddress.parse("172.16.0.0/11").unwrap().is_private());
      Assert.AreEqual(false,
                 IPAddress.parse("192.0.0.2/24").unwrap().is_private());
    }
    [Test]
    void test_method_octet()
    {
      Assert.AreEqual(setup().ip.parts()[0], 172);
      Assert.AreEqual(setup().ip.parts()[1], 16);
      Assert.AreEqual(setup().ip.parts()[2], 10);
      Assert.AreEqual(setup().ip.parts()[3], 1);
    }
    [Test]
    void test_method_a()
    {
      Assert.AreEqual(true, IpV4.is_class_a(setup().class_a));
      Assert.AreEqual(false, IpV4.is_class_a(setup().class_b));
      Assert.AreEqual(false, IpV4.is_class_a(setup().class_c));
    }
    [Test]
    void test_method_b()
    {
      Assert.AreEqual(true, IpV4.is_class_b(setup().class_b));
      Assert.AreEqual(false, IpV4.is_class_b(setup().class_a));
      Assert.AreEqual(false, IpV4.is_class_b(setup().class_c));
    }
    [Test]
    void test_method_c()
    {
      Assert.AreEqual(true, IpV4.is_class_c(setup().class_c));
      Assert.AreEqual(false, IpV4.is_class_c(setup().class_a));
      Assert.AreEqual(false, IpV4.is_class_c(setup().class_b));
    }
    [Test]
    void test_method_to_ipv6()
    {
      Assert.AreEqual("::ac10:a01", setup().ip.to_ipv6().to_s());
    }
    [Test]
    void test_method_reverse()
    {
      Assert.AreEqual(setup().ip.dns_reverse(), "10.16.172.in-addr.arpa");
    }
    [Test]
    void test_method_dns_rev_domains()
    {
      Assert.AreEqual(IPAddress.parse("173.17.5.1/23").unwrap().dns_rev_domains(),
                        new List<String> { "4.17.173.in-addr.arpa", "5.17.173.in-addr.arpa" });
      Assert.AreEqual(IPAddress.parse("173.17.1.1/15").unwrap().dns_rev_domains(),
                 new List<String> { "16.173.in-addr.arpa", "17.173.in-addr.arpa" });
      Assert.AreEqual(IPAddress.parse("173.17.1.1/7").unwrap().dns_rev_domains(),
                 new List<String> { "172.in-addr.arpa", "173.in-addr.arpa" });
      Assert.AreEqual(IPAddress.parse("173.17.1.1/29").unwrap().dns_rev_domains(),
                 new List<String> {
                       "0.1.17.173.in-addr.arpa",
                       "1.1.17.173.in-addr.arpa",
                       "2.1.17.173.in-addr.arpa",
                       "3.1.17.173.in-addr.arpa",
                       "4.1.17.173.in-addr.arpa",
                       "5.1.17.173.in-addr.arpa",
                       "6.1.17.173.in-addr.arpa",
                       "7.1.17.173.in-addr.arpa"});
      Assert.AreEqual(IPAddress.parse("174.17.1.1/24").unwrap().dns_rev_domains(),
                        new List<String> { "1.17.174.in-addr.arpa" });
      Assert.AreEqual(IPAddress.parse("175.17.1.1/16").unwrap().dns_rev_domains(),
                 new List<String> { "17.175.in-addr.arpa" });
      Assert.AreEqual(IPAddress.parse("176.17.1.1/8").unwrap().dns_rev_domains(),
                 new List<String> { "176.in-addr.arpa" });
      Assert.AreEqual(IPAddress.parse("177.17.1.1/0").unwrap().dns_rev_domains(),
                 new List<String> { "in-addr.arpa" });
      Assert.AreEqual(IPAddress.parse("178.17.1.1/32").unwrap().dns_rev_domains(),
                new List<String> { "1.1.17.178.in-addr.arpa" });
    }
    [Test]
    void test_method_compare()
    {
      var ip1 = IPAddress.parse("10.1.1.1/8").unwrap();
      var ip2 = IPAddress.parse("10.1.1.1/16").unwrap();
      var ip3 = IPAddress.parse("172.16.1.1/14").unwrap();
      var ip4 = IPAddress.parse("10.1.1.1/8").unwrap();

      // ip2 should be greater than ip1
      Assert.AreEqual(true, ip1.lt(ip2));
      Assert.AreEqual(false, ip1.gt(ip2));
      Assert.AreEqual(false, ip2.lt(ip1));
      // ip2 should be less than ip3
      Assert.AreEqual(true, ip2.lt(ip3));
      Assert.AreEqual(false, ip2.gt(ip3));
      // ip1 should be less than ip3
      Assert.AreEqual(true, ip1.lt(ip3));
      Assert.AreEqual(false, ip1.gt(ip3));
      Assert.AreEqual(false, ip3.lt(ip1));
      // ip1 should be equal to itself
      Assert.AreEqual(true, ip1.equal(ip1));
      // ip1 should be equal to ip4
      Assert.AreEqual(true, ip1.equal(ip4));
      // test sorting
      var res = IPAddress.sort(new List<IPAddress> { ip1, ip2, ip3 });
      Assert.AreEqual(IPAddress.to_string_vec(res),
                      new List<String> { "10.1.1.1/8", "10.1.1.1/16", "172.16.1.1/14" });
      // test same prefix
      ip1 = IPAddress.parse("10.0.0.0/24").unwrap();
      ip2 = IPAddress.parse("10.0.0.0/16").unwrap();
      ip3 = IPAddress.parse("10.0.0.0/8").unwrap();
      {
        res = IPAddress.sort(new List<IPAddress> { ip1, ip2, ip3 });
        Assert.AreEqual(IPAddress.to_string_vec(res),
                   new List<String> { "10.0.0.0/8", "10.0.0.0/16", "10.0.0.0/24" });
      }
    }
    [Test]
    void test_method_minus()
    {
      var ip1 = IPAddress.parse("10.1.1.1/8").unwrap();
      var ip2 = IPAddress.parse("10.1.1.10/8").unwrap();
      Assert.AreEqual(9, (int)ip2.sub(ip1));
      Assert.AreEqual(9, (int)ip1.sub(ip2));
    }
    [Test]
    void test_method_plus()
    {
      var ip1 = IPAddress.parse("172.16.10.1/24").unwrap();
      var ip2 = IPAddress.parse("172.16.11.2/24").unwrap();
      Assert.AreEqual(IPAddress.to_string_vec(ip1.add(ip2)), new List<String> { "172.16.10.0/23" });

      ip2 = IPAddress.parse("172.16.12.2/24").unwrap();
      Assert.AreEqual(IPAddress.to_string_vec(ip1.add(ip2)),
                 new List<String> { ip1.network().to_string(), ip2.network().to_string() });

      ip1 = IPAddress.parse("10.0.0.0/23").unwrap();
      ip2 = IPAddress.parse("10.0.2.0/24").unwrap();
      Assert.AreEqual(IPAddress.to_string_vec(ip1.add(ip2)),
                 new List<String> { "10.0.0.0/23", "10.0.2.0/24" });

      ip1 = IPAddress.parse("10.0.0.0/23").unwrap();
      ip2 = IPAddress.parse("10.0.2.0/24").unwrap();
      Assert.AreEqual(IPAddress.to_string_vec(ip1.add(ip2)),
                 new List<String> { "10.0.0.0/23", "10.0.2.0/24" });

      ip1 = IPAddress.parse("10.0.0.0/16").unwrap();
      ip2 = IPAddress.parse("10.0.2.0/24").unwrap();
      Assert.AreEqual(IPAddress.to_string_vec(ip1.add(ip2)),
          new List<String> { "10.0.0.0/16" });

      ip1 = IPAddress.parse("10.0.0.0/23").unwrap();
      ip2 = IPAddress.parse("10.1.0.0/24").unwrap();
      Assert.AreEqual(IPAddress.to_string_vec(ip1.add(ip2)),
                      new List<String> { "10.0.0.0/23", "10.1.0.0/24" });
    }
    [Test]
    void test_method_netmask_equal()
    {
      var ip = IPAddress.parse("10.1.1.1/16").unwrap();
      Assert.AreEqual(16, ip.prefix.num);
      var ip2 = ip.change_netmask("255.255.255.0").unwrap();
      Assert.AreEqual(24, ip2.prefix.num);
    }
    [Test]
    void test_method_split()
    {
      Assert.IsTrue(setup().ip.split(0).isErr());
      Assert.IsTrue(setup().ip.split(257).isErr());

      Assert.AreEqual(setup().ip.split(1).unwrap(), new List<IPAddress> { setup().ip.network() });

      Assert.AreEqual(IPAddress.to_string_vec(setup().network.split(8).unwrap()),
                      new List<String> { "172.16.10.0/27",
                    "172.16.10.32/27",
                    "172.16.10.64/27",
                    "172.16.10.96/27",
                    "172.16.10.128/27",
                    "172.16.10.160/27",
                    "172.16.10.192/27",
          "172.16.10.224/27"});

      Assert.AreEqual(IPAddress.to_string_vec(setup().network.split(7).unwrap()),
                 new List<String> { "172.16.10.0/27",
                    "172.16.10.32/27",
                    "172.16.10.64/27",
                    "172.16.10.96/27",
                    "172.16.10.128/27",
                    "172.16.10.160/27",
                    "172.16.10.192/26" });

      Assert.AreEqual(IPAddress.to_string_vec(setup().network.split(6).unwrap()),
                 new List<String> { "172.16.10.0/27",
                    "172.16.10.32/27",
                    "172.16.10.64/27",
                    "172.16.10.96/27",
                    "172.16.10.128/26",
                    "172.16.10.192/26" });
      Assert.AreEqual(IPAddress.to_string_vec(setup().network.split(5).unwrap()),
                 new List<String> { "172.16.10.0/27",
                    "172.16.10.32/27",
                    "172.16.10.64/27",
                    "172.16.10.96/27",
                    "172.16.10.128/25" });
      Assert.AreEqual(IPAddress.to_string_vec(setup().network.split(4).unwrap()),
                 new List<String> { "172.16.10.0/26", "172.16.10.64/26", "172.16.10.128/26", "172.16.10.192/26" });
      Assert.AreEqual(IPAddress.to_string_vec(setup().network.split(3).unwrap()),
                 new List<String> { "172.16.10.0/26", "172.16.10.64/26", "172.16.10.128/25" });
      Assert.AreEqual(IPAddress.to_string_vec(setup().network.split(2).unwrap()),
                 new List<String> { "172.16.10.0/25", "172.16.10.128/25" });
      Assert.AreEqual(IPAddress.to_string_vec(setup().network.split(1).unwrap()),
                      new List<String> { "172.16.10.0/24" });
    }
    [Test]
    void test_method_subnet()
    {
      Assert.IsTrue(setup().network.subnet(23).isErr());
      Assert.IsTrue(setup().network.subnet(33).isErr());
      Assert.IsTrue(setup().ip.subnet(30).isOk());
      Assert.AreEqual(IPAddress.to_string_vec(setup().network.subnet(26).unwrap()),
                               new List<String> { "172.16.10.0/26",
                                  "172.16.10.64/26",
                                  "172.16.10.128/26",
          "172.16.10.192/26" });
      Assert.AreEqual(IPAddress.to_string_vec(setup().network.subnet(25).unwrap()),
                 new List<String> { "172.16.10.0/25", "172.16.10.128/25" });
      Assert.AreEqual(IPAddress.to_string_vec(setup().network.subnet(24).unwrap()),
                      new List<String> { "172.16.10.0/24" });
    }
    [Test]
    void test_method_supernet()
    {
      Assert.IsTrue(setup().ip.supernet(24).isErr());
      Assert.AreEqual("0.0.0.0/0", setup().ip.supernet(0).unwrap().to_string());
      // Assert.AreEqual("0.0.0.0/0", setup().ip.supernet(-2).unwrap().to_string());
      Assert.AreEqual("172.16.10.0/23",
                 setup().ip.supernet(23).unwrap().to_string());
      Assert.AreEqual("172.16.8.0/22",
                 setup().ip.supernet(22).unwrap().to_string());
    }
    [Test]
    void test_classmethod_parse_u32()
    {
      foreach (var kp in setup().decimal_values)
      {
        var addr = kp.Key;
        var value = kp.Value;
        var ip = IpV4.from_u32(value, 32).unwrap();
        var splitted = addr.Split(new string[] { "/" }, StringSplitOptions.None);
        var ip2 = ip.change_prefix(int.Parse(splitted[1])).unwrap();
        Assert.AreEqual(ip2.to_string(), addr);
      }
    }

    // void test_classhmethod_extract() {
    //   var str = "foobar172.16.10.1barbaz";
    //   Assert.AreEqual("172.16.10.1", IPAddress.extract(str).to_s
    // }
    [Test]
    void test_classmethod_summarize()
    {

      // Should return self if only one network given
      Assert.AreEqual(IPAddress.summarize(new List<IPAddress> { setup().ip }),
                      new List<IPAddress> { setup().ip.network() });

      // Summarize homogeneous networks
      var ip1 = IPAddress.parse("172.16.10.1/24").unwrap();
      var ip2 = IPAddress.parse("172.16.11.2/24").unwrap();
      Assert.AreEqual(IPAddress.to_string_vec(IPAddress.summarize(new List<IPAddress> { ip1, ip2 })),
                      new List<String> { "172.16.10.0/23" });

      ip1 = IPAddress.parse("10.0.0.1/24").unwrap();
      ip2 = IPAddress.parse("10.0.1.1/24").unwrap();
      var ip3 = IPAddress.parse("10.0.2.1/24").unwrap();
      var ip4 = IPAddress.parse("10.0.3.1/24").unwrap();
      Assert.AreEqual(IPAddress.to_string_vec(IPAddress.summarize(new List<IPAddress> { ip1, ip2, ip3, ip4 })),
                            new List<String> { "10.0.0.0/22" });


      ip1 = IPAddress.parse("10.0.0.1/24").unwrap();
      ip2 = IPAddress.parse("10.0.1.1/24").unwrap();
      ip3 = IPAddress.parse("10.0.2.1/24").unwrap();
      ip4 = IPAddress.parse("10.0.3.1/24").unwrap();
      Assert.AreEqual(IPAddress.to_string_vec(IPAddress.summarize(new List<IPAddress> { ip4, ip3, ip2, ip1 })),
                      new List<String> { "10.0.0.0/22" });

      // Summarize non homogeneous networks
      ip1 = IPAddress.parse("10.0.0.0/23").unwrap();
      ip2 = IPAddress.parse("10.0.2.0/24").unwrap();
            Assert.AreEqual(IPAddress.to_string_vec(IPAddress.summarize(new List<IPAddress> { ip1, ip2 })),
                  new List<String> { "10.0.0.0/23", "10.0.2.0/24"});

      ip1 = IPAddress.parse("10.0.0.0/16").unwrap();
      ip2 = IPAddress.parse("10.0.2.0/24").unwrap();
      Assert.AreEqual(IPAddress.to_string_vec(IPAddress.summarize(new List<IPAddress> { ip1, ip2 })),
                      new List<String> { "10.0.0.0/16" });

      ip1 = IPAddress.parse("10.0.0.0/23").unwrap();
      ip2 = IPAddress.parse("10.1.0.0/24").unwrap();
      Assert.AreEqual(IPAddress.to_string_vec(IPAddress.summarize(new List<IPAddress> { ip1, ip2})),
                   new List<String> { "10.0.0.0/23", "10.1.0.0/24"});

      ip1 = IPAddress.parse("10.0.0.0/23").unwrap();
      ip2 = IPAddress.parse("10.0.2.0/23").unwrap();
      ip3 = IPAddress.parse("10.0.4.0/24").unwrap();
      ip4 = IPAddress.parse("10.0.6.0/24").unwrap();
      Assert.AreEqual(IPAddress.to_string_vec(IPAddress.summarize(new List<IPAddress> { ip1, ip2, ip3, ip4})),
                   new List<String> { "10.0.0.0/22", "10.0.4.0/24", "10.0.6.0/24"});
        
        ip1 = IPAddress.parse("10.0.1.1/24").unwrap();
      ip2 = IPAddress.parse("10.0.2.1/24").unwrap();
      ip3 = IPAddress.parse("10.0.3.1/24").unwrap();
      ip4 = IPAddress.parse("10.0.4.1/24").unwrap();
      Assert.AreEqual(IPAddress.to_string_vec(IPAddress.summarize(new List<IPAddress> { ip1, ip2, ip3, ip4})),
                   new List<String> { "10.0.1.0/24", "10.0.2.0/23", "10.0.4.0/24"});


      ip1 = IPAddress.parse("10.0.1.1/24").unwrap();
      ip2 = IPAddress.parse("10.0.2.1/24").unwrap();
      ip3 = IPAddress.parse("10.0.3.1/24").unwrap();
      ip4 = IPAddress.parse("10.0.4.1/24").unwrap();
                    Assert.AreEqual(IPAddress.to_string_vec(IPAddress.summarize(new List<IPAddress>{ip4, ip3, ip2, ip1 })),
                                    new List<String>{"10.0.1.0/24", "10.0.2.0/23", "10.0.4.0/24" });

        ip1 = IPAddress.parse("10.0.1.1/24").unwrap();
      ip2 = IPAddress.parse("10.10.2.1/24").unwrap();
      ip3 = IPAddress.parse("172.16.0.1/24").unwrap();
      ip4 = IPAddress.parse("172.16.1.1/24").unwrap();
      Assert.AreEqual(IPAddress.to_string_vec(IPAddress.summarize(new List<IPAddress> { ip1, ip2, ip3, ip4 })),
                      new List<String> { "10.0.1.0/24", "10.10.2.0/24", "172.16.0.0/23" });

                      var ips = new List<IPAddress> {IPAddress.parse("10.0.0.12/30").unwrap(),
                      IPAddress.parse("10.0.100.0/24").unwrap()};
      Assert.AreEqual(IPAddress.to_string_vec(IPAddress.summarize(ips)),
                      new List<String> { "10.0.0.12/30", "10.0.100.0/24" });

      ips = new List<IPAddress> {
          IPAddress.parse("172.16.0.0/31").unwrap(),
                      IPAddress.parse("10.10.2.1/32").unwrap()
                        };
      Assert.AreEqual(IPAddress.to_string_vec(IPAddress.summarize(ips)),
                        new List<String> { "10.10.2.1/32", "172.16.0.0/31" });

                        var xips = new List<IPAddress> {IPAddress.parse("172.16.0.0/32").unwrap(),
                            IPAddress.parse("10.10.2.1/32").unwrap()};
      Assert.AreEqual(IPAddress.to_string_vec(IPAddress.summarize(xips)),
                          new List<String> { "10.10.2.1/32", "172.16.0.0/32" });
    }

    [Test]
    void test_classmethod_parse_classful()
    {
                  foreach (var kp in setup().classful) {
        var ip = kp.Key;
                            var prefix = kp.Value;
    var res = IpV4.parse_classful(ip).unwrap();
    Assert.AreEqual(prefix, res.prefix.num);
      Assert.AreEqual(string.Format("%s/%d", ip, prefix), res.to_string());
    }
  Assert.IsTrue(IpV4.parse_classful("192.168.256.257").isErr());
    }
}
}
