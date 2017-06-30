using System;
using System.Numerics;
using System.Collections.Generic;

namespace ipaddress
{
  class Prefix128
  {
    ///
    ///  Creates a new prefix object for 128 bits IPv6 addresses
    ///
    ///    prefix = IPAddressPrefix128.new 64
    ///      ///  64
    ///
    public static Result<Prefix> create(int num)
    {
      if (num <= 128)
      {
        //static _FROM: &'static (Fn(&Prefix, usize) -> Result<Prefix, String>) = &from;
        //static _TO_IP_STR: &'static (Fn(&Vec<u16>) -> String) = &Prefix128::to_ip_str;
        var ip_bits = IpBits.V6;
        var bits = ip_bits.bits;
        return Result<Prefix>.Ok(new Prefix(
                num,
                ip_bits,
                Prefix.new_netmask(num, bits),
                (p, _num) => { return create(_num); }
        ));
      }
      return Result<Prefix>.Err(string.Format("Prefix must be in range 0..128, got: «%d»", num));
    }

    public Result<Prefix> from(int num)
    {
      return create(num);
    }
  }
}