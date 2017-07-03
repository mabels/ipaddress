using System;
using System.Collections.Generic;
using System.Numerics;
using System.Text;

namespace ipaddress
{

  class Prefix
  {
    public uint num;
    public IpBits ip_bits;
    public BigInteger net_mask;

    public delegate Result<Prefix> VtFrom(Prefix p, uint n);

    VtFrom vt_from;

    public Prefix(uint num, IpBits ip_bits, BigInteger netmask, VtFrom vtfrom)
    {
      this.num = num;
      this.ip_bits = ip_bits;
      this.net_mask = netmask;
      this.vt_from = vtfrom;
    }

    public Prefix clone()
    {
      return new Prefix(num, ip_bits, net_mask, vt_from);
    }

    public bool equal(Prefix other)
    {
      return this.ip_bits.version == other.ip_bits.version &&
        this.num == other.num;
    }

    public String inspect()
    {
      return "Prefix: «num»";
    }

    public int compare(Prefix oth)
    {
      if (this.ip_bits.version < oth.ip_bits.version)
      {
        return -1;
      }
      else if (this.ip_bits.version > oth.ip_bits.version)
      {
        return 1;
      }
      else
      {
        if (this.num < oth.num)
        {
          return -1;
        }
        else if (this.num > oth.num)
        {
          return 1;
        }
        else
        {
          return 0;
        }
      }
    }

    public Result<Prefix> from(uint num)
    {
      return this.vt_from(this, num);
    }

    public string to_ip_str()
    {
      return this.ip_bits.vt_as_compressed_string(this.ip_bits, this.netmask());
    }

    public BigInteger size()
    {
      return (new BigInteger(1)) << (int)(this.ip_bits.bits - this.num);
    }

    public static BigInteger new_netmask(uint prefix, uint bits)
    {
      var mask = new BigInteger(0);
      var host_prefix = bits - prefix;
      for (var i = 0; i < prefix; i++)
      {
        mask = mask + ((new BigInteger(1)) << (int)(host_prefix + i));
      }
      return mask;
    }

    public BigInteger netmask()
    {
      return this.net_mask;
    }

    public uint get_prefix()
    {
      return this.num;
    }

    ///  The hostmask is the contrary of the subnet mask,
    ///  as it shows the bits that can change within the
    ///  hosts
    ///
    ///    prefix = IPAddress::Prefix32.new 24
    ///
    ///    prefix.hostmask
    ///      ///  "0.0.0.255"
    ///
    public BigInteger host_mask()
    {
      var ret = new BigInteger(0);
      for (var i = 0; i < this.ip_bits.bits - this.num; i++)
      {
        ret = (ret << 1) + 1;
      }
      return ret;
    }

    ///
    ///  Returns the length of the host portion
    ///  of a netmask.
    ///
    ///    prefix = Prefix128.new 96
    ///
    ///    prefix.host_prefix
    ///      ///  128
    ///
    public uint host_prefix()
    {
      return (this.ip_bits.bits) - this.num;
    }

    ///
    ///  Transforms the prefix into a string of bits
    ///  representing the netmask
    ///
    ///    prefix = IPAddress::Prefix128.new 64
    ///
    ///    prefix.bits
    ///      ///  "1111111111111111111111111111111111111111111111111111111111111111"
    ///          "0000000000000000000000000000000000000000000000000000000000000000"
    ///
    public String bits()
    {
      var r = new StringBuilder();
      for (var i = 0; i < this.host_prefix(); ++i) {
        r.Append("1");
      }
      for (var i = 0; i < this.num; ++i)
      {
        r.Append("0");
      }
      return r.ToString();
    }
    public String to_s()
    {
      return string.Format("{0}", this.get_prefix());
    }

    public uint to_i()
    {
      return this.get_prefix();
    }

    public Result<Prefix> add_prefix(Prefix other)
    {
      return this.from(this.get_prefix() + other.get_prefix());
    }
    public Result<Prefix> add(uint other)
    {
      return this.from(this.get_prefix() + other);
    }
    public Result<Prefix> sub_prefix(Prefix other)
    {
      return this.sub(other.get_prefix());
    }
    public Result<Prefix> sub(uint other)
    {
      if (other > this.get_prefix())
      {
        return this.from(other - this.get_prefix());
      }
      return this.from(this.get_prefix() - other);
    }
  }
}
