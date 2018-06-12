package com.adviser.ipaddress.java

import java.util.Vector
import java.util.HashMap
import java.util.List
import org.junit.Test
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertTrue;

class TestPrefix32 {

    static class Prefix32Test {
        String netmask0
        String netmask8
        String netmask16
        String netmask24
        String netmask30
        Vector<String> netmasks = new Vector<String>()
        HashMap<String, Integer> prefix_hash = new HashMap<String, Integer>()
        HashMap<List<Integer>, Integer> octets_hash = new HashMap<List<Integer>, Integer>()
        HashMap<Integer, Long> u32_hash = new HashMap<Integer, Long>()
        new(String netmask0, String netmask8, String netmask16,
            String netmask24, String netmask30) {
            this.netmask0 = netmask0
            this.netmask8 = netmask8
            this.netmask16 = netmask16
            this.netmask24 = netmask24
            this.netmask30 = netmask30
        }
    }

    public def Prefix32Test setup() {
        var p32t = new Prefix32Test(
            "0.0.0.0",
            "255.0.0.0",
            "255.255.0.0",
            "255.255.255.0",
            "255.255.255.252");
        p32t.netmasks.add(p32t.netmask0);
        p32t.netmasks.add(p32t.netmask8);
        p32t.netmasks.add(p32t.netmask16);
        p32t.netmasks.add(p32t.netmask24);
        p32t.netmasks.add(p32t.netmask30);
        p32t.prefix_hash.put("0.0.0.0", 0);
        p32t.prefix_hash.put("255.0.0.0", 8);
        p32t.prefix_hash.put("255.255.0.0", 16);
        p32t.prefix_hash.put("255.255.255.0", 24);
        p32t.prefix_hash.put("255.255.255.252", 30);

        p32t.octets_hash.put(#[0, 0, 0, 0], 0);
        p32t.octets_hash.put(#[255, 0, 0, 0], 8);
        p32t.octets_hash.put(#[255, 255, 0, 0], 16);
        p32t.octets_hash.put(#[255, 255, 255, 0], 24);
        p32t.octets_hash.put(#[255, 255, 255, 252], 30);
        
        p32t.u32_hash.put(0, 0l);
        p32t.u32_hash.put(8, 4278190080l);
        p32t.u32_hash.put(16, 4294901760l);
        p32t.u32_hash.put(24, 4294967040l);
        p32t.u32_hash.put(30, 4294967292l);
        return p32t;
    }

    @Test
    public def test_attributes() {
        for (num : setup().prefix_hash.values()) {
            val prefix = Prefix32.create(num).unwrap();
            assertEquals(num, prefix.num)
        }
    }

    @Test
    public def test_parse_netmask_to_prefix() {
        setup().prefix_hash.forEach[netmask, num |
            val prefix = IPAddress.parse_netmask_to_prefix(netmask).unwrap();
            assertEquals(num, prefix);
        ]
    }
    @Test
    public def test_method_to_ip() {
        setup().prefix_hash.forEach[netmask, num |
            val prefix = Prefix32.create(num).unwrap();
            assertEquals(netmask, prefix.to_ip_str())
        ]
    }
    @Test
    public def test_method_to_s() {
        val prefix = Prefix32.create(8).unwrap();
        assertEquals("8", prefix.to_s())
    }
    @Test
    public def test_method_bits() {
        val prefix = Prefix32.create(16).unwrap();
        assertEquals("11111111111111110000000000000000", prefix.bits())
    }
    @Test
    public def test_method_to_u32() {
        setup().u32_hash.forEach[num,ip32 |
            assertEquals(ip32,
                       Prefix32.create(num).unwrap().netmask().longValue())
        ]
    }
    @Test
    public def test_method_plus() {
        val p1 = Prefix32.create(8).unwrap();
        val p2 = Prefix32.create(10).unwrap();
        assertEquals(18, p1.add_prefix(p2).unwrap().num);
        assertEquals(12, p1.add(4).unwrap().num)
    }
    @Test
    public def test_method_minus() {
        val p1 = Prefix32.create(8).unwrap();
        val p2 = Prefix32.create(24).unwrap();
        assertEquals(16, p1.sub_prefix(p2).unwrap().num);
        assertEquals(16, p2.sub_prefix(p1).unwrap().num);
        assertEquals(20, p2.sub(4).unwrap().num);
    }
    @Test
    public def test_initialize() {
        assertTrue(Prefix32.create(33).isErr());
        assertTrue(Prefix32.create(8).isOk());
    }
    @Test
    public def test_method_octets() {
        setup().octets_hash.forEach[arr, pref |
            val prefix = Prefix32.create(pref).unwrap();
            assertArrayEquals(prefix.ip_bits.parts(prefix.netmask()), arr);
        ]
    }
    @Test
    public def test_method_brackets() {
        setup().octets_hash.forEach[arr, pref| 
            val prefix = Prefix32.create(pref).unwrap();
            for (var index = 0; index < arr.size; index++) {
                val oct = arr.get(index);
                assertEquals(prefix.ip_bits.parts(prefix.netmask()).get(index), oct)
            }
        ]
    }
    @Test
    public def test_method_hostmask() {
        val prefix = Prefix32.create(8).unwrap();
        assertEquals("0.255.255.255",
                   IpV4.from_u32(prefix.host_mask().intValue(), 0).unwrap().to_s());
    }
}
