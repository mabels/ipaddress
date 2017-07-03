using System;
using System.Numerics;
using System.Collections.Generic;
using Xunit;
using ipaddress;

//ipaddress
namespace address_test
{

  class Prefix32Test
  {
    public String netmask0;
    public     String netmask8;
    public     String netmask16;
    public     String netmask24;
    public     String netmask30;
    public List<String> netmasks = new List<String>();
    public Dictionary<String, uint> prefix_hash = new Dictionary<String, uint>();
    public Dictionary<List<uint>, uint> octets_hash = new Dictionary<List<uint>, uint>();
    public     Dictionary<uint, UInt32> u32_hash = new Dictionary<uint, UInt32>();
    public Prefix32Test(String netmask0, String netmask8, String netmask16,
        String netmask24, String netmask30) {
      this.netmask0 = netmask0;
      this.netmask8 = netmask8;
      this.netmask16 = netmask16;
      this.netmask24 = netmask24;
      this.netmask30 = netmask30;
    }
  }


  public class TestPrefix32 {


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

    
      [Xunit.Fact]
        public void test_attributes() {
          foreach (var num in setup().prefix_hash.Values) {
            var prefix = Prefix32.create(num).unwrap();
            Xunit.Assert.Equal(num, prefix.num);
          }
        }

    
      [Xunit.Fact]
        void test_parse_netmask_to_prefix() {
          foreach (var kp in setup().prefix_hash)
          {
            var netmask = kp.Key;
            var num = kp.Value;
            var prefix = IPAddress.parse_netmask_to_prefix(netmask).unwrap();
            Xunit.Assert.Equal(num, prefix);
          }
        }
    
      [Xunit.Fact]
        void test_method_to_ip()
        {
          foreach (var kp in setup().prefix_hash)
          {
            var netmask = kp.Key;
            var num = kp.Value;
            var prefix = Prefix32.create(num).unwrap();
            Xunit.Assert.Equal(netmask, prefix.to_ip_str());
          }
        }
    
      [Xunit.Fact]
        void test_method_to_s() {
          var prefix = Prefix32.create(8).unwrap();
          Xunit.Assert.Equal("8", prefix.to_s());
        }
    
      [Xunit.Fact]
        void test_method_bits() {
          var prefix = Prefix32.create(16).unwrap();
          Xunit.Assert.Equal("11111111111111110000000000000000", prefix.bits());
        }
    
      [Xunit.Fact]
        void test_method_to_u32() {
          foreach (var kp in setup().u32_hash)
          {
            var num = kp.Key;
            var ip32 = kp.Value;
            Xunit.Assert.Equal(ip32, Prefix32.create(num).unwrap().netmask());
          }
        }
    
      [Xunit.Fact]
        void test_method_plus() {
          var p1 = Prefix32.create(8).unwrap();
          var p2 = Prefix32.create(10).unwrap();
          Xunit.Assert.Equal(18u, p1.add_prefix(p2).unwrap().num);
          Xunit.Assert.Equal(12u, p1.add(4).unwrap().num);
        }
    
      [Xunit.Fact]
        void test_method_minus() {
          var p1 = Prefix32.create(8).unwrap();
          var p2 = Prefix32.create(24).unwrap();
          Xunit.Assert.Equal(16u, p1.sub_prefix(p2).unwrap().num);
          Xunit.Assert.Equal(16u, p2.sub_prefix(p1).unwrap().num);
          Xunit.Assert.Equal(20u, p2.sub(4).unwrap().num);
        }
    
      [Xunit.Fact]
        void test_initialize() {
          Xunit.Assert.True(Prefix32.create(33).isErr());
          Xunit.Assert.True(Prefix32.create(8).isOk());
        }
    
      [Xunit.Fact]
        void test_method_octets()
        {
          foreach (var kp in setup().octets_hash) {
            var arr = kp.Key;
            var pref = kp.Value;
            var prefix = Prefix32.create(pref).unwrap();
            Xunit.Assert.Equal(prefix.ip_bits.parts(prefix.netmask()), arr);
          }
        }
    
      [Xunit.Fact]
        void test_method_brackets() {
          foreach (var kp in setup().octets_hash)
          {
            var arr = kp.Key;
            var pref = kp.Value;
            var prefix = Prefix32.create(pref).unwrap();
            for (var index = 0; index < arr.Count; index++)
            {
              var oct = arr[index];
              Xunit.Assert.Equal(prefix.ip_bits.parts(prefix.netmask())[index], oct);
            }
          }
        }
    
      [Xunit.Fact]
        void test_method_hostmask() {
          var prefix = Prefix32.create(8).unwrap();
          Xunit.Assert.Equal("0.255.255.255",
              IpV4.from_u32((UInt32)prefix.host_mask(), 0).unwrap().to_s());
        }
  }
}
