using System;
using System.Numerics;
using System.Collections.Generic;

namespace ipaddress
{

class TestIpv6Loopback {
    
    static class IPv6LoopbackTest {
        IPAddress ip
        String s
        String n
        String string
        BigInteger one
        new(IPAddress ip, String s, String n,
            String string, BigInteger one) {
        this.ip = ip
        this.s = s
        this.n = n
        this.string = string
        this.one = one
        }
    }

    def IPv6LoopbackTest setup() {
        return new IPv6LoopbackTest(
            Ipv6Loopback.create(),
            "::1",
            "::1/128",
            "0000:0000:0000:0000:0000:0000:0000:0001/128",
            BigInteger.ONE
        );
    }

    @Test
    public def test_attributes() {
        val s = setup();
        assertEquals(128, s.ip.prefix.num);
        assertEquals(true, s.ip.is_loopback());
        assertEquals(s.s, s.ip.to_s());
        assertEquals(s.n, s.ip.to_string());
        assertEquals(s.string, s.ip.to_string_uncompressed());
        assertEquals(s.one, s.ip.host_address);
    }

    @Test
    def test_method_ipv6() {
        assertEquals(true, setup().ip.is_ipv6());
    }
}
}
