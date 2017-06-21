package com.adviser.ipaddress

import org.junit.Test;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertTrue;
import java.util.Vector

class TestIpAddress {

    static class IPAddressTest {
        public String valid_ipv4
        public String valid_ipv6
        public String valid_mapped
        public String invalid_ipv4
        public String invalid_ipv6
        public String invalid_mapped
        new(String valid_ipv4, String valid_ipv6, String valid_mapped,
            String invalid_ipv4, String invalid_ipv6, String invalid_mapped) {
            this.valid_ipv4 = valid_ipv4
            this.valid_ipv6 = valid_ipv6
            this.valid_mapped = valid_mapped
            this.invalid_ipv4 = invalid_ipv4
            this.invalid_ipv6 = invalid_ipv6
            this.invalid_mapped = invalid_mapped
        }
    }

    public def IPAddressTest setup() {
        return new IPAddressTest(
            "172.16.10.1/24",
            "2001:db8::8:800:200c:417a/64",
            "::13.1.68.3",
            "10.0.0.256",
            ":1:2:3:4:5:6:7",
            "::1:2.3.4");
    }

    @Test
    public def test_method_ipaddress() {
        assertTrue(IPAddress.parse(setup().valid_ipv4).isOk());
        assertTrue(IPAddress.parse(setup().valid_ipv6).isOk());
        assertTrue(IPAddress.parse(setup().valid_mapped).isOk());

        assertTrue(IPAddress.parse(setup().valid_ipv4).unwrap().is_ipv4());
        assertTrue(IPAddress.parse(setup().valid_ipv6).unwrap().is_ipv6());
        assertTrue(IPAddress.parse(setup().valid_mapped).unwrap().is_mapped());

        assertTrue(IPAddress.parse(setup().invalid_ipv4).isErr());
        assertTrue(IPAddress.parse(setup().invalid_ipv6).isErr());
        assertTrue(IPAddress.parse(setup().invalid_mapped).isErr());
    }
    @Test
    public def test_module_method_valid() {
        assertEquals(true, IPAddress.is_valid("10.0.0.1"));
        assertEquals(true, IPAddress.is_valid("10.0.0.0"));
        assertEquals(true, IPAddress.is_valid("2002::1"));
        assertEquals(true, IPAddress.is_valid("dead:beef:cafe:babe::f0ad"));
        assertEquals(false, IPAddress.is_valid("10.0.0.256"));
        assertEquals(false, IPAddress.is_valid("10.0.0.0.0"));
        assertEquals(true, IPAddress.is_valid("10.0.0"));
        assertEquals(true, IPAddress.is_valid("10.0"));
        assertEquals(false, IPAddress.is_valid("2002:516:2:200"));
        assertEquals(false, IPAddress.is_valid("2002:::1"));
    }
    @Test
    public def test_module_method_valid_ipv4_netmark() {
        assertEquals(true, IPAddress.is_valid_netmask("255.255.255.0"));
        assertEquals(false, IPAddress.is_valid_netmask("10.0.0.1"));
    }
    static class Ranger {
      public final int start
      public final int stop
      new(int start, int stop) {
        this.start = start
        this.stop = stop
      }
    }
    public static def Range(int start, int stop) {
        return new Ranger(start, stop)
    }

    @Test
    public def test_summarize() {
        val netstr = new Vector<String>()
        val ranges = #[
                     Range(1,10), Range(11,127), 
                     Range(128,169), Range(170,172), 
                     Range(173,192), Range(193,224)
                     ]
        for (range : ranges) {
            for (var i = range.start; i < range.stop; i++) {
                netstr.add(String.format("%d.0.0.0/8", i));
            }
        }
        for (var i = 0; i < 256; i++) {
            if (i != 254) {
                netstr.add(String.format("169.%d.0.0/16", i));
            }
        }
        for (var i = 0; i < 256; i++) {
            if (i < 16 || 31 < i) {
                netstr.add(String.format("172.%d.0.0/16", i));
            }
        }
        for (var i = 0; i < 256; i++) {
            if (i != 168) {
                netstr.add(String.format("192.%d.0.0/16", i));
            }
        }
        val ip_addresses = new Vector<IPAddress>()
        for (net : netstr) {
            ip_addresses.add(IPAddress.parse(net).unwrap());
        }

        val empty_vec = new Vector<String>();
        assertEquals(IPAddress.summarize_str(empty_vec).unwrap().length(), 0);
        val sone = IPAddress.summarize_str(#["10.1.0.4/24"]).unwrap()
        val one = IPAddress.to_string_vec(sone)
        assertArrayEquals(one, #["10.1.0.0/24"]);
        assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize_str(#["2000:1::4711/32"])
                       .unwrap()),
                   #["2000:1::/32"]);

        assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize_str(#["10.1.0.4/24",
                                                                           "7.0.0.0/0",
                                                                           "1.2.3.4/4"])
                       .unwrap()),
                   #["0.0.0.0/0"]);
        val tmp = IPAddress.to_string_vec(IPAddress.summarize_str(#["2000:1::/32",
                                                                           "3000:1::/32",
                                                                           "2000:2::/32",
                                                                           "2000:3::/32",
                                                                           "2000:4::/32",
                                                                           "2000:5::/32",
                                                                           "2000:6::/32",
                                                                           "2000:7::/32",
                                                                           "2000:8::/32"])
                       .unwrap())
        assertArrayEquals(tmp,
                   #["2000:1::/32", "2000:2::/31", "2000:4::/30", "2000:8::/32", "3000:1::/32"]);

        assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize_str(#["10.0.1.1/24",
                                                                           "30.0.1.0/16",
                                                                           "10.0.2.0/24",
                                                                           "10.0.3.0/24",
                                                                           "10.0.4.0/24",
                                                                           "10.0.5.0/24",
                                                                           "10.0.6.0/24",
                                                                           "10.0.7.0/24",
                                                                           "10.0.8.0/24"])
                       .unwrap()),
                   #["10.0.1.0/24", "10.0.2.0/23", "10.0.4.0/22", "10.0.8.0/24", "30.0.0.0/16"]);

        assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize_str(#["10.0.0.0/23",
                                                                       "10.0.2.0/24"])
                       .unwrap()),
                   #["10.0.0.0/23", "10.0.2.0/24"]);
        assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize_str(#["10.0.0.0/24",
                                                                           "10.0.1.0/24",
                                                                           "10.0.2.0/23"])
                       .unwrap()),
                   #["10.0.0.0/22"]);


        assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize_str(#["10.0.0.0/16",
                                                                           "10.0.2.0/24"])
                       .unwrap()),
                   #["10.0.0.0/16"]);

        val cnt = 10;
        for (var _ = 0; _ < cnt; _++) {
            assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize(ip_addresses)),
                       #["1.0.0.0/8",
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
                        "208.0.0.0/4"]);
        }
        // end
        // printer = RubyProf::GraphPrinter.new(result)
        // printer.print(STDOUT, {})
        // test imutable input parameters
        val a1 = IPAddress.parse("10.0.0.1/24").unwrap();
        val a2 = IPAddress.parse("10.0.1.1/24").unwrap();
        assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize(#[a1, a2])), #["10.0.0.0/23"]);
        assertEquals("10.0.0.1/24", a1.to_string());
        assertEquals("10.0.1.1/24", a2.to_string());
    }
}
