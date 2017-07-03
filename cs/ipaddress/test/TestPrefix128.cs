using System;
using System.Numerics;
using System.Collections.Generic;
using System.Text;
using Xunit;
using ipaddress;

//namespace ipaddress
namespace address_test
{

  class Prefix128Test
  {
    public Dictionary<uint, BigInteger> u128_hash = new Dictionary<uint, BigInteger>();
  }


  public  class TestPrefix128 {


    Prefix128Test setup() {
      var p128t = new Prefix128Test();
      p128t.u128_hash.Add(32, BigInteger.Parse("340282366841710300949110269838224261120"));
      p128t.u128_hash.Add(64, BigInteger.Parse("340282366920938463444927863358058659840"));
      p128t.u128_hash.Add(96, BigInteger.Parse("340282366920938463463374607427473244160"));
      p128t.u128_hash.Add(126, BigInteger.Parse("340282366920938463463374607431768211452"));
      return p128t;
    }

    [Fact]
      void test_initialize() {
        Assert.True(Prefix128.create(129).isErr());
        Assert.True(Prefix128.create(64).isOk());
      }

    [Fact]
      void test_method_bits() {
        var prefix = Prefix128.create(64).unwrap();
        var str = new StringBuilder();
        for (var i = 0; i < 64; i++) {
          str.Append("1");
        }
        for (var i = 0; i < 64; i++) {
          str.Append("0");
        }
        Assert.Equal(str.ToString(), prefix.bits());
      }
    [Fact]
      void test_method_to_u32() {
        foreach (var kp in setup().u128_hash)
        {
          var num = kp.Key;
          var u128 = kp.Value;
          Assert.Equal(u128, Prefix128.create(num).unwrap().netmask());
        }

      }
  }
}
