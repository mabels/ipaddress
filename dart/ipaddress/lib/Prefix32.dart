import 'package:result_monad/result_monad.dart';

import 'IpBits.dart';
import 'Prefix.dart';

class Prefix32 {
  Result<Prefix, String> from(Prefix my, int num) {
    return create(num);
  }

  ///  Gives the prefix in IPv4 dotted decimal format,
  ///  i.e. the canonical netmask we're all used to
  ///
  ///    prefix = IPAddress::prefix::Prefix32.24
  ///
  ///    prefix.to_ip
  ///      ///  "255.255.255.0"
  ///
  static Result<Prefix, String> create(int num) {
    if (0 <= num && num <= 32) {
      final ip_bits = IpBits.V4;
      final bits = ip_bits.bits;
      return Result.ok(Prefix(num, ip_bits, Prefix.new_netmask(num, bits),
          (p, _num) => create(_num)));
    }
    return Result.error("Prefix must be in range 0..32, got: ${num}");
  }
}
