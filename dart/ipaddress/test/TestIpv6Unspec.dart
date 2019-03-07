import 'package:test/test.dart';

import '../IPAddress.dart';
import '../Ipv6Unspec.dart';

class IPv6UnspecifiedTest {
  IPAddress ip;
  String to_s;
  String to_string;
  String to_string_uncompressed;
  BigInt num;
  IPv6UnspecifiedTest(IPAddress ip, String to_s, String to_string,
      String to_string_uncompressed, BigInt num) {
    this.ip = ip;
    this.to_s = to_s;
    this.to_string = to_string;
    this.to_string_uncompressed = to_string_uncompressed;
    this.num = num;
  }
}

IPv6UnspecifiedTest setup() {
  return IPv6UnspecifiedTest(Ipv6Unspec.create(), "::", "::/128",
      "0000:0000:0000:0000:0000:0000:0000:0000/128", BigInt.zero);
}

void main() {
  test("test_attributes", () {
    expect(setup().ip.host_address, setup().num);
    expect(128, setup().ip.prefix.get_prefix());
    expect(true, setup().ip.is_unspecified());
    expect(setup().to_s, setup().ip.to_s());
    expect(setup().to_string, setup().ip.to_string());
    expect(setup().to_string_uncompressed, setup().ip.to_string_uncompressed());
  });

  test("test_method_ipv6", () {
    expect(true, setup().ip.is_ipv6());
  });
}
