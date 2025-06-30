import Prefix from "./prefix.js";
import IpBits from "./ip_bits.js";

const Prefix128 = {
  // #[derive(Ord,PartialOrd,Eq,PartialEq,Debug,Copy,Clone)]
  // pub struct Prefix128 {
  // }
  //
  // impl Prefix128 {
  //
  //  Creates a new prefix object for 128 bits IPv6 addresses
  //
  //    prefix = IPAddressPrefix128.new 64
  //      // => 64
  //
  // #[allow(unused_comparisons)]
  create(num: number): Prefix {
    if (num <= 128) {
      // static _FROM: &'static (Fn(&Prefix, usize) -> Result<Prefix, String>) = &from;
      // static _TO_IP_STR: &'static (Fn(&Vec<u16>) -> String) = &Prefix128::to_ip_str;
      const ip_bits = IpBits.v6();
      const bits = ip_bits.bits;
      return new Prefix({
        num,
        ip_bits,
        net_mask: Prefix.new_netmask(num, bits),
        vt_from: Prefix128.from, // vt_to_ip_str: _TO_IP_STR
      });
    }
    return null;
  },

  from(my: Prefix, num: number): Prefix {
    return Prefix128.create(num);
  },
};

export default Prefix128;
