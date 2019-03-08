import "package:test/test.dart";

import '../Rle.dart';

rleArrayExpect(List<Rle> a, List<Rle> b) {
  expect(a.length, b.length);
  for (var i = 0; i < a.length; ++i) {
    expect(true, a[i].eq(b[i]));
  }
}

void main() {    
  test("test_rle()", () {
        rleArrayExpect(Rle.code([]), []);
        rleArrayExpect(Rle.code([4711]), [Rle(
                         4711,
                         0,
                         1,
                         true
                    )]);
        rleArrayExpect(Rle.code([4711, 4711]), [Rle(
                         4711,
                         0,
                         2,
                         true
                    )]);
        rleArrayExpect(Rle.code([4711, 4711, 4811]), [Rle(
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
                    )]);
        rleArrayExpect(Rle.code([4711, 4711, 4811, 4711, 4711]), [Rle(
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
                    )]);
        rleArrayExpect(Rle.code([4711, 4711, 4711, 4811, 4711, 4711]), [Rle(
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
                    )]
                   );
           rleArrayExpect(Rle.code([4711, 4711, 4711, 4811, 4711, 4711, 4911, 4911, 4911]), [Rle(
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
                       )]);


       rleArrayExpect(Rle.code([0x2001, 0x888, 0, 0x6630, 0, 0, 0, 0]), [Rle(
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
       ]);


   });
}
