using System;
using System.Numerics;
using System.Collections.Generic;
using System.Text;

namespace ipaddress
{

  class IpBits
  {
    public IpVersion version;
    public uint bits;
    public uint part_bits;
    public uint dns_bits;
    public String rev_domain;
    public BigInteger part_mod;
    public BigInteger host_ofs;

    public Vt_to_string vt_as_compressed_string;
    public Vt_to_string vt_as_uncompressed_string;

    public IpBits(IpVersion ver, Vt_to_string cp, Vt_to_string ucp,
      uint bits, uint part_bits, uint dns_bits, String rev_domain,
      BigInteger part_mod, BigInteger host_ofs)
    {
      this.version = ver;
      this.vt_as_compressed_string = cp;
      this.vt_as_uncompressed_string = ucp;
      this.bits = bits;
      this.part_bits = part_bits;
      this.dns_bits = dns_bits;
      this.rev_domain = rev_domain;
      this.part_mod = part_mod;
      this.host_ofs = host_ofs;
    }

    public delegate string Vt_to_string(IpBits ip_bits, BigInteger host_address);

    static string ipv4_as_compressed(IpBits ip_bits, BigInteger host_address)
    {
      var ret = new StringBuilder();
      var sep = "";
      foreach (var part in ip_bits.parts(host_address))
      {
        ret.Append(sep);
        ret.Append(part);
        sep = ".";
      }
      return ret.ToString();
    }

    public static IpBits v4()
    {

      return new IpBits(IpVersion.V4,
      ipv4_as_compressed,
      ipv4_as_compressed,
      32,
      8,
      8,
      "in-addr.arpa",
                        new BigInteger(1) << 8,
                        new BigInteger(1));
    }
    public static IpBits V4 = v4();

    static string ipv6_as_compressed(IpBits ip_bits, BigInteger host_address)
    {
      //println!("ipv6_as_compressed:{}", host_address);
      var ret = new StringBuilder();
      var the_colon = ":";
      var the_empty = "";
      var colon = the_empty;
      var done = false;
      foreach (var rle in Rle.code(ip_bits.parts(host_address)))
      {
        var abort = false;
        for (var i = 0; !abort && i < rle.cnt; i++)
        {
          if (done || !(rle.part == 0 && rle.max))
          {
            ret.Append(colon);
            ret.Append(rle.part.ToString("x"));
            colon = the_colon;
          }
          else if (rle.part == 0 && rle.max)
          {
            ret.Append("::");
            colon = the_empty;
            done = true;
            abort = true;
          }
        }
      }

      return ret.ToString();
    }

    static string ipv6_as_uncompressed(IpBits ip_bits, BigInteger host_address)
    {
      var ret = new StringBuilder();
      var sep = "";
      foreach (var part in ip_bits.parts(host_address))
      {
        ret.Append(sep);
        ret.Append(part.ToString("x4"));
        sep = ":";
      }
      return ret.ToString();
    }

    public static IpBits v6()
    {
      return new IpBits(IpVersion.V6,
      ipv6_as_compressed,
      ipv6_as_uncompressed,
      128,
      16,
      4,
      "ip6.arpa",
      new BigInteger(1) << 16,
                        new BigInteger(0));
    }

    public static IpBits V6 = v6();

    public string Inspect()
    {
      return "IpBits: «this.version»";
    }

    public static List<uint> reverse(List<uint> data)
    {
      var right = data.Count - 1;
      for (var left = 0; left < right; left++, right--)
      {
        // swap the values at the left and right indices
        var temp = data[left];
        data[left] = data[right];
        data[right] = temp;
      }
      return data;
    }

    public List<uint> parts(BigInteger bu)
    {
      var len = (this.bits / this.part_bits);
      var vec = new List<uint>();
      var my = bu;
      var part_mod = (new BigInteger(1)) << (int)this.part_bits;// - BigUint::one();
      for (var i = 0; i < len; i++)
      {
        var v = (uint)(my % part_mod);
        vec.Add(v);
        my = my >> (int)this.part_bits;
      }
      return IpBits.reverse(vec);
    }

    public String as_compressed_string(BigInteger bu)
    {
      return this.vt_as_compressed_string(this, bu);
    }
    public String as_uncompressed_string(BigInteger bu)
    {
      return this.vt_as_uncompressed_string(this, bu);
    }

    //  Returns the IP address in in-addr.arpa format
    //  for DNS lookups
    //
    //    ip = IPAddress("172.16.100.50/24")
    //
    //    ip.reverse
    //      // => "50.100.16.172.in-addr.arpa"
    //
    // #[allow(dead_code)]
    // pub fn dns_reverse(&self, bu: &BigUint) -> String {
    //     let mut ret = String::new();
    //     let part_mod = BigUint::one() << 4;
    //     let the_dot = String::from(".");
    //     let mut dot = &String::from("");
    //     let mut addr = bu.clone();
    //     for _ in 0..(self.bits / self.dns_bits) {
    //         ret.push_str(dot);
    //         let lower = addr.mod_floor(&part_mod).to_usize().unwrap();
    //         ret.push_str(self.dns_part_format(lower).as_str());
    //         addr = addr >> self.dns_bits;
    //         dot = &the_dot;
    //     }
    //     ret.push_str(self.rev_domain);
    //     return ret;
    // }

    public String dns_part_format(int i)
    {
      switch (this.version)
      {
        case IpVersion.V4: return i.ToString();
        case IpVersion.V6: return i.ToString("x");
        default: throw new Exception("Unknown DNS Format");
      }

    }

  }
}


