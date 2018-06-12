package com.adviser.ipaddress.kotlin

import org.junit.Test
import java.math.BigInteger
import kotlin.test.assertEquals

class IPv6LoopbackTest(val ip: IPAddress,
                       val s: String,
                       val n: String,
                       val string: String,
                       val one: BigInteger) {
}

class TestIpv6Loopback {

    fun setup(): IPv6LoopbackTest {
        return IPv6LoopbackTest(
                Ipv6Loopback.create(),
                "::1",
                "::1/128",
                "0000:0000:0000:0000:0000:0000:0000:0001/128",
                BigInteger.ONE
        )
    }

    @Test
    fun test_attributes() {
        val s = setup()
        assertEquals(128, s.ip.prefix.num)
        assertEquals(true, s.ip.is_loopback())
        assertEquals(s.s, s.ip.to_s())
        assertEquals(s.n, s.ip.to_string())
        assertEquals(s.string, s.ip.to_string_uncompressed())
        assertEquals(s.one, s.ip.host_address)
    }

    @Test
    fun test_method_ipv6() {
        assertEquals(true, setup().ip.is_ipv6())
    }
}
