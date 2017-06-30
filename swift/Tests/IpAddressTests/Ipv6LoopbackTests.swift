import XCTest
@testable import IpAddress
import BigInt

class IPv6LoopbackTest {
  let ip: IPAddress;
  let s: String;
  let n: String;
  let string: String;
  let one: BigUInt;
  init(ip: IPAddress, s: String, n: String, string: String, one: BigUInt) {
    self.ip = ip
    self.s = s;
    self.n = n;
    self.string = string;
    self.one = one;
  }
}


class Ipv6LoopbackTests : XCTestCase {
  func setup() -> IPv6LoopbackTest {
    return IPv6LoopbackTest(
      ip: Ipv6Loopback.create(),
      s: "::1",
      n: "::1/128",
      string: "0000:0000:0000:0000:0000:0000:0000:0001/128",
      one: BigUInt(1)
    );
  }
  
  func test_attributes() {
    let s = setup();
    XCTAssertEqual(128, s.ip.prefix.num);
    XCTAssertEqual(true, s.ip.is_loopback());
    XCTAssertEqual(s.s, s.ip.to_s());
    XCTAssertEqual(s.n, s.ip.to_string());
    XCTAssertEqual(s.string, s.ip.to_string_uncompressed());
    XCTAssertEqual(String(s.one), String(s.ip.host_address));
  }
  func test_method_ipv6() {
    XCTAssertEqual(true, setup().ip.is_ipv6());
  }
  static var allTests : [(String, (Ipv6LoopbackTests) -> () throws -> Void)] {
    return [
      ("test_attributes", test_attributes),
      ("test_method_ipv6", test_method_ipv6),
    ]
  }
}
