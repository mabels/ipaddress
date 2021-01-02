
import XCTest
//@testable import Swift

@testable import IpAddress

import BigInt

class Prefix32Test {
  let netmask0: String = "0.0.0.0";
  let netmask8: String = "255.0.0.0";
  let netmask16: String = "255.255.0.0";
  let netmask24: String = "255.255.255.0";
  let netmask30: String = "255.255.255.252";
  var netmasks: [String] = [String]();
  var prefix_hash  = [String: UInt8]();
  var octets_hash  = [UInt8: [UInt]]();
  var u32_hash = [UInt8: BigUInt]();
}

func setup() -> Prefix32Test {
  let p32t = Prefix32Test();
  p32t.netmasks.append(p32t.netmask0);
  p32t.netmasks.append(p32t.netmask8);
  p32t.netmasks.append(p32t.netmask16);
  p32t.netmasks.append(p32t.netmask24);
  p32t.netmasks.append(p32t.netmask30);
  p32t.prefix_hash["0.0.0.0"] = 0;
  p32t.prefix_hash["255.0.0.0"] = 8;
  p32t.prefix_hash["255.255.0.0"] = 16;
  p32t.prefix_hash["255.255.255.0"] = 24;
  p32t.prefix_hash["255.255.255.252"] = 30;
  p32t.octets_hash[0] = [0, 0, 0, 0];
  p32t.octets_hash[8] = [255, 0, 0, 0];
  p32t.octets_hash[16] = [255, 255, 0, 0];
  p32t.octets_hash[24] = [255, 255, 255, 0];
  p32t.octets_hash[30] = [255, 255, 255, 252];
  p32t.u32_hash[0] = BigUInt(0);
  p32t.u32_hash[8] = BigUInt("4278190080");
  p32t.u32_hash[16] = BigUInt("4294901760");
  p32t.u32_hash[24] = BigUInt("4294967040");
  p32t.u32_hash[30] = BigUInt("4294967292");
  return p32t;
}

class Prefix32Tests: XCTestCase {
  
  func test_attributes() {
    for (_, e) in setup().prefix_hash {
      let prefix = Prefix32.create(e)!;
      XCTAssertEqual(e, prefix.num);
    }
  }
  
  func test_parse_netmask_to_prefix() {
    for (netmask, num) in setup().prefix_hash {
      // console.log(e);
      let prefix = IPAddress.parse_netmask_to_prefix(netmask)!;
      XCTAssertEqual(num, prefix);
    }
  }
  func test_method_to_ip() {
    for (netmask, num) in setup().prefix_hash {
      let prefix = Prefix32.create(num)!;
      XCTAssertEqual(netmask, prefix.to_ip_str())
    }
  }
  func test_method_to_s() {
    let prefix = Prefix32.create(8)!;
    XCTAssertEqual("8", prefix.to_s())
  }
  func test_method_bits() {
    let prefix = Prefix32.create(16)!;
    XCTAssertEqual("11111111111111110000000000000000", prefix.bits())
  }
  func test_method_to_u32() {
    for (num, ip32) in setup().u32_hash {
      XCTAssertEqual(ip32, Prefix32.create(num)!.netmask());
    }
  }
  func test_method_plus() {
    let p1 = Prefix32.create(8)!;
    let p2 = Prefix32.create(10)!;
    XCTAssertEqual(18, p1.add_prefix(p2)!.num);
    XCTAssertEqual(12, p1.add(4)!.num)
  }
  func test_method_minus() {
    let p1 = Prefix32.create(8)!;
    let p2 = Prefix32.create(24)!;
    XCTAssertEqual(16, p1.sub_prefix(p2)!.num);
    XCTAssertEqual(16, p2.sub_prefix(p1)!.num);
    XCTAssertEqual(20, p2.sub(4)!.num);
  }
  func test_initialize() {
    XCTAssertNil(Prefix32.create(33));
    XCTAssertNotNil(Prefix32.create(8));
  }
  func test_method_octets() {
    for (pref, arr) in setup().octets_hash {
      let prefix = Prefix32.create(pref)!;
      XCTAssertEqual(prefix.ip_bits.parts(prefix.netmask()), arr);
    }
  }
  func test_method_brackets() {
    for (pref, arr) in setup().octets_hash {
      let prefix = Prefix32.create(pref)!;
      for index in stride(from:0, to:arr.count, by:1) {
        // console.log("xxxx", prefix.netmask());
        XCTAssertEqual(prefix.ip_bits.parts(prefix.netmask())[index], arr[index]);
      }
    }
  }
  func test_method_hostmask() {
    let prefix = Prefix32.create(8)!;
    // console.log(">>>>", prefix.host_mask());
    XCTAssertEqual("0.255.255.255", Ipv4.from_int(prefix.host_mask(), 0)!.to_s());
  }
  
  static var allTests : [(String, (Prefix32Tests) -> () throws -> Void)] {
    return [
      ("test_attributes", test_attributes),
      ("test_parse_netmask_to_prefix", test_parse_netmask_to_prefix),
      ("test_method_to_ip", test_method_to_ip),
      ("test_method_to_s", test_method_to_s),
      ("test_method_bits", test_method_bits),
      ("test_method_to_u32", test_method_to_u32),
      ("test_method_plus", test_method_plus),
      ("test_method_minus", test_method_minus),
      ("test_initialize", test_initialize),
      ("test_method_octets", test_method_octets),
      ("test_method_brackets", test_method_brackets),
      ("test_method_hostmask", test_method_hostmask),
    ]
  }
}
