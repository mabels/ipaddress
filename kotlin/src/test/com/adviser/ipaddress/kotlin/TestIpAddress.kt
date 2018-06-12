package com.adviser.ipaddress.kotlin

import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

fun assertArrayEquals(t1: IntArray, t2: IntArray) {
    assertEquals(t1.toList(), t2.toList())
}

fun <T> assertArrayEquals(t1: Array<T>, t2: Array<T>) {
    assertEquals(t1.toList(), t2.toList())
}

fun <T> assertArrayEquals(t1: Array<T>, t2: List<T>) {
    assertEquals(t1.toList(), t2)
}

fun <T> assertArrayEquals(t1: List<T>, t2: Array<T>) {
    assertEquals(t1, t2.toList())
}

fun <T> assertArrayEquals(t1: List<T>, t2: List<T>) {
    assertEquals(t1, t2)
}

class TestIpAddress {

    class IPAddressTest(
            val valid_ipv4: String,
            val valid_ipv6: String,
            val valid_mapped: String,
            val invalid_ipv4: String,
            val invalid_ipv6: String,
            val invalid_mapped: String) {
    }

    class Range(val start: Int, val stop: Int) {
    }

    fun setup(): IPAddressTest {
        return IPAddressTest(
                "172.16.10.1/24",
                "2001:db8::8:800:200c:417a/64",
                "::13.1.68.3",
                "10.0.0.256",
                ":1:2:3:4:5:6:7",
                "::1:2.3.4")
    }

    @Test
    fun test_method_ipaddress() {
        assertTrue(IPAddress.parse(setup().valid_ipv4).isOk())
        assertTrue(IPAddress.parse(setup().valid_ipv6).isOk())
        assertTrue(IPAddress.parse(setup().valid_mapped).isOk())

        assertTrue(IPAddress.parse(setup().valid_ipv4).unwrap().is_ipv4())
        assertTrue(IPAddress.parse(setup().valid_ipv6).unwrap().is_ipv6())
        assertTrue(IPAddress.parse(setup().valid_mapped).unwrap().is_mapped())

        assertTrue(IPAddress.parse(setup().invalid_ipv4).isErr())
        assertTrue(IPAddress.parse(setup().invalid_ipv6).isErr())
        assertTrue(IPAddress.parse(setup().invalid_mapped).isErr())
    }

    @Test
    fun test_module_method_valid() {
        assertEquals(true, IPAddress.is_valid("10.0.0.1"))
        assertEquals(true, IPAddress.is_valid("10.0.0.0"))
        assertEquals(true, IPAddress.is_valid("2002::1"))
        assertEquals(true, IPAddress.is_valid("dead:beef:cafe:babe::f0ad"))
        assertEquals(false, IPAddress.is_valid("10.0.0.256"))
        assertEquals(false, IPAddress.is_valid("10.0.0.0.0"))
        assertEquals(true, IPAddress.is_valid("10.0.0"))
        assertEquals(true, IPAddress.is_valid("10.0"))
        assertEquals(false, IPAddress.is_valid("2002:516:2:200"))
        assertEquals(false, IPAddress.is_valid("2002:::1"))
    }

    @Test
    fun test_module_method_valid_ipv4_netmark() {
        assertEquals(true, IPAddress.is_valid_netmask("255.255.255.0"))
        assertEquals(false, IPAddress.is_valid_netmask("10.0.0.1"))
    }

    @Test
    fun test_summarize() {
        val netstr = mutableListOf<String>()
        val ranges = arrayOf(
                Range(1, 10), Range(11, 127),
                Range(128, 169), Range(170, 172),
                Range(173, 192), Range(193, 224)
        )
        for (range in ranges) {
            for (i in range.start until range.stop) {
                netstr.add(String.format("%d.0.0.0/8", i))
            }
        }
        for (i in 0 until 256) {
            if (i != 254) {
                netstr.add(String.format("169.%d.0.0/16", i))
            }
        }
        for (i in 0 until 256) {
            if (i < 16 || 31 < i) {
                netstr.add(String.format("172.%d.0.0/16", i))
            }
        }
        for (i in 0 until 256) {
            if (i != 168) {
                netstr.add(String.format("192.%d.0.0/16", i))
            }
        }
        val ip_addresses = mutableListOf<IPAddress>()
        for (net in netstr) {
            ip_addresses.add(IPAddress.parse(net).unwrap())
        }

        val empty_vec = emptyList<String>()
        assertEquals(IPAddress.summarize_str(empty_vec).unwrap().size, 0)
        val sone = IPAddress.summarize_str(listOf("10.1.0.4/24")).unwrap()
        val one = IPAddress.to_string_vec(sone)
        assertArrayEquals(one, listOf("10.1.0.0/24"))
        assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize_str(listOf("2000:1::4711/32"))
                .unwrap()),
                listOf("2000:1::/32"))

        assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize_str(listOf("10.1.0.4/24",
                "7.0.0.0/0",
                "1.2.3.4/4"))
                .unwrap()), listOf("0.0.0.0/0"))
        val tmp = IPAddress.to_string_vec(IPAddress.summarize_str(listOf("2000:1::/32",
                "3000:1::/32",
                "2000:2::/32",
                "2000:3::/32",
                "2000:4::/32",
                "2000:5::/32",
                "2000:6::/32",
                "2000:7::/32",
                "2000:8::/32"))
                .unwrap())
        assertArrayEquals(tmp,
                listOf("2000:1::/32", "2000:2::/31", "2000:4::/30", "2000:8::/32", "3000:1::/32"))

        assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize_str(listOf("10.0.1.1/24",
                "30.0.1.0/16",
                "10.0.2.0/24",
                "10.0.3.0/24",
                "10.0.4.0/24",
                "10.0.5.0/24",
                "10.0.6.0/24",
                "10.0.7.0/24",
                "10.0.8.0/24"))
                .unwrap()),
                listOf("10.0.1.0/24", "10.0.2.0/23", "10.0.4.0/22", "10.0.8.0/24", "30.0.0.0/16"))

        assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize_str(listOf("10.0.0.0/23",
                "10.0.2.0/24"))
                .unwrap()),
                listOf("10.0.0.0/23", "10.0.2.0/24"))
        assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize_str(listOf("10.0.0.0/24",
                "10.0.1.0/24",
                "10.0.2.0/23"))
                .unwrap()),
                listOf("10.0.0.0/22"))


        assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize_str(listOf("10.0.0.0/16",
                "10.0.2.0/24"))
                .unwrap()),
                listOf("10.0.0.0/16"))

        val cnt = 10
        for (i in 0 until cnt) {
            assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize(ip_addresses)),
                    listOf("1.0.0.0/8",
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
                            "208.0.0.0/4"))
        }
        // end
        // printer = RubyProf::GraphPrinter.new(result)
        // printer.print(STDOUT, {})
        // test imutable input parameters
        val a1 = IPAddress.parse("10.0.0.1/24").unwrap()
        val a2 = IPAddress.parse("10.0.1.1/24").unwrap()
        assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize(listOf(a1, a2))), listOf("10.0.0.0/23"))
        assertEquals("10.0.0.1/24", a1.to_string())
        assertEquals("10.0.1.1/24", a2.to_string())
    }
}
