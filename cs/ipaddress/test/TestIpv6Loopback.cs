using System;
using System.Numerics;
using Xunit;
using ipaddress;

//namespace ipaddress
namespace address_test
{

  class IPv6LoopbackTest
  {
    public IPAddress ip;
    public String s;
    public String n;
    public String _str;
    public BigInteger one;
    public IPv6LoopbackTest(IPAddress ip, String s, String n,
        String _str, BigInteger one)
    {
      this.ip = ip;
      this.s = s;
      this.n = n;
      this._str = _str;
      this.one = one;
    }
  }

  public class TestIpv6Loopback {

    IPv6LoopbackTest setup() {
      return new IPv6LoopbackTest(
          Ipv6Loopback.create(),
          "::1",
          "::1/128",
          "0000:0000:0000:0000:0000:0000:0000:0001/128",
          new BigInteger(1)
          );
    }

    [Fact]
      void test_attributes() {
        var s = setup();
        Assert.Equal(128u, s.ip.prefix.num);
        Assert.True(s.ip.is_loopback());
        Assert.Equal(s.s, s.ip.to_s());
        Assert.Equal(s.n, s.ip.to_string());
        Assert.Equal(s._str, s.ip.to_string_uncompressed());
        Assert.Equal(s.one, s.ip.host_address);
      }

    [Fact]
      void test_method_ipv6() {
        Assert.True(setup().ip.is_ipv6());
      }
  }
}
