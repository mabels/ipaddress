import 'package:test/test.dart';

import '../IPAddress.dart';
import '../Ipv6Mapped.dart';

class IPv6MappedTest {
  IPAddress ip;
  String s;
  String sstr;
  String string;
  BigInt u128;
  String address;
  Map<String, BigInt> valid_mapped = Map<String, BigInt>();
  Map<String, BigInt> valid_mapped_ipv6 = Map<String, BigInt>();
  Map<String, String> valid_mapped_ipv6_conversion = Map<String, String>();
  IPv6MappedTest(
      this.ip, this.s, this.sstr, this.string, this.u128, this.address);
}

IPv6MappedTest setup() {
  final ret = IPv6MappedTest(
      Ipv6Mapped.create("::172.16.10.1").value,
      "::ffff:172.16.10.1",
      "::ffff:172.16.10.1/32",
      "0000:0000:0000:0000:0000:ffff:ac10:0a01/128",
      BigInt.parse("281473568475649"),
      "::ffff:ac10:a01/128");
  ret.valid_mapped["::13.1.68.3"] = BigInt.parse(("281470899930115"));
  ret.valid_mapped["0:0:0:0:0:ffff:129.144.52.38"] =
      BigInt.parse(("281472855454758"));
  ret.valid_mapped["::ffff:129.144.52.38"] = BigInt.parse(("281472855454758"));
  ret.valid_mapped_ipv6["::ffff:13.1.68.3"] = BigInt.parse(("281470899930115"));
  ret.valid_mapped_ipv6["0:0:0:0:0:ffff:8190:3426"] =
      BigInt.parse(("281472855454758"));
  ret.valid_mapped_ipv6["::ffff:8190:3426"] = BigInt.parse(("281472855454758"));
  ret.valid_mapped_ipv6_conversion["::ffff:13.1.68.3"] = "13.1.68.3";
  ret.valid_mapped_ipv6_conversion["0:0:0:0:0:ffff:8190:3426"] =
      "129.144.52.38";
  ret.valid_mapped_ipv6_conversion["::ffff:8190:3426"] = "129.144.52.38";
  return ret;
}

void main() {
  test("test_initialize", () {
    final s = setup();
    expect(true, IPAddress.parse("::172.16.10.1").isSuccess);
    s.valid_mapped.forEach((ip, u128) {
      //println!("-{}--{}", ip, u128);
      //if IPAddress.parse(ip).is_err() {
      //    println!("{}", IPAddress.parse(ip).unwrapErr());
      //}
      expect(true, IPAddress.parse(ip).isSuccess);
      expect(u128, IPAddress.parse(ip).value.host_address);
    });
    s.valid_mapped_ipv6.forEach((ip, u128) {
      //println!("===={}=={:x}", ip, u128);
      expect(true, IPAddress.parse(ip).isSuccess);
      expect(u128, IPAddress.parse(ip).value.host_address);
    });
  });

  test("test_mapped_from_ipv6_conversion", () {
    setup().valid_mapped_ipv6_conversion.forEach((ip6, ip4) {
      //println!("+{}--{}", ip6, ip4);
      expect(ip4, IPAddress.parse(ip6).value.mapped?.to_s());
    });
  });

  test("test_attributes", () {
    final s = setup();
    expect(s.address, s.ip.to_string());
    expect(128, s.ip.prefix.num);
    expect(s.s, s.ip.to_s_mapped());
    expect(s.sstr, s.ip.to_string_mapped());
    expect(s.string, s.ip.to_string_uncompressed());
    expect(s.u128, s.ip.host_address);
  });

  test("test_method_ipv6", () {
    expect(setup().ip.is_ipv6(), true);
  });

  test("test_mapped", () {
    expect(setup().ip.is_mapped(), true);
  });
}
