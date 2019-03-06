import 'package:test/test.dart';

import '../IPAddress.dart';
import '../IpV4.dart';
import '../Prefix32.dart';

class Prefix32Test {
  String netmask0;
  String netmask8;
  String netmask16;
  String netmask24;
  String netmask30;
  List<String> netmasks = List<String>();
  Map<String, int> prefix_hash = Map<String, int>();
  Map<List<int>, int> octets_hash = Map<List<int>, int>();
  Map<int, int> u32_hash = Map<int, int>();
  Prefix32Test(String netmask0, String netmask8, String netmask16,
      String netmask24, String netmask30) {
    this.netmask0 = netmask0;
    this.netmask8 = netmask8;
    this.netmask16 = netmask16;
    this.netmask24 = netmask24;
    this.netmask30 = netmask30;
  }
}

Prefix32Test setup() {
  var p32t = Prefix32Test("0.0.0.0", "255.0.0.0", "255.255.0.0",
      "255.255.255.0", "255.255.255.252");
  p32t.netmasks.add(p32t.netmask0);
  p32t.netmasks.add(p32t.netmask8);
  p32t.netmasks.add(p32t.netmask16);
  p32t.netmasks.add(p32t.netmask24);
  p32t.netmasks.add(p32t.netmask30);
  p32t.prefix_hash["0.0.0.0"] = 0;
  p32t.prefix_hash["255.0.0.0"] = 8;
  p32t.prefix_hash["255.255.0.0"] = 16;
  p32t.prefix_hash["255.255.255.0"] = 24;
  p32t.prefix_hash["255.255.255.252"] = 30;

  p32t.octets_hash[[0, 0, 0, 0]] = 0;
  p32t.octets_hash[[255, 0, 0, 0]] = 8;
  p32t.octets_hash[[255, 255, 0, 0]] = 16;
  p32t.octets_hash[[255, 255, 255, 0]] = 24;
  p32t.octets_hash[[255, 255, 255, 252]] = 30;

  p32t.u32_hash[0] = 0;
  p32t.u32_hash[8] = 4278190080;
  p32t.u32_hash[16] = 4294901760;
  p32t.u32_hash[24] = 4294967040;
  p32t.u32_hash[30] = 4294967292;
  return p32t;
}

void main() {
  test("test_attributes", () {
    for (var num in setup().prefix_hash.values) {
      final prefix = Prefix32.create(num).unwrap();
      expect(num, prefix.num);
    }
  });

  test("test_parse_netmask_to_prefix", () {
    setup().prefix_hash.forEach((netmask, num) {
      final prefix = IPAddress.parse_netmask_to_prefix(netmask).unwrap();
      expect(num, prefix);
    });
  });
  test("test_method_to_ip", () {
    setup().prefix_hash.forEach((netmask, num) {
      final prefix = Prefix32.create(num).unwrap();
      expect(netmask, prefix.to_ip_str());
    });
  });

  test("test_method_to_s", () {
    final prefix = Prefix32.create(8).unwrap();
    expect("8", prefix.to_s());
  });

  test("test_method_bits", () {
    final prefix = Prefix32.create(16).unwrap();
    expect("11111111111111110000000000000000", prefix.bits());
  });

  test("test_method_to_u32", () {
    setup().u32_hash.forEach((num, ip32) {
      expect(ip32, Prefix32.create(num).unwrap().netmask().toInt());
    });
  });

  test("test_method_plus", () {
    final p1 = Prefix32.create(8).unwrap();
    final p2 = Prefix32.create(10).unwrap();
    expect(18, p1.add_prefix(p2).unwrap().num);
    expect(12, p1.add(4).unwrap().num);
  });

  test("test_method_minus", () {
    final p1 = Prefix32.create(8).unwrap();
    final p2 = Prefix32.create(24).unwrap();
    expect(16, p1.sub_prefix(p2).unwrap().num);
    expect(16, p2.sub_prefix(p1).unwrap().num);
    expect(20, p2.sub(4).unwrap().num);
  });

  test("test_initialize", () {
    expect(Prefix32.create(33).isErr(), true);
    expect(Prefix32.create(8).isOk(), true);
  });

  test("test_method_octets", () {
    setup().octets_hash.forEach((arr, pref) {
      final prefix = Prefix32.create(pref).unwrap();
      expect(prefix.ip_bits.parts(prefix.netmask()), arr);
    });
  });

  test("test_method_brackets", () {
    setup().octets_hash.forEach((arr, pref) {
      final prefix = Prefix32.create(pref).unwrap();
      for (var index = 0; index < arr.length; index++) {
        final oct = arr[index];
        expect(prefix.ip_bits.parts(prefix.netmask())[index], oct);
      }
    });
  });

  test("test_method_hostmask", () {
    final prefix = Prefix32.create(8).unwrap();
    expect("0.255.255.255",
        IpV4.from_u32(prefix.host_mask().toInt(), 0).unwrap().to_s());
  });
}
