
using System;
//using System.Numerics;
using System.Collections.Generic;
//using NUnit.Framework;
using Xunit;
using ipaddress;

//namespace ipaddress
namespace address_test
{

  class Ranger
  {
    public int start;
    public int stop;
    public Ranger(int start, int stop)
    {
      this.start = start;
      this.stop = stop;
    }
  };
  class IPAddressTest
  {
    public string valid_ipv4;
    public string valid_ipv6;
    public string valid_mapped;
    public string invalid_ipv4;
    public string invalid_ipv6;
    public string invalid_mapped;
    public IPAddressTest(string valid_ipv4, string valid_ipv6, string valid_mapped,
        string invalid_ipv4, string invalid_ipv6, string invalid_mapped)
    {
      this.valid_ipv4 = valid_ipv4;
      this.valid_ipv6 = valid_ipv6;
      this.valid_mapped = valid_mapped;
      this.invalid_ipv4 = invalid_ipv4;
      this.invalid_ipv6 = invalid_ipv6;
      this.invalid_mapped = invalid_mapped;
    }
  };




  public class TestIpAddress
  {
        internal static void Compare<T>(List<T> me, List<T> my)
    {
      if (me.Count != my.Count)
      {
        Xunit.Assert.Equal(me, my);
      }
      for (var i = 0; i < my.Count; ++i)
      {
        Xunit.Assert.Equal(me[i], my[i]);
      }
    }


    IPAddressTest setup()
    {
      return new IPAddressTest("172.16.10.1/24",
          "2001:db8::8:800:200c:417a/64",
          "::13.1.68.3",
          "10.0.0.256",
          ":1:2:3:4:5:6:7",
          "::1:2.3.4");
    }

    [Fact]
    void test_method_ipaddress()
    {
      Assert.True(IPAddress.parse(setup().valid_ipv4).isOk());
      Assert.True(IPAddress.parse(setup().valid_ipv6).isOk());
      Assert.True(IPAddress.parse(setup().valid_mapped).isOk());

      Assert.True(IPAddress.parse(setup().valid_ipv4).unwrap().is_ipv4());
      Assert.True(IPAddress.parse(setup().valid_ipv6).unwrap().is_ipv6());
      Assert.True(IPAddress.parse(setup().valid_mapped).unwrap().is_mapped());

      Assert.True(IPAddress.parse(setup().invalid_ipv4).isErr());
      Assert.True(IPAddress.parse(setup().invalid_ipv6).isErr());
      Assert.True(IPAddress.parse(setup().invalid_mapped).isErr());
    }
    [Fact]
    void test_module_method_valid()
    {
      Assert.True(IPAddress.is_valid("10.0.0.1"));
      Assert.True(IPAddress.is_valid("10.0.0.0"));
      Assert.True(IPAddress.is_valid("2002::1"));
      Assert.True(IPAddress.is_valid("dead:beef:cafe:babe::f0ad"));
      Assert.False(IPAddress.is_valid("10.0.0.256"));
      Assert.False(IPAddress.is_valid("10.0.0.0.0"));
      Assert.True(IPAddress.is_valid("10.0.0"));
      Assert.True(IPAddress.is_valid("10.0"));
      Assert.False(IPAddress.is_valid("2002:516:2:200"));
      Assert.False(IPAddress.is_valid("2002:::1"));
    }
    [Fact]
    void test_module_method_valid_ipv4_netmark()
    {
      Assert.True(IPAddress.is_valid_netmask("255.255.255.0"));
      Assert.False(IPAddress.is_valid_netmask("10.0.0.1"));
    }

    static Ranger Range(int start, int stop)
    {
      return new Ranger(start, stop);
    }

    [Fact]
    void test_summarize()
    {
      var netstr = new List<string>();
      var ranges = new[] {
          Range(1, 10), Range(11, 127),
            Range(128, 169), Range(170, 172),
            Range(173, 192), Range(193, 224)
        };
      foreach (var range in ranges)
      {
        for (var i = range.start; i < range.stop; i++)
        {
          netstr.Add(string.Format("{0}.0.0.0/8", i));
        }
      }
      for (var i = 0; i < 256; i++)
      {
        if (i != 254)
        {
          netstr.Add(string.Format("169.{0}.0.0/16", i));
        }
      }
      for (var i = 0; i < 256; i++)
      {
        if (i < 16 || 31 < i)
        {
          netstr.Add(string.Format("172.{0}.0.0/16", i));
        }
      }
      for (var i = 0; i < 256; i++)
      {
        if (i != 168)
        {
          netstr.Add(string.Format("192.{0}.0.0/16", i));
        }
      }
      var ip_addresses = new List<IPAddress>();
      foreach (var net in netstr)
      {
        ip_addresses.Add(IPAddress.parse(net).unwrap());
      }

      var empty_vec = new List<string>();
      Assert.Empty(IPAddress.summarize_str(empty_vec).unwrap());
      var sone = IPAddress.summarize_str(new List<string> { "10.1.0.4/24" }).unwrap();
      var one = IPAddress.to_string_vec(sone);
      TestIpAddress.Compare(one, new List<String> { "10.1.0.0/24" });
      TestIpAddress.Compare(IPAddress.to_string_vec(IPAddress.summarize_str(new List<String> { "2000:1::4711/32" }).unwrap()),
          new List<String> { "2000:1::/32" });

      TestIpAddress.Compare(IPAddress.to_string_vec(IPAddress.summarize_str(new List<String> { "10.1.0.4/24", "7.0.0.0/0", "1.2.3.4/4" }).unwrap()),
          new List<String> { "0.0.0.0/0" });
      var tmp = IPAddress.to_string_vec(IPAddress.summarize_str(new List<String> {"2000:1::/32",
              "3000:1::/32",
              "2000:2::/32",
              "2000:3::/32",
              "2000:4::/32",
              "2000:5::/32",
              "2000:6::/32",
              "2000:7::/32",
              "2000:8::/32"})
          .unwrap());
      TestIpAddress.Compare(tmp,
          new List<String> { "2000:1::/32", "2000:2::/31", "2000:4::/30", "2000:8::/32", "3000:1::/32" });

      TestIpAddress.Compare(IPAddress.to_string_vec(IPAddress.summarize_str(new List<String> {"10.0.1.1/24",
                "30.0.1.0/16",
                "10.0.2.0/24",
                "10.0.3.0/24",
                "10.0.4.0/24",
                "10.0.5.0/24",
                "10.0.6.0/24",
                "10.0.7.0/24",
                "10.0.8.0/24"}).unwrap()),
          new List<String> { "10.0.1.0/24", "10.0.2.0/23", "10.0.4.0/22", "10.0.8.0/24", "30.0.0.0/16" });

      TestIpAddress.Compare(IPAddress.to_string_vec(IPAddress.summarize_str(new List<String> { "10.0.0.0/23",
                "10.0.2.0/24"}).unwrap()), new List<String> { "10.0.0.0/23", "10.0.2.0/24" });

      TestIpAddress.Compare(IPAddress.to_string_vec(IPAddress.summarize_str(new List<String> { "10.0.0.0/24",
                "10.0.1.0/24",
                "10.0.2.0/23"})
            .unwrap()),
          new List<String> { "10.0.0.0/22" });


      TestIpAddress.Compare(IPAddress.to_string_vec(IPAddress.summarize_str(new List<String> { "10.0.0.0/16",
                "10.0.2.0/24"})
            .unwrap()),
          new List<String> { "10.0.0.0/16" });

      var cnt = 10;
      for (var i = 0; i < cnt; i++)
      {
        TestIpAddress.Compare(IPAddress.to_string_vec(IPAddress.summarize(ip_addresses)),
            new List<String> {"1.0.0.0/8",
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
              "208.0.0.0/4"});
      }
      // end
      // printer = RubyProf::GraphPrinter.new(result)
      // printer.print(STDOUT, {})
      // test imutable input parameters
      var a1 = IPAddress.parse("10.0.0.1/24").unwrap();
      var a2 = IPAddress.parse("10.0.1.1/24").unwrap();
      TestIpAddress.Compare(IPAddress.to_string_vec(IPAddress.summarize(new List<IPAddress> { a1, a2 })), new List<String> { "10.0.0.0/23" });
      Assert.Equal("10.0.0.1/24", a1.to_string());
      Assert.Equal("10.0.1.1/24", a2.to_string());
    }
  }
}
