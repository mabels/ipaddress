package com.adviser.ipaddress.kotlin

import org.junit.Test
import java.math.BigInteger
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class Prefix128Test {
    public val u128_hash = HashMap<Int, BigInteger>()
}

class TestPrefix128 {

    public fun setup(): Prefix128Test {
        val p128t = Prefix128Test()
        p128t.u128_hash.put(32, BigInteger("340282366841710300949110269838224261120", 10))
        p128t.u128_hash.put(64, BigInteger("340282366920938463444927863358058659840", 10))
        p128t.u128_hash.put(96, BigInteger("340282366920938463463374607427473244160", 10))
        p128t.u128_hash.put(126, BigInteger("340282366920938463463374607431768211452", 10))
        return p128t
    }

    @Test
    public fun test_initialize() {
        assertTrue(Prefix128.create(129).isErr())
        assertTrue(Prefix128.create(64).isOk())
    }

    @Test
    public fun test_method_bits() {
        val prefix = Prefix128.create(64).unwrap()
        val str = StringBuilder()
        for (i in 0 until 64) {
            str.append("1")
        }
        for (i in 0 until 64) {
            str.append("0")
        }
        assertEquals(str.toString(), prefix.bits())
    }

    @Test
    public fun test_method_to_u32() {
        setup().u128_hash.forEach { num, u128 ->
            assertEquals(u128, Prefix128.create(num).unwrap().netmask())
        }
    }
}
