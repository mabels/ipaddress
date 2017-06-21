package com.adviser.ipaddress

import java.math.BigInteger
import org.junit.Test
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.assertEquals;


class TestIpv6Unspec {

    static class IPv6UnspecifiedTest {
        public IPAddress ip
        public String to_s
        public String to_string
        public String to_string_uncompressed
        public BigInteger num
        new(IPAddress ip, String to_s, String to_string,
            String to_string_uncompressed, BigInteger num) {
          this.ip = ip
          this.to_s = to_s
          this.to_string = to_string
          this.to_string_uncompressed = to_string_uncompressed
          this.num = num
        }
    }

    public def IPv6UnspecifiedTest setup() {
        return new IPv6UnspecifiedTest(
            Ipv6Unspec.create(),
            "::",
            "::/128",
            "0000:0000:0000:0000:0000:0000:0000:0000/128",
            BigInteger.ZERO);
    }

    @Test
    public def test_attributes() {
        assertEquals(setup().ip.host_address, setup().num);
        assertEquals(128, setup().ip.prefix().get_prefix());
        assertEquals(true, setup().ip.is_unspecified());
        assertEquals(setup().to_s, setup().ip.to_s());
        assertEquals(setup().to_string, setup().ip.to_string());
        assertEquals(setup().to_string_uncompressed,
                   setup().ip.to_string_uncompressed());
    }
   
    @Test 
    public def test_method_ipv6() {
        assertEquals(true, setup().ip.is_ipv6());
    }
}
