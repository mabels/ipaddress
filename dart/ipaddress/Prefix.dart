import 'IpBits.dart';
import 'IpVersion.dart';
import 'Result.dart';

typedef Result<Prefix> VtFrom(Prefix p, int n);

class Prefix {
  final int num;
  final IpBits ip_bits;
  final BigInt net_mask;
  final VtFrom vt_from;

  Prefix(this.num, this.ip_bits, this.net_mask, this.vt_from);

  Prefix clone() {
    return Prefix(num, ip_bits, net_mask, vt_from);
  }

  bool equal(Prefix other) {
    return this.ip_bits.version == other.ip_bits.version &&
        this.num == other.num;
  }

  String inspect() {
    return "Prefix: ${num}";
  }

  int compare(Prefix oth) {
    if (this.ip_bits.version == IpVersion.V4 &&
        oth.ip_bits.version == IpVersion.V6) {
      return -1;
    } else if (this.ip_bits.version == IpVersion.V6 &&
        oth.ip_bits.version == IpVersion.V4) {
      return 1;
    } else {
      if (this.num < oth.num) {
        return -1;
      } else if (this.num > oth.num) {
        return 1;
      } else {
        return 0;
      }
    }
  }

  Result<Prefix> from(int num) {
    return this.vt_from(this, num);
  }

  String to_ip_str() {
    return this.ip_bits.vt_as_compressed_string(this.ip_bits, this.netmask());
  }

  BigInt size() {
    return BigInt.from(1) << (this.ip_bits.bits - this.num);
  }

  static BigInt new_netmask(int prefix, int bits) {
    var mask = BigInt.from(0);
    final host_prefix = bits - prefix;
    for (var i = 0; i < prefix; i++) {
      mask += BigInt.from(1) << (host_prefix + i);
    }
    return mask;
  }

  BigInt netmask() {
    return BigInt.from(0) + this.net_mask;
  }

  int get_prefix() {
    return this.num;
  }

  ///  The hostmask is the contrary of the subnet mask,
  ///  as it shows the bits that can change within the
  ///  hosts
  ///
  ///    prefix = IPAddress::Prefix32.24
  ///
  ///    prefix.hostmask
  ///      ///  "0.0.0.255"
  ///
  BigInt host_mask() {
    var ret = BigInt.from(0);
    for (var i = 0; i < this.ip_bits.bits - this.num; i++) {
      ret = (ret << 1) + BigInt.from(1);
    }
    return ret;
  }

  ///
  ///  Returns the length of the host portion
  ///  of a netmask.
  ///
  ///    prefix = Prefix128.96
  ///
  ///    prefix.host_prefix
  ///      ///  128
  ///
  int host_prefix() {
    return (this.ip_bits.bits) - this.num;
  }

  ///
  ///  Transforms the prefix into a string of bits
  ///  representing the netmask
  ///
  ///    prefix = IPAddress::Prefix128.64
  ///
  ///    prefix.bits
  ///      ///  "1111111111111111111111111111111111111111111111111111111111111111"
  ///          "0000000000000000000000000000000000000000000000000000000000000000"
  ///
  String bits() {
    return this.netmask().toRadixString(2);
  }

  String to_s() {
    return "${this.get_prefix()}";
  }

  int to_i() {
    return this.get_prefix();
  }

  Result<Prefix> add_prefix(Prefix other) {
    return this.from(this.get_prefix() + other.get_prefix());
  }

  Result<Prefix> add(int other) {
    return this.from(this.get_prefix() + other);
  }

  Result<Prefix> sub_prefix(Prefix other) {
    return this.sub(other.get_prefix());
  }

  Result<Prefix> sub(int other) {
    if (other > this.get_prefix()) {
      return this.from(other - this.get_prefix());
    }
    return this.from(this.get_prefix() - other);
  }
}
