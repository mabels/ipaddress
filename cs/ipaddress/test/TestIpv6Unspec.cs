using System;
using System.Numerics;
using System.Collections.Generic;
using NUnit.Framework;

namespace ipaddress
{

  class IPv6UnspecifiedTest
  {
    public IPAddress ip;
    public String to_s;
    public String to_string;
    public String to_string_uncompressed;
    public BigInteger num;
    public IPv6UnspecifiedTest(IPAddress ip, String to_s, String to_string,
        String to_string_uncompressed, BigInteger num) {
      this.ip = ip;
          this.to_s = to_s;
          this.to_string = to_string;
          this.to_string_uncompressed = to_string_uncompressed;
          this.num = num;
        }
  }

class TestIpv6Unspec {

    IPv6UnspecifiedTest setup() {
        return new IPv6UnspecifiedTest(
            Ipv6Unspec.create(),
            "::",
            "::/128",
            "0000:0000:0000:0000:0000:0000:0000:0000/128",
            new BigInteger(0));
    }

    //@Test
    void test_attributes() {
        Assert.AreEqual(setup().ip.host_address, setup().num);
        Assert.AreEqual(128, setup().ip.prefix.get_prefix());
        Assert.AreEqual(true, setup().ip.is_unspecified());
        Assert.AreEqual(setup().to_s, setup().ip.to_s());
        Assert.AreEqual(setup().to_string, setup().ip.to_string());
        Assert.AreEqual(setup().to_string_uncompressed,
                   setup().ip.to_string_uncompressed());
    }
   
    //@Test 
    void test_method_ipv6() {
        Assert.AreEqual(true, setup().ip.is_ipv6());
    }
}
}
