import 'package:test/test.dart';

import '../Prefix128.dart';

class Prefix128Test {
  Map<int, BigInt> u128_hash = {};
}

Prefix128Test setup() {
  final p128t = Prefix128Test();
  p128t.u128_hash[32] = BigInt.parse("340282366841710300949110269838224261120");
  p128t.u128_hash[64] = BigInt.parse("340282366920938463444927863358058659840");
  p128t.u128_hash[96] = BigInt.parse("340282366920938463463374607427473244160");
  p128t.u128_hash[126] =
      BigInt.parse("340282366920938463463374607431768211452");
  return p128t;
}

void main() {
  test("test_initialize", () {
    expect(Prefix128.create(129).isFailure, true);
    expect(Prefix128.create(64).isSuccess, true);
  });

  test("test_method_bits", () {
    var prefix = Prefix128.create(64).value;
    var str = "";
    for (var i = 0; i < 64; i++) {
      str += "1";
    }
    for (var i = 0; i < 64; i++) {
      str += "0";
    }
    expect(str.toString(), prefix.bits());
  });

  test("test_method_to_u32", () {
    setup().u128_hash.forEach(
        (num, u128) => expect(u128, Prefix128.create(num).value.netmask()));
  });
}
