import 'package:test/test.dart';

import '../IPAddress.dart';
import '../Ipv6Loopback.dart';

class IPv6LoopbackTest {
  IPAddress ip;
  String s;
  String n;
  String string;
  BigInt one;
  IPv6LoopbackTest(
      IPAddress ip, String s, String n, String string, BigInt one) {
    this.ip = ip;
    this.s = s;
    this.n = n;
    this.string = string;
    this.one = one;
  }
}

IPv6LoopbackTest setup() {
  return IPv6LoopbackTest(Ipv6Loopback.create(), "::1", "::1/128",
      "0000:0000:0000:0000:0000:0000:0000:0001/128", BigInt.one);
}

void main() {
  test("test_attributes", () {
    final s = setup();
    expect(128, s.ip.prefix.num);
    expect(true, s.ip.is_loopback());
    expect(s.s, s.ip.to_s());
    expect(s.n, s.ip.to_string());
    expect(s.string, s.ip.to_string_uncompressed());
    expect(s.one, s.ip.host_address);
  });

  test("test_method_ipv6", () {
    expect(true, setup().ip.is_ipv6());
  });
}
