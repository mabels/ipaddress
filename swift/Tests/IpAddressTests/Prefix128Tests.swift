import XCTest
import BigInt
@testable import IpAddress

class Prefix128Test {
  var u128_hash = [UInt8: BigUInt]()
}

func setup() -> Prefix128Test {
  let p128t = Prefix128Test();
  p128t.u128_hash[32] = BigUInt("340282366841710300949110269838224261120");
  p128t.u128_hash[64] = BigUInt("340282366920938463444927863358058659840");
  p128t.u128_hash[96] = BigUInt("340282366920938463463374607427473244160");
  p128t.u128_hash[126] = BigUInt("340282366920938463463374607431768211452");
  return p128t;
}

class Prefix128Tests : XCTestCase {

  func test_initialize() {
    XCTAssertNil(Prefix128.create(129));
    XCTAssertNotNil(Prefix128.create(64));
  }

  func test_method_bits() {
    let prefix = Prefix128.create(64)!;
    var str = "";
    for _ in 1...64 {
      str += "1";
    }
    for _ in 1...64 {
      str += "0";
    }
    XCTAssertEqual(str, prefix.bits())
  }
  func test_method_to_u32() {
    for (k,v) in setup().u128_hash {
      XCTAssertEqual(v, Prefix128.create(k)!.netmask())
    }
  }

    static var allTests : [(String, (Prefix128Tests) -> () throws -> Void)] {
        return [
("test_initialize", test_initialize),
("test_method_bits", test_method_bits),
("test_method_to_u32", test_method_to_u32),
        ]
    }
}
