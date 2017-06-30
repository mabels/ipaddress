import XCTest
@testable import IpAddress
import BigInt

class IPv6UnspecifiedTest {
  let ip: IPAddress;
  let to_s: String;
  let to_string: String;
  let to_string_uncompressed: String;
  let num: BigUInt;
  init(ip: IPAddress, to_s: String, to_string: String, to_string_uncompressed: String, num: BigUInt) {
    self.ip = ip;
    self.to_s = to_s;
    self.to_string = to_string;
    self.to_string_uncompressed = to_string_uncompressed;
    self.num = num;
  }
}

class Ipv6UnspecTests: XCTestCase {
  
  func setup() -> IPv6UnspecifiedTest {
    return IPv6UnspecifiedTest(
      ip: Ipv6Unspec.create(),
      to_s: "::",
      to_string: "::/128",
      to_string_uncompressed: "0000:0000:0000:0000:0000:0000:0000:0000/128",
      num: BigUInt(0)
    );
  }
  
  func test_attributes() {
    XCTAssertEqual(setup().ip.host_address, setup().num);
    XCTAssertEqual(128, setup().ip.prefix.num);
    XCTAssertEqual(true, setup().ip.is_unspecified());
    XCTAssertEqual(setup().to_s, setup().ip.to_s());
    XCTAssertEqual(setup().to_string, setup().ip.to_string());
    XCTAssertEqual(setup().to_string_uncompressed, setup().ip.to_string_uncompressed());
  }
  func test_method_ipv6() {
    XCTAssertEqual(true, setup().ip.is_ipv6());
  }
  static var allTests : [(String, (Ipv6UnspecTests) -> () throws -> Void)] {
    return [
      ("test_attributes", test_attributes),
      ("test_method_ipv6", test_method_ipv6),
    ]
  }
}
