
using System;
using System.Numerics;
using System.Collections.Generic;
using NUnit.Framework;

namespace ipaddress.test
{

  [TestFixture]
  class TestRle
  {

    [Test]
    void test_rle()
    {
      Assert.AreEqual(Rle.code(new List<int> { }), new List<Rle> { });
      Assert.AreEqual(Rle.code(new List<int> { 4711 }), new List<Rle> {
        new Rle(
                         4711,
                         0,
                         1,
          true)
      });
      Assert.AreEqual(Rle.code(new List<int> { 4711, 4711 }), new List<Rle> {new Rle(
                         4711,
                         0,
                         2,
                         true
                    )});
      Assert.AreEqual(Rle.code(new List<int> { 4711, 4711, 4811 }), new List<Rle> {new Rle(
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
                    )});
      Assert.AreEqual(Rle.code(new List<int> { 4711, 4711, 4811, 4711, 4711 }), new List<Rle> {new Rle(
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
                    )});
      Assert.AreEqual(Rle.code(new List<int> { 4711, 4711, 4711, 4811, 4711, 4711 }), new List<Rle> {new Rle(
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
                    )}
             );
      Assert.AreEqual(Rle.code(new List<int> { 4711, 4711, 4711, 4811, 4711, 4711, 4911, 4911, 4911 }), new List<Rle> {new Rle(
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
                       )});


      Assert.AreEqual(Rle.code(new List<int> { 0x2001, 0x888, 0, 0x6630, 0, 0, 0, 0 }), new List<Rle> {
            new Rle( 0x2001, 0, 1, true ),
                   new Rle( 0x888, 1, 1, true ),
                   new Rle( 0, 2, 1, false ),
                   new Rle( 0x6630, 3, 1, true ),
                   new Rle( 0, 4, 4, true )
       });


    }
  }
}
