import Prefix from "./prefix.js";
import IpBits from "./ip_bits.js";

const Prefix32 = {
  from(my: Prefix, num: number): Prefix {
    return Prefix32.create(num);
  },

  create(num: number): Prefix {
    if (num >= 0 && num <= 32) {
      // static _FROM: &'static (Fn(&::prefix::Prefix, usize) -> Result<::prefix::Prefix, String>) =
      // &from;
      // static _TO_IP_STR: &'static (Fn(&Vec<u16>) -> String) = &to_ip_str;
      const ip_bits = IpBits.v4();
      const bits = ip_bits.bits;
      return new Prefix({
        num,
        ip_bits,
        net_mask: Prefix.new_netmask(num, bits),
        vt_from: Prefix32.from,
        // vt_to_ip_str: _TO_IP_STR,
      });
    }
    return null;
  },
};

export default Prefix32;
