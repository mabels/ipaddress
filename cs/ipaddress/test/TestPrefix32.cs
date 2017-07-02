using System;
using System.Numerics;
using System.Collections.Generic;
using NUnit.Framework;

namespace ipaddress
{

  class Prefix32Test
  {
    public String netmask0;
    public     String netmask8;
    public     String netmask16;
    public     String netmask24;
    public     String netmask30;
    public List<String> netmasks = new List<String>();
    public Dictionary<String, int> prefix_hash = new Dictionary<String, int>();
    public Dictionary<List<UInt32>, int> octets_hash = new Dictionary<List<UInt32>, int>();
    public     Dictionary<int, UInt32> u32_hash = new Dictionary<int, UInt32>();
    public Prefix32Test(String netmask0, String netmask8, String netmask16,
            String netmask24, String netmask30) {
      this.netmask0 = netmask0;
            this.netmask8 = netmask8;
            this.netmask16 = netmask16;
            this.netmask24 = netmask24;
            this.netmask30 = netmask30;
        }
  }


  class TestPrefix32 {


    Prefix32Test setup() {
        var p32t = new Prefix32Test(
            "0.0.0.0",
            "255.0.0.0",
            "255.255.0.0",
            "255.255.255.0",
            "255.255.255.252");
        p32t.netmasks.Add(p32t.netmask0);
        p32t.netmasks.Add(p32t.netmask8);
        p32t.netmasks.Add(p32t.netmask16);
        p32t.netmasks.Add(p32t.netmask24);
        p32t.netmasks.Add(p32t.netmask30);
        p32t.prefix_hash.Add("0.0.0.0", 0);
        p32t.prefix_hash.Add("255.0.0.0", 8);
        p32t.prefix_hash.Add("255.255.0.0", 16);
        p32t.prefix_hash.Add("255.255.255.0", 24);
        p32t.prefix_hash.Add("255.255.255.252", 30);

      p32t.octets_hash.Add(new List<UInt32>{ 0, 0, 0, 0}, 0);
      p32t.octets_hash.Add(new List<UInt32> { 255, 0, 0, 0 }, 8);
        p32t.octets_hash.Add(new List<UInt32> { 255, 255, 0, 0}, 16);
        p32t.octets_hash.Add(new List<UInt32> { 255, 255, 255, 0}, 24);
        p32t.octets_hash.Add(new List<UInt32> { 255, 255, 255, 252}, 30);
        
        p32t.u32_hash.Add(0, 0);
        p32t.u32_hash.Add(8, 4278190080);
        p32t.u32_hash.Add(16, 4294901760);
        p32t.u32_hash.Add(24, 4294967040);
        p32t.u32_hash.Add(30, 4294967292);
        return p32t;
    }

    [Test]
    void test_attributes() {
      foreach (var num in setup().prefix_hash.Values) {
            var prefix = Prefix32.create(num).unwrap();
        Assert.AreEqual(num, prefix.num);
        }
    }

    [Test]
    void test_parse_netmask_to_prefix() {
      foreach (var kp in setup().prefix_hash)
      {
        var netmask = kp.Key;
        var num = kp.Value;
        var prefix = IPAddress.parse_netmask_to_prefix(netmask).unwrap();
        Assert.AreEqual(num, prefix);
      }
    }
    [Test]
    void test_method_to_ip()
    {
      foreach (var kp in setup().prefix_hash)
      {
        var netmask = kp.Key;
        var num = kp.Value;
        var prefix = Prefix32.create(num).unwrap();
        Assert.AreEqual(netmask, prefix.to_ip_str());
      }
    }
    [Test]
    void test_method_to_s() {
        var prefix = Prefix32.create(8).unwrap();
      Assert.AreEqual("8", prefix.to_s());
    }
    [Test]
    void test_method_bits() {
        var prefix = Prefix32.create(16).unwrap();
      Assert.AreEqual("11111111111111110000000000000000", prefix.bits());
    }
    [Test]
    void test_method_to_u32() {
      foreach (var kp in setup().u32_hash)
      {
        var num = kp.Key;
        var ip32 = kp.Value;
        Assert.AreEqual(ip32, Prefix32.create(num).unwrap().netmask());
      } 
    }
    [Test]
    void test_method_plus() {
        var p1 = Prefix32.create(8).unwrap();
        var p2 = Prefix32.create(10).unwrap();
        Assert.AreEqual(18, p1.add_prefix(p2).unwrap().num);
      Assert.AreEqual(12, p1.add(4).unwrap().num);
    }
    [Test]
    void test_method_minus() {
        var p1 = Prefix32.create(8).unwrap();
        var p2 = Prefix32.create(24).unwrap();
        Assert.AreEqual(16, p1.sub_prefix(p2).unwrap().num);
        Assert.AreEqual(16, p2.sub_prefix(p1).unwrap().num);
        Assert.AreEqual(20, p2.sub(4).unwrap().num);
    }
    [Test]
    void test_initialize() {
      Assert.IsTrue(Prefix32.create(33).isErr());
        Assert.IsTrue(Prefix32.create(8).isOk());
    }
    [Test]
    void test_method_octets()
    {
      foreach (var kp in setup().octets_hash) {
        var arr = kp.Key;
      var pref = kp.Value;
      var prefix = Prefix32.create(pref).unwrap();
        Assert.AreEqual(prefix.ip_bits.parts(prefix.netmask()), arr);
    } 
    }
    [Test]
    void test_method_brackets() {
      foreach (var kp in setup().octets_hash)
      {
        var arr = kp.Key;
        var pref = kp.Value;
        var prefix = Prefix32.create(pref).unwrap();
        for (var index = 0; index < arr.Count; index++)
        {
          var oct = arr[index];
          Assert.AreEqual(prefix.ip_bits.parts(prefix.netmask())[index], oct);
        }
      }
    }
    [Test]
    void test_method_hostmask() {
        var prefix = Prefix32.create(8).unwrap();
        Assert.AreEqual("0.255.255.255",
                     IpV4.from_u32((UInt32)prefix.host_mask(), 0).unwrap().to_s());
    }
}
}
