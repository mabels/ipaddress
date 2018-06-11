package com.adviser.ipaddress

import java.math.BigInteger
import kotlin.test.assertEquals

class IPv6MappedTest(IPAddress ip, String s, String sstr,
    String string, BigInteger u128, String address) {
    public IPAddress ip
    public String s
    public String sstr
    public String string
    public BigInteger u128
    public String address
    HashMap<String, BigInteger> valid_mapped = HashMap<String, BigInteger>()
    HashMap<String, BigInteger> valid_mapped_ipv6 = HashMap<String, BigInteger>()
    HashMap<String, String> valid_mapped_ipv6_conversion = HashMap<String, String>()
        this.ip = ip
        this.s = s
        this.sstr = sstr
        this.string = string
        this.u128 = u128
        this.address = address
    }
}

class TestIpv6Mapped {

    public fun IPv6MappedTest setup() {
        val ret = IPv6MappedTest(
            Ipv6Mapped.create("::172.16.10.1").unwrap(),
            "::ffff:172.16.10.1",
            "::ffff:172.16.10.1/32",
            "0000:0000:0000:0000:0000:ffff:ac10:0a01/128",
            BigInteger("281473568475649"),
            "::ffff:ac10:a01/128");
        ret.valid_mapped.put("::13.1.68.3", BigInteger("281470899930115"));
        ret.valid_mapped.put("0:0:0:0:0:ffff:129.144.52.38",
                            BigInteger("281472855454758"));
        ret.valid_mapped.put("::ffff:129.144.52.38",
                            BigInteger("281472855454758"));
        ret.valid_mapped_ipv6.put("::ffff:13.1.68.3", BigInteger("281470899930115"));
        ret.valid_mapped_ipv6.put("0:0:0:0:0:ffff:8190:3426",
                                 BigInteger("281472855454758"));
        ret.valid_mapped_ipv6.put("::ffff:8190:3426",
                                 BigInteger("281472855454758"));
        ret.valid_mapped_ipv6_conversion.put("::ffff:13.1.68.3", "13.1.68.3");
        ret.valid_mapped_ipv6_conversion.put("0:0:0:0:0:ffff:8190:3426", "129.144.52.38");
        ret.valid_mapped_ipv6_conversion.put("::ffff:8190:3426", "129.144.52.38");
        return ret
    }


    @Test
    public fun test_initialize() {
        val s = setup();
        assertEquals(true, IPAddress.parse("::172.16.10.1").isOk());
        s.valid_mapped.forEach[ip, u128 |
            //println!("-{}--{}", ip, u128);
            //if IPAddress.parse(ip).is_err() {
            //    println!("{}", IPAddress.parse(ip).unwrapErr());
            //}
            assertEquals(true, IPAddress.parse(ip).isOk());
            assertEquals(u128, IPAddress.parse(ip).unwrap().host_address);
        ]
        s.valid_mapped_ipv6.forEach[ip, u128 |
            //println!("===={}=={:x}", ip, u128);
            assertEquals(true, IPAddress.parse(ip).isOk());
            assertEquals(u128, IPAddress.parse(ip).unwrap().host_address);
        ]
    }
    @Test
    public fun test_mapped_from_ipv6_conversion() {
        setup().valid_mapped_ipv6_conversion.forEach[ip6, ip4 |
            //println!("+{}--{}", ip6, ip4);
            assertEquals(ip4, IPAddress.parse(ip6).unwrap().mapped.to_s());
        ]
    }
    @Test
    public fun test_attributes() {
        val s = setup();
        assertEquals(s.address, s.ip.to_string());
        assertEquals(128, s.ip.prefix.num);
        assertEquals(s.s, s.ip.to_s_mapped());
        assertEquals(s.sstr, s.ip.to_string_mapped());
        assertEquals(s.string, s.ip.to_string_uncompressed());
        assertEquals(s.u128, s.ip.host_address);
    }
    @Test
    public fun test_method_ipv6() {
        assertTrue(setup().ip.is_ipv6());
    }
    @Test
    public fun test_mapped() {
        assertTrue(setup().ip.is_mapped());
    }
}
