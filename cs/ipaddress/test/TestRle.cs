
using System;
using System.Numerics;
using System.Collections.Generic;
using Xunit;
using ipaddress;

//mespace ipaddress.test
namespace address_test
{


  //[NUnit.Framework.TestFixture]
  public class TestRle
  {
    void Compare(List<Rle> me, List<Rle> my)
    {
      if (me.Count != my.Count)
      {
        Xunit.Assert.Equal(me, my);
      }
      for (var i = 0; i < my.Count; ++i)
      {
        Xunit.Assert.Equal(me[i], my[i]);
      }
    }

    //[NUnit.Framework.Test]
    [Xunit.Fact]
      public void testRle()
      {
        Compare(Rle.code(new List<uint> { }), new List<Rle> { });
        Compare(Rle.code(new List<uint> { 4711 }), new List<Rle> {
            new Rle(
                4711,
                0,
                1,
                true)
            });
        Compare(Rle.code(new List<uint> { 4711, 4711 }), new List<Rle> {new Rle(
              4711,
              0,
              2,
              true
              )});
        Compare(Rle.code(new List<uint> { 4711, 4711, 4811 }), new List<Rle> {new Rle(
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
        Compare(Rle.code(new List<uint> { 4711, 4711, 4811, 4711, 4711 }), new List<Rle> {new Rle(
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
        Compare(Rle.code(new List<uint> { 4711, 4711, 4711, 4811, 4711, 4711 }), new List<Rle> {new Rle(
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
        Compare(Rle.code(new List<uint> { 4711, 4711, 4711, 4811, 4711, 4711, 4911, 4911, 4911 }), new List<Rle> {new Rle(
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


        Compare(Rle.code(new List<uint> { 0x2001, 0x888, 0, 0x6630, 0, 0, 0, 0 }), new List<Rle> {
            new Rle( 0x2001, 0, 1, true ),
            new Rle( 0x888, 1, 1, true ),
            new Rle( 0, 2, 1, false ),
            new Rle( 0x6630, 3, 1, true ),
            new Rle( 0, 4, 4, true )
            });


      }
  }
}
