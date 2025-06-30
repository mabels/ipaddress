using System;
using System.Numerics;
using System.Collections.Generic;
using Xunit;
using ipaddress;

//namespace ipaddress
namespace address_test
{

  class IPv6MappedTest
  {
    public IPAddress ip;
    public String s;
    public String sstr;
    public String _str;
    public BigInteger u128;
    public String address;
    public Dictionary<String, BigInteger> valid_mapped = new Dictionary<String, BigInteger>();
    public Dictionary<String, BigInteger> valid_mapped_ipv6 = new Dictionary<String, BigInteger>();
    public Dictionary<String, String> valid_mapped_ipv6_conversion = new Dictionary<String, String>();
    public IPv6MappedTest(IPAddress ip, String s, String sstr,
        String _str, BigInteger u128, String address) {
      this.ip = ip;
      this.s = s;
      this.sstr = sstr;
      this._str = _str;
      this.u128 = u128;
      this.address = address;
    }
  }


  public   class TestIpv6Mapped {


    IPv6MappedTest setup() {
      var ret = new IPv6MappedTest(
          Ipv6Mapped.create("::172.16.10.1").unwrap(),
          "::ffff:172.16.10.1",
          "::ffff:172.16.10.1/32",
          "0000:0000:0000:0000:0000:ffff:ac10:0a01/128",
          BigInteger.Parse("281473568475649"),
          "::ffff:ac10:a01/128");
      ret.valid_mapped.Add("::13.1.68.3", BigInteger.Parse("281470899930115"));
      ret.valid_mapped.Add("0:0:0:0:0:ffff:129.144.52.38",
          BigInteger.Parse("281472855454758"));
      ret.valid_mapped.Add("::ffff:129.144.52.38",
          BigInteger.Parse("281472855454758"));
      ret.valid_mapped_ipv6.Add("::ffff:13.1.68.3", BigInteger.Parse("281470899930115"));
      ret.valid_mapped_ipv6.Add("0:0:0:0:0:ffff:8190:3426",
          BigInteger.Parse("281472855454758"));
      ret.valid_mapped_ipv6.Add("::ffff:8190:3426",
          BigInteger.Parse("281472855454758"));
      ret.valid_mapped_ipv6_conversion.Add("::ffff:13.1.68.3", "13.1.68.3");
      ret.valid_mapped_ipv6_conversion.Add("0:0:0:0:0:ffff:8190:3426", "129.144.52.38");
      ret.valid_mapped_ipv6_conversion.Add("::ffff:8190:3426", "129.144.52.38");
      return ret;
    }


    [Fact]
      void test_initialize() {
        var s = setup();
        Assert.True(IPAddress.parse("::172.16.10.1").isOk());
        foreach (var kp in s.valid_mapped)
        {
          var ip = kp.Key;
          var u128 = kp.Value;
          //println!("-{}--{}", ip, u128);
          //if IPAddress.parse(ip).is_err() {
          //    println!("{}", IPAddress.parse(ip).unwrapErr());
          //}
          Assert.True(IPAddress.parse(ip).isOk());
          Assert.Equal(u128, IPAddress.parse(ip).unwrap().host_address);
        }

        foreach (var kp in s.valid_mapped_ipv6) {
          var ip = kp.Key;
          var u128 = kp.Value;
          //println!("===={}=={:x}", ip, u128);
          Assert.True(IPAddress.parse(ip).isOk());
          Assert.Equal(u128, IPAddress.parse(ip).unwrap().host_address);
        }
      }
    [Fact]
      void test_mapped_from_ipv6_conversion() {
        foreach (var kp in setup().valid_mapped_ipv6_conversion)
        {
          var ip6 = kp.Key;
          var ip4 = kp.Value;
          //println!("+{}--{}", ip6, ip4);
          Assert.Equal(ip4, IPAddress.parse(ip6).unwrap().mapped.to_s());
        }

      }
    [Fact]
      void test_attributes() {
        var s = setup();
        Assert.Equal(s.address, s.ip.to_string());
        Assert.Equal(128u, s.ip.prefix.num);
        Assert.Equal(s.s, s.ip.to_s_mapped());
        Assert.Equal(s.sstr, s.ip.to_string_mapped());
        Assert.Equal(s._str, s.ip.to_string_uncompressed());
        Assert.Equal(s.u128, s.ip.host_address);
      }
    [Fact]
      void test_method_ipv6() {
        Assert.True(setup().ip.is_ipv6());
      }
    [Fact]
      void test_mapped() {
        Assert.True(setup().ip.is_mapped());
      }
  }
}
