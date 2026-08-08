import 'package:result_monad/result_monad.dart';

import 'IpBits.dart';
import 'Prefix.dart';

class Prefix128 {
  ///
  ///  Creates a prefix object for 128 bits IPv6 addresses
  ///
  ///    prefix = IPAddressPrefix128.64
  ///      ///  64
  ///
  static Result<Prefix, String> create(int num) {
    if (num <= 128) {
      //static _FROM: &'static (Fn(&Prefix, usize) -> Result<Prefix, String>) = &from;
      //static _TO_IP_STR: &'static (Fn(&Vec<u16>) -> String) = &Prefix128::to_ip_str;
      final ip_bits = IpBits.V6;
      final bits = ip_bits.bits;
      return Result.ok(Prefix(num, ip_bits, Prefix.new_netmask(num, bits),
          (p, _num) => create(_num)));
    }
    return Result.error("Prefix must be in range 0..128, got: ${num}");
  }

  Result<Prefix, String> from(int num) {
    return create(num);
  }
}
