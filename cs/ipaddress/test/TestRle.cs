using System;
using System.Numerics;
using System.Collections.Generic;

namespace ipaddress
{

public class TestRle {
    
    @Test
    public def test_rle() {
        assertArrayEquals(Rle.code(#[]), #[]);
        assertArrayEquals(Rle.code(#[4711]), #[new Rle(
                         4711,
                         0,
                         1,
                         true
                    )]);
        assertArrayEquals(Rle.code(#[4711, 4711]), #[new Rle(
                         4711,
                         0,
                         2,
                         true
                    )]);
        assertArrayEquals(Rle.code(#[4711, 4711, 4811]), #[new Rle(
                         4711,
                         0,
                         2,
                         true
                    ),
                    new Rle(
                         4811,
                         1,
                         1,
                         true
                    )]);
        assertArrayEquals(Rle.code(#[4711, 4711, 4811, 4711, 4711]), #[new Rle(
                         4711,
                         0,
                         2,
                         true
                    ),
                    new Rle(
                         4811,
                         1,
                         1,
                         true
                    ),
                    new Rle(
                         4711,
                         2,
                         2,
                         true
                    )]);
        assertArrayEquals(Rle.code(#[4711, 4711, 4711, 4811, 4711, 4711]), #[new Rle(
                         4711,
                         0,
                         3,
                         true
                    ),
                    new Rle(
                         4811,
                         1,
                         1,
                         true
                    ),
                    new Rle(
                         4711,
                         2,
                         2,
                         false
                    )]
                   );
           assertArrayEquals(Rle.code(#[4711, 4711, 4711, 4811, 4711, 4711, 4911, 4911, 4911]), #[new Rle(
                            4711,
                            0,
                            3,
                            true
                       ),
                       new Rle(
                            4811,
                            1,
                            1,
                            true
                       ),
                       new Rle(
                            4711,
                            2,
                            2,
                            false
                       ),
                       new Rle(
                            4911,
                            3,
                            3,
                            true
                       )]);


       assertArrayEquals(Rle.code(#[0x2001, 0x888, 0, 0x6630, 0, 0, 0, 0]), #[new Rle(
                        0x2001,
                        0,
                        1,
                        true
                   ),
                   new Rle(
                        0x888,
                        1,
                        1,
                        true
                   ),
                   new Rle(
                        0,
                        2,
                        1,
                        false
                   ),
                   new Rle(
                        0x6630,
                        3,
                        1,
                        true
                   ),
                   new Rle(
                        0,
                        4,
                        4,
                        true
                   )
       ]);


   }
}
}
