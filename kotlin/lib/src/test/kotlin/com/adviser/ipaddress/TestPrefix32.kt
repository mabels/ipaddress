package com.adviser.ipaddress.kotlin


import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class Prefix32Test(
        val netmask0: String,
        val netmask8: String,
        val netmask16: String,
        val netmask24: String,
        val netmask30: String) {
    val netmasks = emptyArray<String>()
    val prefix_hash = HashMap<String, Int>()
    val octets_hash = HashMap<IntArray, Int>()
    val u32_hash = HashMap<Int, Long>()
}

class TestPrefix32 {

    public fun setup(): Prefix32Test {
        val p32t = Prefix32Test(
                "0.0.0.0",
                "255.0.0.0",
                "255.255.0.0",
                "255.255.255.0",
                "255.255.255.252")
        p32t.netmasks.plus(p32t.netmask0)
        p32t.netmasks.plus(p32t.netmask8)
        p32t.netmasks.plus(p32t.netmask16)
        p32t.netmasks.plus(p32t.netmask24)
        p32t.netmasks.plus(p32t.netmask30)
        p32t.prefix_hash.put("0.0.0.0", 0)
        p32t.prefix_hash.put("255.0.0.0", 8)
        p32t.prefix_hash.put("255.255.0.0", 16)
        p32t.prefix_hash.put("255.255.255.0", 24)
        p32t.prefix_hash.put("255.255.255.252", 30)

        p32t.octets_hash.put(intArrayOf(0, 0, 0, 0), 0)
        p32t.octets_hash.put(intArrayOf(255, 0, 0, 0), 8)
        p32t.octets_hash.put(intArrayOf(255, 255, 0, 0), 16)
        p32t.octets_hash.put(intArrayOf(255, 255, 255, 0), 24)
        p32t.octets_hash.put(intArrayOf(255, 255, 255, 252), 30)

        p32t.u32_hash.put(0, 0L)
        p32t.u32_hash.put(8, 4278190080L)
        p32t.u32_hash.put(16, 4294901760L)
        p32t.u32_hash.put(24, 4294967040L)
        p32t.u32_hash.put(30, 4294967292L)
        return p32t
    }

    @Test
    public fun test_attributes() {
        for (num in setup().prefix_hash.values) {
            val prefix = Prefix32.create(num).unwrap()
            assertEquals(num, prefix.num)
        }
    }

    @Test
    public fun test_parse_netmask_to_prefix() {
        setup().prefix_hash.forEach { netmask, num ->
            val prefix = IPAddress.parse_netmask_to_prefix(netmask).unwrap()
            assertEquals(num, prefix)
        }
    }

    @Test
    public fun test_method_to_ip() {
        setup().prefix_hash.forEach { netmask, num ->
            val prefix = Prefix32.create(num).unwrap()
            assertEquals(netmask, prefix.to_ip_str())
        }
    }

    @Test
    public fun test_method_to_s() {
        val prefix = Prefix32.create(8).unwrap()
        assertEquals("8", prefix.to_s())
    }

    @Test
    public fun test_method_bits() {
        val prefix = Prefix32.create(16).unwrap()
        assertEquals("11111111111111110000000000000000", prefix.bits())
    }

    @Test
    public fun test_method_to_u32() {
        setup().u32_hash.forEach { num, ip32 ->
            assertEquals(ip32, Prefix32.create(num).unwrap().netmask().toLong())
        }
    }

    @Test
    public fun test_method_plus() {
        val p1 = Prefix32.create(8).unwrap()
        val p2 = Prefix32.create(10).unwrap()
        assertEquals(18, p1.add_prefix(p2).unwrap().num)
        assertEquals(12, p1.add(4).unwrap().num)
    }

    @Test
    public fun test_method_minus() {
        val p1 = Prefix32.create(8).unwrap()
        val p2 = Prefix32.create(24).unwrap()
        assertEquals(16, p1.sub_prefix(p2).unwrap().num)
        assertEquals(16, p2.sub_prefix(p1).unwrap().num)
        assertEquals(20, p2.sub(4).unwrap().num)
    }

    @Test
    public fun test_initialize() {
        assertTrue(Prefix32.create(33).isErr())
        assertTrue(Prefix32.create(8).isOk())
    }

    @Test
    public fun test_method_octets() {
        setup().octets_hash.forEach { arr, pref ->
            val prefix = Prefix32.create(pref).unwrap()
            assertArrayEquals(prefix.ip_bits.parts(prefix.netmask()), arr)
        }
    }

    @Test
    public fun test_method_brackets() {
        setup().octets_hash.forEach { arr, pref ->
            val prefix = Prefix32.create(pref).unwrap()
            for (index in 0 until arr.size) {
                val oct = arr.get(index)
                assertEquals(prefix.ip_bits.parts(prefix.netmask()).get(index), oct)
            }
        }
    }

    @Test
    public fun test_method_hostmask() {
        val prefix = Prefix32.create(8).unwrap()
        assertEquals("0.255.255.255",
                IpV4.from_u32(prefix.host_mask().toLong(), 0).unwrap().to_s())
    }
}
