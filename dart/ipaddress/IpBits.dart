// #[derive(Debug, Clone)]
import 'dart:core';

import 'IpVersion.dart';
import 'Rle.dart';

typedef String Vt_as_string(IpBits b, BigInt bi);

class IpBits {
  final IpVersion version;
  int bits;
  int part_bits;
  int dns_bits;
  final String rev_domain;
  final BigInt part_mod;
  final BigInt host_ofs;

  final Vt_as_string vt_as_compressed_string;
  final Vt_as_string vt_as_uncompressed_string;

  IpBits(
      this.version,
      this.vt_as_compressed_string,
      this.vt_as_uncompressed_string,
      this.bits,
      this.part_bits,
      this.dns_bits,
      this.rev_domain,
      this.part_mod,
      this.host_ofs);

  static IpBits v4() {
    final ipv4_as_compressed = (IpBits ip_bits, BigInt host_address) {
      var sep = "";
      var ret = "";
      for (var part in ip_bits.parts(host_address)) {
        ret += sep;
        ret += part.toString();
        sep = ".";
      }
      return ret.toString();
    };
    return IpBits(IpVersion.V4, ipv4_as_compressed, ipv4_as_compressed, 32, 8,
        8, "in-addr.arpa", BigInt.from(1) << 8, BigInt.from(1));
  }

  static final IpBits V4 = v4();

  static IpBits v6() {
    final ipv6_as_compressed = (IpBits ip_bits, BigInt host_address) {
      //println!("ipv6_as_compressed:{}", host_address);
      var ret = "";
      var the_colon = ":";
      final the_empty = "";
      var colon = the_empty;
      var done = false;
      for (var rle in Rle.code(ip_bits.parts(host_address))) {
        var abort = false;
        for (var i = 0; !abort && i < rle.cnt; i++) {
          if (done || !(rle.part == 0 && rle.max)) {
            ret += colon;
            ret += rle.part.toRadixString(16);
            colon = the_colon;
          } else if (rle.part == 0 && rle.max) {
            ret += "::";
            colon = the_empty;
            done = true;
            abort = true;
          }
        }
      }
      return ret.toString();
    };
    final ipv6_as_uncompressed = (IpBits ip_bits, BigInt host_address) {
      var ret = "";
      var sep = "";
      for (var part in ip_bits.parts(host_address)) {
        ret += sep;
        ret += part.toRadixString(16).padLeft(4);
        sep = ":";
      }
      return ret.toString();
    };
    return IpBits(IpVersion.V6, ipv6_as_compressed, ipv6_as_uncompressed, 128,
        16, 4, "ip6.arpa", BigInt.from(1) << 16, BigInt.from(0));
  }

  static final IpBits V6 = v6();

  String Inspect() {
    return "IpBits: ${this.version}";
  }

  static List<int> reverse(List<int> data) {
    var right = data.length - 1;
    for (var left = 0; left < right; left++, right--) {
      // swap the values at the left and right indices
      final temp = data[left];
      data[left] = data[right];
      data[right] = temp;
    }
    return data;
  }

  List<int> parts(BigInt bu) {
    final len = (this.bits / this.part_bits);
    List<int> vec = [];
    var my = BigInt.from(0) + bu;
    var part_mod = BigInt.from(1) << this.part_bits; // - BigUint::one();
    for (var i = 0; i < len; i++) {
      final v = (my % part_mod).toInt();
      vec[i] = v;
      my = my >> this.part_bits;
    }
    return IpBits.reverse(vec);
  }

  String as_compressed_string(BigInt bu) {
    return this.vt_as_compressed_string(this, bu);
  }

  String as_uncompressed_string(BigInt bu) {
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

  String dns_part_format(int i) {
    switch (version) {
      case IpVersion.V4:
        return i.toString();
      case IpVersion.V6:
        return i.toRadixString(16).padLeft(1);
    }
    throw UnimplementedError('unknown ip version');
  }
}
