using System;
using System.Numerics;
using NUnit.Framework;

namespace ipaddress
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

class TestIpv6Loopback {

    IPv6LoopbackTest setup() {
        return new IPv6LoopbackTest(
            Ipv6Loopback.create(),
            "::1",
            "::1/128",
            "0000:0000:0000:0000:0000:0000:0000:0001/128",
            new BigInteger(1)
        );
    }

    //@Test
    void test_attributes() {
        var s = setup();
        Assert.AreEqual(128, s.ip.prefix.num);
        Assert.AreEqual(true, s.ip.is_loopback());
        Assert.AreEqual(s.s, s.ip.to_s());
        Assert.AreEqual(s.n, s.ip.to_string());
        Assert.AreEqual(s._str, s.ip.to_string_uncompressed());
        Assert.AreEqual(s.one, s.ip.host_address);
    }

    //@Test
    void test_method_ipv6() {
        Assert.AreEqual(true, setup().ip.is_ipv6());
    }
}
}
