package com.adviser.ipaddress

import java.math.BigInteger
import kotlin.test.assertEquals

class Prefix128Test {
    public HashMap<Integer, BigInteger> u128_hash = HashMap<Integer, BigInteger>()
}

class TestPrefix128 {

    public fun Prefix128Test setup() {
        val p128t = Prefix128Test()
        p128t.u128_hash.put(32, BigInteger("340282366841710300949110269838224261120", 10))
        p128t.u128_hash.put(64, BigInteger("340282366920938463444927863358058659840", 10))
        p128t.u128_hash.put(96, BigInteger("340282366920938463463374607427473244160", 10))
        p128t.u128_hash.put(126, BigInteger("340282366920938463463374607431768211452", 10))
        return p128t;
    }

    @Test
    public fun test_initialize() {
        assertTrue(Prefix128.create(129).isErr());
        assertTrue(Prefix128.create(64).isOk());
    }

    @Test
    public fun test_method_bits() {
        val prefix = Prefix128.create(64).unwrap();
        var str = StringBuilder();
        for (var i = 0; i < 64; i++) {
            str.append("1");
        }
        for (var i = 0; i < 64; i++) {
            str.append("0");
        }
        assertEquals(str.toString(), prefix.bits())
    }
    @Test
    public fun test_method_to_u32() {
        setup().u128_hash.forEach[num, u128|
            assertEquals(u128, Prefix128.create(num).unwrap().netmask())
        ]
    }
}
