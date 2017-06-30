using System;
using System.Numerics;
using System.Collections.Generic;

namespace ipaddress
{
  class Prefix32
  {
    public  Result<Prefix> from(Prefix my, int num)  {
      return create(num);
    }
    ///  Gives the prefix in IPv4 dotted decimal format,
    ///  i.e. the canonical netmask we're all used to
    ///
    ///    prefix = IPAddress::prefix::Prefix32.new 24
    ///
    ///    prefix.to_ip
    ///      ///  "255.255.255.0"
    ///
    public static Result<Prefix> create(int num) {
      if (0 <= num && num <= 32)
      {
        var ip_bits = IpBits.V4;
        var bits = ip_bits.bits;
        return Result<Prefix>.Ok(new Prefix(num, ip_bits, Prefix.new_netmask(num, bits),

                                            (p, _num) => create(_num)));
        }
      return Result<Prefix>.Err(string.Format("Prefix must be in range 0..32, got: %d", num));
    }
  }
}