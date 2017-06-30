import XCTest
@testable import IpAddress

import BigInt

class IPv6MappedTest {
  let ip: IPAddress;
  let s: String;
  let sstr: String;
  let string: String;
  let u128: BigUInt;
  let address: String;
  var valid_mapped = [String: BigUInt]();
  var valid_mapped_ipv6 = [String: BigUInt]();
  var valid_mapped_ipv6_conversion = [String: String]();
  init(ip: IPAddress, s: String, sstr: String, string: String, u128: BigUInt, address: String) {
    self.ip = ip;
    self.s = s;
    self.sstr = sstr;
    self.string = string;
    self.u128 = u128;
    self.address = address;
  }
}


class Ipv6MappedTests: XCTestCase {
  
  func setup()-> IPv6MappedTest {
    let ipv6 = IPv6MappedTest(
      ip: Ipv6Mapped.create("::172.16.10.1")!,
      s: "::ffff:172.16.10.1",
      sstr: "::ffff:172.16.10.1/32",
      string: "0000:0000:0000:0000:0000:ffff:ac10:0a01/128",
      u128: BigUInt("281473568475649")!,
      address: "::ffff:ac10:a01/128"
    );
    ipv6.valid_mapped["::13.1.68.3"] = BigUInt("281470899930115")!;
    ipv6.valid_mapped["0:0:0:0:0:ffff:129.144.52.38"] = BigUInt("281472855454758")!;
    ipv6.valid_mapped["::ffff:129.144.52.38"] = BigUInt("281472855454758")!;
    ipv6.valid_mapped_ipv6["::ffff:13.1.68.3"] = BigUInt("281470899930115")!;
    ipv6.valid_mapped_ipv6["0:0:0:0:0:ffff:8190:3426"] = BigUInt("281472855454758")!;
    ipv6.valid_mapped_ipv6["::ffff:8190:3426"] = BigUInt("281472855454758")!;
    ipv6.valid_mapped_ipv6_conversion["::ffff:13.1.68.3"] = "13.1.68.3";
    ipv6.valid_mapped_ipv6_conversion["0:0:0:0:0:ffff:8190:3426"] = "129.144.52.38";
    ipv6.valid_mapped_ipv6_conversion["::ffff:8190:3426"] = "129.144.52.38";
    return ipv6;
  }
  
  func test_initialize() {
    let s = setup();
    XCTAssertNotNil(IPAddress.parse("::172.16.10.1")!);
    for (ip, u128) in s.valid_mapped {
      // println("-{}--{}", ip, u128);
      XCTAssertNotNil(IPAddress.parse(ip));
      XCTAssertEqual(u128, IPAddress.parse(ip)!.host_address);
    }
    for (ip, u128) in s.valid_mapped_ipv6 {
      // println("===={}=={:x}", ip, u128);
      XCTAssertNotNil(IPAddress.parse(ip));
      XCTAssertEqual(u128, IPAddress.parse(ip)!.host_address);
    }
  }
  func test_mapped_from_ipv6_conversion() {
    for (ip6, ip4) in setup().valid_mapped_ipv6_conversion {
      XCTAssertEqual(ip4, IPAddress.parse(ip6)!.mapped!.to_s());
    }
  }
  func test_attributes() {
    let s = setup();
    XCTAssertEqual(s.address, s.ip.to_string());
    XCTAssertEqual(128, s.ip.prefix.num);
    XCTAssertEqual(s.s, s.ip.to_s_mapped());
    XCTAssertEqual(s.sstr, s.ip.to_string_mapped());
    XCTAssertEqual(s.string, s.ip.to_string_uncompressed());
    XCTAssertEqual(s.u128, s.ip.host_address);
  }
  func test_method_ipv6() {
    XCTAssertTrue(setup().ip.is_ipv6());
  }
  func test_mapped() {
    XCTAssertTrue(setup().ip.is_mapped());
  }
  static var allTests : [(String, (Ipv6MappedTests) -> () throws -> Void)] {
    return [
      ("test_initialize", test_initialize),
      ("test_mapped_from_ipv6_conversion", test_mapped_from_ipv6_conversion),
      ("test_attributes", test_attributes),
      ("test_method_ipv6", test_method_ipv6),
      ("test_mapped", test_mapped),
    ]
  }
}
