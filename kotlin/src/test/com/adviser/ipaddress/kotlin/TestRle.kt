package com.adviser.ipaddress.kotlin

import org.junit.Test


class TestRle {

    @Test
    fun test_rle() {
        assertArrayEquals(Rle.code(intArrayOf()), emptyList<Rle>())
        assertArrayEquals(Rle.code(intArrayOf(4711)), listOf(Rle(
                4711,
                0,
                1,
                true
        )))
        assertArrayEquals(Rle.code(intArrayOf(4711, 4711)), listOf(Rle(
                4711,
                0,
                2,
                true
        )))
        assertArrayEquals(Rle.code(intArrayOf(4711, 4711, 4811)), listOf(Rle(
                4711,
                0,
                2,
                true
        ),
                Rle(
                        4811,
                        1,
                        1,
                        true
                )))
        assertArrayEquals(Rle.code(intArrayOf(4711, 4711, 4811, 4711, 4711)), listOf(Rle(
                4711,
                0,
                2,
                true
        ),
                Rle(
                        4811,
                        1,
                        1,
                        true
                ),
                Rle(
                        4711,
                        2,
                        2,
                        true
                )))
        assertArrayEquals(Rle.code(intArrayOf(4711, 4711, 4711, 4811, 4711, 4711)), listOf(Rle(
                4711,
                0,
                3,
                true
        ),
                Rle(
                        4811,
                        1,
                        1,
                        true
                ),
                Rle(
                        4711,
                        2,
                        2,
                        false
                ))
        )
        assertArrayEquals(Rle.code(intArrayOf(4711, 4711, 4711, 4811, 4711, 4711, 4911, 4911, 4911)), listOf(Rle(
                4711,
                0,
                3,
                true
        ),
                Rle(
                        4811,
                        1,
                        1,
                        true
                ),
                Rle(
                        4711,
                        2,
                        2,
                        false
                ),
                Rle(
                        4911,
                        3,
                        3,
                        true
                )))


        assertArrayEquals(Rle.code(intArrayOf(0x2001, 0x888, 0, 0x6630, 0, 0, 0, 0)), listOf(Rle(
                0x2001,
                0,
                1,
                true
        ),
                Rle(
                        0x888,
                        1,
                        1,
                        true
                ),
                Rle(
                        0,
                        2,
                        1,
                        false
                ),
                Rle(
                        0x6630,
                        3,
                        1,
                        true
                ),
                Rle(
                        0,
                        4,
                        4,
                        true
                )
        ))


    }
}
