package com.adviser.ipaddress.kotlin


import org.junit.Test
import java.math.BigInteger
import kotlin.test.assertEquals

class IPv6UnspecifiedTest(
        val ip: IPAddress,
        val to_s: String,
        val to_string: String,
        val to_string_uncompressed: String,
        val num: BigInteger) {
}

class TestIpv6Unspec {

    public fun setup(): IPv6UnspecifiedTest {
        return IPv6UnspecifiedTest(
                Ipv6Unspec.create(),
                "::",
                "::/128",
                "0000:0000:0000:0000:0000:0000:0000:0000/128",
                BigInteger.ZERO)
    }

    @Test
    public fun test_attributes() {
        assertEquals(setup().ip.host_address, setup().num)
        assertEquals(128, setup().ip.prefix().get_prefix())
        assertEquals(true, setup().ip.is_unspecified())
        assertEquals(setup().to_s, setup().ip.to_s())
        assertEquals(setup().to_string, setup().ip.to_string())
        assertEquals(setup().to_string_uncompressed,
                setup().ip.to_string_uncompressed())
    }

    @Test
    public fun test_method_ipv6() {
        assertEquals(true, setup().ip.is_ipv6())
    }
}
