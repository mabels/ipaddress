package com.adviser.ipaddress.java

import org.junit.Test
import static org.junit.Assert.assertEquals
import static org.junit.Assert.assertArrayEquals
import static org.junit.Assert.assertTrue
import java.util.HashMap
import java.util.List
import java.util.Vector
import java.math.BigInteger

class TestIpv4 {
    
    static class IPv4Prefix {
        public String ip
        public int prefix
        new(String ip, int prefix) {
          this.ip = ip
          this.prefix = prefix
        }
    }

    static class IPv4Test {
        public HashMap<String, IPv4Prefix> valid_ipv4 = new HashMap<String, IPv4Prefix>()
        public List<String> invalid_ipv4
        public List<String> valid_ipv4_range
        public HashMap<String, String> netmask_values = new HashMap<String, String>()
        public HashMap<String, Long> decimal_values = new HashMap<String, Long>()
        public IPAddress ip
        public IPAddress network
        public HashMap<String, String> networks = new HashMap<String, String>()
        public HashMap<String, String> broadcast = new HashMap<String, String>()
        public IPAddress class_a
        public IPAddress class_b
        public IPAddress class_c
        public HashMap<String, Integer> classful = new HashMap<String, Integer>()
        new(List<String> invalid_ipv4, List<String> valid_ipv4_range,
          IPAddress ip, IPAddress network, IPAddress class_a,
          IPAddress class_b, IPAddress class_c) {
          this.invalid_ipv4 = invalid_ipv4
          this.valid_ipv4_range = valid_ipv4_range
          this.ip = ip
          this.network = network
          this.class_a = class_a
          this.class_b = class_b
          this.class_c = class_c
        }
    }
    static def IPv4Test setup() {
        var ipv4t = new IPv4Test(
            #["10.0.0.256", "10.0.0.0.0"],
            #["10.0.0.1-254", "10.0.1-254.0", "10.1-254.0.0"],
            IpV4.create("172.16.10.1/24").unwrap(),
            IpV4.create("172.16.10.0/24").unwrap(),
            IpV4.create("10.0.0.1/8").unwrap(),
            IpV4.create("172.16.0.1/16").unwrap(),
            IpV4.create("192.168.0.1/24").unwrap());
        ipv4t.valid_ipv4.put("9.9/17",
                                new IPv4Prefix(
                                    "9.0.0.9",
                                     17
                                ));
        ipv4t.valid_ipv4.put("100.1.100",
                                new IPv4Prefix(
                                    "100.1.0.100",
                                     32
                                ));
        ipv4t.valid_ipv4.put("0.0.0.0/0",
                                new IPv4Prefix(
                                    "0.0.0.0",
                                     0
                                ));
        ipv4t.valid_ipv4.put("10.0.0.0",
                                new IPv4Prefix(
                                    "10.0.0.0",
                                     32
                                ));
        ipv4t.valid_ipv4.put("10.0.0.1",
                                new IPv4Prefix(
                                    "10.0.0.1",
                                     32
                                ));
        ipv4t.valid_ipv4.put("10.0.0.1/24",
                                new IPv4Prefix(
                                    "10.0.0.1",
                                     24
                                ));
        ipv4t.valid_ipv4.put("10.0.0.9/255.255.255.0",
                                new IPv4Prefix(
                                    "10.0.0.9",
                                     24
                                ));

        ipv4t.netmask_values.put("0.0.0.0/0", "0.0.0.0");
        ipv4t.netmask_values.put("10.0.0.0/8", "255.0.0.0");
        ipv4t.netmask_values.put("172.16.0.0/16", "255.255.0.0");
        ipv4t.netmask_values.put("192.168.0.0/24", "255.255.255.0");
        ipv4t.netmask_values.put("192.168.100.4/30", "255.255.255.252");

        ipv4t.decimal_values.put("0.0.0.0/0", 0l);
        ipv4t.decimal_values.put("10.0.0.0/8", 167772160l);
        ipv4t.decimal_values.put("172.16.0.0/16", 2886729728l);
        ipv4t.decimal_values.put("192.168.0.0/24", 3232235520l);
        ipv4t.decimal_values.put("192.168.100.4/30", 3232261124l);

        ipv4t.ip = IPAddress.parse("172.16.10.1/24").unwrap();
        ipv4t.network = IPAddress.parse("172.16.10.0/24").unwrap();

        ipv4t.broadcast.put("10.0.0.0/8", "10.255.255.255/8");
        ipv4t.broadcast.put("172.16.0.0/16", "172.16.255.255/16");
        ipv4t.broadcast.put("192.168.0.0/24", "192.168.0.255/24");
        ipv4t.broadcast.put("192.168.100.4/30", "192.168.100.7/30");

        ipv4t.networks.put("10.5.4.3/8", "10.0.0.0/8");
        ipv4t.networks.put("172.16.5.4/16", "172.16.0.0/16");
        ipv4t.networks.put("192.168.4.3/24", "192.168.4.0/24");
        ipv4t.networks.put("192.168.100.5/30", "192.168.100.4/30");

        ipv4t.class_a = IPAddress.parse("10.0.0.1/8").unwrap();
        ipv4t.class_b = IPAddress.parse("172.16.0.1/16").unwrap();
        ipv4t.class_c = IPAddress.parse("192.168.0.1/24").unwrap();

        ipv4t.classful.put("10.1.1.1", 8);
        ipv4t.classful.put("150.1.1.1", 16);
        ipv4t.classful.put("200.1.1.1", 24);
        return ipv4t;
    }


   @Test
    public def test_initialize() {
        val setup = setup();
        setup.valid_ipv4.forEach[i, x |
            val ip = IPAddress.parse(i).unwrap();
            assertTrue(ip.is_ipv4() && !ip.is_ipv6());
        ]
        assertEquals(32, setup.ip.prefix.ip_bits.bits);
        assertTrue(IPAddress.parse("1.f.13.1/-3").isErr());
        assertTrue(IPAddress.parse("10.0.0.0/8").isOk());
    }
   @Test
    public def test_initialize_format_error() {
        setup().invalid_ipv4.forEach[i|
            assertTrue(IPAddress.parse(i).isErr());
        ]
        assertTrue(IPAddress.parse("10.0.0.0/asd").isErr());
    }
   @Test
    public def test_initialize_without_prefix() {
        assertTrue(IPAddress.parse("10.10.0.0").isOk());
        val ip = IPAddress.parse("10.10.0.0").unwrap();
        assertTrue(!ip.is_ipv6() && ip.is_ipv4());
        assertEquals(32, ip.prefix.num);
    }
   @Test
    public def test_attributes() {
        setup().valid_ipv4.forEach[arg, attr |
            val ip = IPAddress.parse(arg).unwrap();
            // println!("test_attributes:{}:{:?}", arg, attr);
            assertEquals(attr.ip, ip.to_s());
            assertEquals(attr.prefix, ip.prefix.num);
        ]
    }
   @Test
    public def test_octets() {
        val ip = IPAddress.parse("10.1.2.3/8").unwrap();
        assertArrayEquals(ip.parts(), #[10, 1, 2, 3]);
    }
   @Test
    public def test_method_to_string() {
        setup().valid_ipv4.forEach[arg, attr |
            val ip = IPAddress.parse(arg).unwrap();
            assertEquals(String.format("%s/%d", attr.ip, attr.prefix), ip.to_string());
        ]
    }
   @Test
    public def test_method_to_s() {
        setup().valid_ipv4.forEach[arg, attr |
            val ip = IPAddress.parse(arg).unwrap();
            assertEquals(attr.ip, ip.to_s());
            // val ip_c = IPAddress.parse(arg).unwrap();
            // assertEquals(attr.ip, ip.to_s());
        ]
    }
   @Test
    public def test_netmask() {
        setup().netmask_values.forEach[addr, mask|
            val ip = IPAddress.parse(addr).unwrap();
            assertEquals(ip.netmask().to_s(), mask);
        ]
    }
   @Test
    public def test_method_to_u32() {
        setup().decimal_values.forEach[addr, value|
            val ip = IPAddress.parse(addr).unwrap();
            assertEquals(ip.host_address.longValue(), value);
        ]
    }
   @Test
    public def test_method_is_network() {
        assertEquals(true, setup().network.is_network());
        assertEquals(false, setup().ip.is_network());
    }
   @Test
    public def test_one_address_network() {
        val network = IPAddress.parse("172.16.10.1/32").unwrap();
        assertEquals(false, network.is_network());
    }
   @Test
    public def test_method_broadcast() {
        setup().broadcast.forEach[addr, bcast |
            val ip = IPAddress.parse(addr).unwrap();
            assertEquals(bcast, ip.broadcast().to_string());
        ]
    }
   @Test
    public def test_method_network() {
        setup().networks.forEach[addr, net|
            val ip = IPAddress.parse(addr).unwrap();
            assertEquals(net, ip.network().to_string());
        ]
    }

   @Test
    public def test_method_bits() {
        val ip = IPAddress.parse("127.0.0.1").unwrap();
        assertEquals("01111111000000000000000000000001", ip.bits());
    }
   @Test
    public def test_method_first() {
        var ip = IPAddress.parse("192.168.100.0/24").unwrap();
        assertEquals("192.168.100.1", ip.first().to_s());
        ip = IPAddress.parse("192.168.100.50/24").unwrap();
        assertEquals("192.168.100.1", ip.first().to_s());
    }
   @Test
    public def test_method_last() {
        var ip = IPAddress.parse("192.168.100.0/24").unwrap();
        assertEquals("192.168.100.254", ip.last().to_s());
        ip = IPAddress.parse("192.168.100.50/24").unwrap();
        assertEquals("192.168.100.254", ip.last().to_s());
    }
   @Test
    public def test_method_each_host() {
        val ip = IPAddress.parse("10.0.0.1/29").unwrap();
        val arr = new Vector<String>()
        ip.each_host([i| arr.add(i.to_s()) ]);
        assertArrayEquals(arr,
                   #["10.0.0.1", "10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6"]);
    }
   @Test
    public def test_method_each() {
        val ip = IPAddress.parse("10.0.0.1/29").unwrap();
        val arr = new Vector<String>()
        ip.each([i| arr.add(i.to_s())]);
        assertArrayEquals(arr,
                   #["10.0.0.0", "10.0.0.1", "10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5",
                    "10.0.0.6", "10.0.0.7"]);
    }
   @Test
    public def test_method_size() {
        val ip = IPAddress.parse("10.0.0.1/29").unwrap();
        assertEquals(ip.size(), new BigInteger("8"));
    }
   @Test
    public def test_method_network_u32() {
        assertEquals(2886732288l,
                   setup().ip.network().host_address.longValue())
    }
   @Test
    public def test_method_broadcast_u32() {
        assertEquals(2886732543l,
                   setup().ip.broadcast().host_address.longValue())
    }
   @Test
    public def test_method_include() {
        var ip = IPAddress.parse("192.168.10.100/24").unwrap();
        val addr = IPAddress.parse("192.168.10.102/24").unwrap();
        assertEquals(true, ip.includes(addr));
        assertEquals(false,
                   ip.includes(IPAddress.parse("172.16.0.48").unwrap()));
        ip = IPAddress.parse("10.0.0.0/8").unwrap();
        assertEquals(true, ip.includes(IPAddress.parse("10.0.0.0/9").unwrap()));
        assertEquals(true, ip.includes(IPAddress.parse("10.1.1.1/32").unwrap()));
        assertEquals(true, ip.includes(IPAddress.parse("10.1.1.1/9").unwrap()));
        assertEquals(false,
                   ip.includes(IPAddress.parse("172.16.0.0/16").unwrap()));
        assertEquals(false, ip.includes(IPAddress.parse("10.0.0.0/7").unwrap()));
        assertEquals(false, ip.includes(IPAddress.parse("5.5.5.5/32").unwrap()));
        assertEquals(false, ip.includes(IPAddress.parse("11.0.0.0/8").unwrap()));
        ip = IPAddress.parse("13.13.0.0/13").unwrap();
        assertEquals(false,
                   ip.includes(IPAddress.parse("13.16.0.0/32").unwrap()));
    }
   @Test
    public def test_method_include_all() {
        val ip = IPAddress.parse("192.168.10.100/24").unwrap();
        val addr1 = IPAddress.parse("192.168.10.102/24").unwrap();
        val addr2 = IPAddress.parse("192.168.10.103/24").unwrap();
        assertEquals(true, ip.includes_all(#[addr1, addr2]));
        assertEquals(false,
                   ip.includes_all(#[addr1, IPAddress.parse("13.16.0.0/32").unwrap()]));
    }
   @Test
    public def test_method_ipv4() {
        assertEquals(true, setup().ip.is_ipv4());
    }
   @Test
    public def test_method_ipv6() {
        assertEquals(false, setup().ip.is_ipv6());
    }
   @Test
    public def test_method_private() {
        assertEquals(true,
                   IPAddress.parse("169.254.10.50/24").unwrap().is_private());
        assertEquals(true,
                   IPAddress.parse("192.168.10.50/24").unwrap().is_private());
        assertEquals(true,
                   IPAddress.parse("192.168.10.50/16").unwrap().is_private());
        assertEquals(true,
                   IPAddress.parse("172.16.77.40/24").unwrap().is_private());
        assertEquals(true,
                   IPAddress.parse("172.16.10.50/14").unwrap().is_private());
        assertEquals(true,
                   IPAddress.parse("10.10.10.10/10").unwrap().is_private());
        assertEquals(true, IPAddress.parse("10.0.0.0/8").unwrap().is_private());
        assertEquals(false,
                   IPAddress.parse("192.168.10.50/12").unwrap().is_private());
        assertEquals(false, IPAddress.parse("3.3.3.3").unwrap().is_private());
        assertEquals(false, IPAddress.parse("10.0.0.0/7").unwrap().is_private());
        assertEquals(false,
                   IPAddress.parse("172.32.0.0/12").unwrap().is_private());
        assertEquals(false,
                   IPAddress.parse("172.16.0.0/11").unwrap().is_private());
        assertEquals(false,
                   IPAddress.parse("192.0.0.2/24").unwrap().is_private());
    }
   @Test
    public def test_method_octet() {
        assertEquals(setup().ip.parts().get(0), 172);
        assertEquals(setup().ip.parts().get(1), 16);
        assertEquals(setup().ip.parts().get(2), 10);
        assertEquals(setup().ip.parts().get(3), 1);
    }
   @Test
    public def test_method_a() {
        assertEquals(true, IpV4.is_class_a(setup().class_a));
        assertEquals(false, IpV4.is_class_a(setup().class_b));
        assertEquals(false, IpV4.is_class_a(setup().class_c));
    }
   @Test
    public def test_method_b() {
        assertEquals(true, IpV4.is_class_b(setup().class_b));
        assertEquals(false, IpV4.is_class_b(setup().class_a));
        assertEquals(false, IpV4.is_class_b(setup().class_c));
    }
   @Test
    public def test_method_c() {
        assertEquals(true, IpV4.is_class_c(setup().class_c));
        assertEquals(false, IpV4.is_class_c(setup().class_a));
        assertEquals(false, IpV4.is_class_c(setup().class_b));
    }
   @Test
    public def test_method_to_ipv6() {
        assertEquals("::ac10:a01", setup().ip.to_ipv6().to_s());
    }
   @Test
    public def test_method_reverse() {
        assertEquals(setup().ip.dns_reverse(), "10.16.172.in-addr.arpa");
    }
   @Test
    public def test_method_dns_rev_domains() {
        assertArrayEquals(IPAddress.parse("173.17.5.1/23").unwrap().dns_rev_domains(),
                   #["4.17.173.in-addr.arpa", "5.17.173.in-addr.arpa"]);
        assertArrayEquals(IPAddress.parse("173.17.1.1/15").unwrap().dns_rev_domains(),
                   #["16.173.in-addr.arpa", "17.173.in-addr.arpa"]);
        assertArrayEquals(IPAddress.parse("173.17.1.1/7").unwrap().dns_rev_domains(),
                   #["172.in-addr.arpa", "173.in-addr.arpa"]);
        assertArrayEquals(IPAddress.parse("173.17.1.1/29").unwrap().dns_rev_domains(),
                   #[
                       "0.1.17.173.in-addr.arpa",
                       "1.1.17.173.in-addr.arpa",
                       "2.1.17.173.in-addr.arpa",
                       "3.1.17.173.in-addr.arpa",
                       "4.1.17.173.in-addr.arpa",
                       "5.1.17.173.in-addr.arpa",
                       "6.1.17.173.in-addr.arpa",
                       "7.1.17.173.in-addr.arpa"
                    ]);
        assertArrayEquals(IPAddress.parse("174.17.1.1/24").unwrap().dns_rev_domains(),
                   #["1.17.174.in-addr.arpa"]);
        assertArrayEquals(IPAddress.parse("175.17.1.1/16").unwrap().dns_rev_domains(),
                   #["17.175.in-addr.arpa"]);
        assertArrayEquals(IPAddress.parse("176.17.1.1/8").unwrap().dns_rev_domains(),
                   #["176.in-addr.arpa"]);
        assertArrayEquals(IPAddress.parse("177.17.1.1/0").unwrap().dns_rev_domains(),
                   #["in-addr.arpa"]);
        assertArrayEquals(IPAddress.parse("178.17.1.1/32").unwrap().dns_rev_domains(),
                   #["1.1.17.178.in-addr.arpa"]);
    }
   @Test
    public def test_method_compare() {
        var ip1 = IPAddress.parse("10.1.1.1/8").unwrap();
        var ip2 = IPAddress.parse("10.1.1.1/16").unwrap();
        var ip3 = IPAddress.parse("172.16.1.1/14").unwrap();
        val ip4 = IPAddress.parse("10.1.1.1/8").unwrap();

        // ip2 should be greater than ip1
        assertEquals(true, ip1.lt(ip2));
        assertEquals(false, ip1.gt(ip2));
        assertEquals(false, ip2.lt(ip1));
        // ip2 should be less than ip3
        assertEquals(true, ip2.lt(ip3));
        assertEquals(false, ip2.gt(ip3));
        // ip1 should be less than ip3
        assertEquals(true, ip1.lt(ip3));
        assertEquals(false, ip1.gt(ip3));
        assertEquals(false, ip3.lt(ip1));
        // ip1 should be equal to itself
        assertEquals(true, ip1.equal(ip1));
        // ip1 should be equal to ip4
        assertEquals(true, ip1.equal(ip4));
        // test sorting
        var res = IPAddress.sort(#[ip1, ip2, ip3]);
        assertArrayEquals(IPAddress.to_string_vec(res),
                   #["10.1.1.1/8", "10.1.1.1/16", "172.16.1.1/14"]);
        // test same prefix
        ip1 = IPAddress.parse("10.0.0.0/24").unwrap();
        ip2 = IPAddress.parse("10.0.0.0/16").unwrap();
        ip3 = IPAddress.parse("10.0.0.0/8").unwrap();
        {
            res = IPAddress.sort(#[ip1, ip2, ip3]);
            assertArrayEquals(IPAddress.to_string_vec(res),
                       #["10.0.0.0/8", "10.0.0.0/16", "10.0.0.0/24"]);
        }
    }
   @Test
    public def test_method_minus() {
        val ip1 = IPAddress.parse("10.1.1.1/8").unwrap();
        val ip2 = IPAddress.parse("10.1.1.10/8").unwrap();
        assertEquals(9, ip2.sub(ip1).intValue());
        assertEquals(9, ip1.sub(ip2).intValue());
    }
   @Test
    public def test_method_plus() {
        var ip1 = IPAddress.parse("172.16.10.1/24").unwrap();
        var ip2 = IPAddress.parse("172.16.11.2/24").unwrap();
        assertArrayEquals(IPAddress.to_string_vec(ip1.add(ip2)), #["172.16.10.0/23"]);

        ip2 = IPAddress.parse("172.16.12.2/24").unwrap();
        assertArrayEquals(IPAddress.to_string_vec(ip1.add(ip2)),
                   #[ip1.network().to_string(), ip2.network().to_string()]);

        ip1 = IPAddress.parse("10.0.0.0/23").unwrap();
        ip2 = IPAddress.parse("10.0.2.0/24").unwrap();
        assertArrayEquals(IPAddress.to_string_vec(ip1.add(ip2)),
                   #["10.0.0.0/23", "10.0.2.0/24"]);

        ip1 = IPAddress.parse("10.0.0.0/23").unwrap();
        ip2 = IPAddress.parse("10.0.2.0/24").unwrap();
        assertArrayEquals(IPAddress.to_string_vec(ip1.add(ip2)),
                   #["10.0.0.0/23", "10.0.2.0/24"]);

        ip1 = IPAddress.parse("10.0.0.0/16").unwrap();
        ip2 = IPAddress.parse("10.0.2.0/24").unwrap();
        assertArrayEquals(IPAddress.to_string_vec(ip1.add(ip2)), 
            #["10.0.0.0/16"]);

        ip1 = IPAddress.parse("10.0.0.0/23").unwrap();
        ip2 = IPAddress.parse("10.1.0.0/24").unwrap();
        assertArrayEquals(IPAddress.to_string_vec(ip1.add(ip2)),
                   #["10.0.0.0/23", "10.1.0.0/24"]);
    }
   @Test
    public def test_method_netmask_equal() {
        val ip = IPAddress.parse("10.1.1.1/16").unwrap();
        assertEquals(16, ip.prefix.num);
        val ip2 = ip.change_netmask("255.255.255.0").unwrap();
        assertEquals(24, ip2.prefix.num);
    }
   @Test
    public def test_method_split() {
        assertTrue(setup().ip.split(0).isErr());
        assertTrue(setup().ip.split(257).isErr());

        assertArrayEquals(setup().ip.split(1).unwrap(), #[setup().ip.network()]);

        assertArrayEquals(IPAddress.to_string_vec(setup().network.split(8).unwrap()),
                   #["172.16.10.0/27",
                    "172.16.10.32/27",
                    "172.16.10.64/27",
                    "172.16.10.96/27",
                    "172.16.10.128/27",
                    "172.16.10.160/27",
                    "172.16.10.192/27",
                    "172.16.10.224/27"]);

        assertArrayEquals(IPAddress.to_string_vec(setup().network.split(7).unwrap()),
                   #["172.16.10.0/27",
                    "172.16.10.32/27",
                    "172.16.10.64/27",
                    "172.16.10.96/27",
                    "172.16.10.128/27",
                    "172.16.10.160/27",
                    "172.16.10.192/26"]);

        assertArrayEquals(IPAddress.to_string_vec(setup().network.split(6).unwrap()),
                   #["172.16.10.0/27",
                    "172.16.10.32/27",
                    "172.16.10.64/27",
                    "172.16.10.96/27",
                    "172.16.10.128/26",
                    "172.16.10.192/26"]);
        assertArrayEquals(IPAddress.to_string_vec(setup().network.split(5).unwrap()),
                   #["172.16.10.0/27",
                    "172.16.10.32/27",
                    "172.16.10.64/27",
                    "172.16.10.96/27",
                    "172.16.10.128/25"]);
        assertArrayEquals(IPAddress.to_string_vec(setup().network.split(4).unwrap()),
                   #["172.16.10.0/26", "172.16.10.64/26", "172.16.10.128/26", "172.16.10.192/26"]);
        assertArrayEquals(IPAddress.to_string_vec(setup().network.split(3).unwrap()),
                   #["172.16.10.0/26", "172.16.10.64/26", "172.16.10.128/25"]);
        assertArrayEquals(IPAddress.to_string_vec(setup().network.split(2).unwrap()),
                   #["172.16.10.0/25", "172.16.10.128/25"]);
        assertArrayEquals(IPAddress.to_string_vec(setup().network.split(1).unwrap()),
                   #["172.16.10.0/24"]);
    }
   @Test
    public def test_method_subnet() {
        assertTrue(setup().network.subnet(23).isErr());
        assertTrue(setup().network.subnet(33).isErr());
        assertTrue(setup().ip.subnet(30).isOk());
        assertArrayEquals(IPAddress.to_string_vec(setup().network.subnet(26).unwrap()),
                                 #["172.16.10.0/26",
                                  "172.16.10.64/26",
                                  "172.16.10.128/26",
                                  "172.16.10.192/26"]);
        assertArrayEquals(IPAddress.to_string_vec(setup().network.subnet(25).unwrap()),
                   #["172.16.10.0/25", "172.16.10.128/25"]);
        assertArrayEquals(IPAddress.to_string_vec(setup().network.subnet(24).unwrap()),
                   #["172.16.10.0/24"]);
    }
   @Test
    public def test_method_supernet() {
        assertTrue(setup().ip.supernet(24).isErr());
        assertEquals("0.0.0.0/0", setup().ip.supernet(0).unwrap().to_string());
        // assertEquals("0.0.0.0/0", setup().ip.supernet(-2).unwrap().to_string());
        assertEquals("172.16.10.0/23",
                   setup().ip.supernet(23).unwrap().to_string());
        assertEquals("172.16.8.0/22",
                   setup().ip.supernet(22).unwrap().to_string());
    }
   @Test
    public def test_classmethod_parse_u32() {
        setup().decimal_values.forEach[addr,value |
            val ip = IpV4.from_u32(value.longValue(), 32).unwrap();
            val splitted = addr.split("/")
            val ip2 = ip.change_prefix(Integer.parseInt(splitted.get(1))).unwrap();
            assertEquals(ip2.to_string(), addr);
        ]
    }

    // public def test_classhmethod_extract() {
    //   val str = "foobar172.16.10.1barbaz";
    //   assertEquals("172.16.10.1", IPAddress.extract(str).to_s
    // }
   @Test
    public def test_classmethod_summarize() {

        // Should return self if only one network given
        assertArrayEquals(IPAddress.summarize(#[setup().ip]),
                   #[setup().ip.network()]);

        // Summarize homogeneous networks
        var ip1 = IPAddress.parse("172.16.10.1/24").unwrap();
        var ip2 = IPAddress.parse("172.16.11.2/24").unwrap();
        assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize(#[ip1, ip2])),
                   #["172.16.10.0/23"]);

            ip1 = IPAddress.parse("10.0.0.1/24").unwrap();
            ip2 = IPAddress.parse("10.0.1.1/24").unwrap();
            var ip3 = IPAddress.parse("10.0.2.1/24").unwrap();
            var ip4 = IPAddress.parse("10.0.3.1/24").unwrap();
            assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize(#[ip1, ip2, ip3, ip4])),
                       #["10.0.0.0/22"]);

            ip1 = IPAddress.parse("10.0.0.1/24").unwrap();
            ip2 = IPAddress.parse("10.0.1.1/24").unwrap();
            ip3 = IPAddress.parse("10.0.2.1/24").unwrap();
            ip4 = IPAddress.parse("10.0.3.1/24").unwrap();
            assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize(#[ip4, ip3, ip2, ip1])),
                       #["10.0.0.0/22"]);

        // Summarize non homogeneous networks
        ip1 = IPAddress.parse("10.0.0.0/23").unwrap();
        ip2 = IPAddress.parse("10.0.2.0/24").unwrap();
        assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize(#[ip1, ip2])),
                   #["10.0.0.0/23", "10.0.2.0/24"]);

        ip1 = IPAddress.parse("10.0.0.0/16").unwrap();
        ip2 = IPAddress.parse("10.0.2.0/24").unwrap();
        assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize(#[ip1, ip2])),
                   #["10.0.0.0/16"]);

        ip1 = IPAddress.parse("10.0.0.0/23").unwrap();
        ip2 = IPAddress.parse("10.1.0.0/24").unwrap();
        assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize(#[ip1, ip2])),
                   #["10.0.0.0/23", "10.1.0.0/24"]);

        ip1 = IPAddress.parse("10.0.0.0/23").unwrap();
        ip2 = IPAddress.parse("10.0.2.0/23").unwrap();
        ip3 = IPAddress.parse("10.0.4.0/24").unwrap();
        ip4 = IPAddress.parse("10.0.6.0/24").unwrap();
        assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize(#[ip1, ip2, ip3, ip4])),
                   #["10.0.0.0/22", "10.0.4.0/24", "10.0.6.0/24"]);
        
        ip1 = IPAddress.parse("10.0.1.1/24").unwrap();
        ip2 = IPAddress.parse("10.0.2.1/24").unwrap();
        ip3 = IPAddress.parse("10.0.3.1/24").unwrap();
        ip4 = IPAddress.parse("10.0.4.1/24").unwrap();
        assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize(#[ip1, ip2, ip3, ip4])),
                   #["10.0.1.0/24", "10.0.2.0/23", "10.0.4.0/24"]);
        
        
        ip1 = IPAddress.parse("10.0.1.1/24").unwrap();
        ip2 = IPAddress.parse("10.0.2.1/24").unwrap();
        ip3 = IPAddress.parse("10.0.3.1/24").unwrap();
        ip4 = IPAddress.parse("10.0.4.1/24").unwrap();
        assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize(#[ip4, ip3, ip2, ip1])),
                   #["10.0.1.0/24", "10.0.2.0/23", "10.0.4.0/24"]);

        ip1 = IPAddress.parse("10.0.1.1/24").unwrap();
        ip2 = IPAddress.parse("10.10.2.1/24").unwrap();
        ip3 = IPAddress.parse("172.16.0.1/24").unwrap();
        ip4 = IPAddress.parse("172.16.1.1/24").unwrap();
        assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize(#[ip1, ip2, ip3, ip4])),
                   #["10.0.1.0/24", "10.10.2.0/24", "172.16.0.0/23"]);

        var ips = #[IPAddress.parse("10.0.0.12/30").unwrap(),
                           IPAddress.parse("10.0.100.0/24").unwrap()];
        assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize(ips)),
                   #["10.0.0.12/30", "10.0.100.0/24"]);

        ips = #[IPAddress.parse("172.16.0.0/31").unwrap(),
                   IPAddress.parse("10.10.2.1/32").unwrap()];
        assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize(ips)),
                   #["10.10.2.1/32", "172.16.0.0/31"]);

        ips = #[IPAddress.parse("172.16.0.0/32").unwrap(),
                   IPAddress.parse("10.10.2.1/32").unwrap()];
        assertArrayEquals(IPAddress.to_string_vec(IPAddress.summarize(ips)),
                   #["10.10.2.1/32", "172.16.0.0/32"]);
    }

   @Test
    public def test_classmethod_parse_classful() {
        setup().classful.forEach[ip, prefix |
            val res = IpV4.parse_classful(ip).unwrap();
            assertEquals(prefix, res.prefix.num);
            assertEquals(String.format("%s/%d", ip, prefix), res.to_string());
        ]
        assertTrue(IpV4.parse_classful("192.168.256.257").isErr());
    }
}
