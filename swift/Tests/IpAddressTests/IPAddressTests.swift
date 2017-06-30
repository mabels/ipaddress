import XCTest
import BigInt
@testable import IpAddress

class IPAddressTest {
  let valid_ipv4: String = "172.16.10.1/24";
  let valid_ipv6: String = "2001:db8::8:800:200c:417a/64";
  let valid_mapped: String = "::13.1.68.3";
  let invalid_ipv4: String = "10.0.0.256";
  let invalid_ipv6: String = ":1:2:3:4:5:6:7";
  let invalid_mapped: String = "::1:2.3.4";
}

class Range {
  let start: Int;
  let target: Int;
  init(_ start: Int, _ target : Int) {
    self.start = start
    self.target = target
  }
}


class IPAddressTests: XCTestCase {
  
  func setup() -> IPAddressTest {
    return IPAddressTest();
  }
  
  func test_method_ipaddress() {
    XCTAssertNotNil(IPAddress.parse(setup().valid_ipv4));
    XCTAssertNotNil(IPAddress.parse(setup().valid_ipv6));
    XCTAssertNotNil(IPAddress.parse(setup().valid_mapped));
    
    XCTAssertTrue(IPAddress.parse(setup().valid_ipv4)!.is_ipv4());
    XCTAssertTrue(IPAddress.parse(setup().valid_ipv6)!.is_ipv6());
    XCTAssertTrue(IPAddress.parse(setup().valid_mapped)!.is_mapped());
    
    XCTAssertNil(IPAddress.parse(setup().invalid_ipv4));
    XCTAssertNil(IPAddress.parse(setup().invalid_ipv6));
    XCTAssertNil(IPAddress.parse(setup().invalid_mapped));
  }
  
  func test_module_method_valid() {
    XCTAssertEqual(true, IPAddress.is_valid("10.0.0.1"));
    XCTAssertEqual(true, IPAddress.is_valid("10.0.0.0"));
    XCTAssertEqual(true, IPAddress.is_valid("2002::1"));
    XCTAssertEqual(true, IPAddress.is_valid("dead:beef:cafe:babe::f0ad"));
    XCTAssertEqual(false, IPAddress.is_valid("10.0.0.256"));
    XCTAssertEqual(false, IPAddress.is_valid("10.0.0.0.0"));
    XCTAssertEqual(true, IPAddress.is_valid("10.0.0"));
    XCTAssertEqual(true, IPAddress.is_valid("10.0"));
    XCTAssertEqual(false, IPAddress.is_valid("2002:516:2:200"));
    XCTAssertEqual(false, IPAddress.is_valid("2002:::1"));
  }
  
  func test_module_method_valid_ipv4_netmark() {
    XCTAssertEqual(true, IPAddress.is_valid_netmask("255.255.255.0"));
    XCTAssertEqual(false, IPAddress.is_valid_netmask("10.0.0.1"));
  }
  
  func test_summarize() {
    var netstr =  [String]()
    for range in [Range(1, 10), Range(11, 127), Range(128, 169), Range(170, 172),
                  Range(173, 192), Range(193, 224)] {
                    for i in range.start...range.target-1 {
                      netstr.append("\(i).0.0.0/8");
                    }
    }
    for i in 0...255 {
      if (i != 254) {
        netstr.append("169.\(i).0.0/16");
      }
    }
    for i in 0...255 {
      if (i < 16 || 31 < i) {
        netstr.append("172.\(i).0.0/16");
      }
    }
    for i in 0...255 {
      if (i != 168) {
        netstr.append("192.\(i).0.0/16");
      }
    }
    var ip_addresses = [IPAddress]();
    for net in netstr {
      ip_addresses.append(IPAddress.parse(net)!);
    }
    
    let empty_vec = [String]();
    XCTAssertEqual(IPAddress.summarize_str(empty_vec)!.count, 0);
    XCTAssertEqual(IPAddress.to_string_vec(IPAddress.summarize_str(["10.1.0.4/24"])
      ),
                   ["10.1.0.0/24"]);
    XCTAssertEqual(IPAddress.to_string_vec(IPAddress.summarize_str(["2000:1::4711/32"])
      ),
                   ["2000:1::/32"]);
    
    XCTAssertEqual(IPAddress.to_string_vec(IPAddress.summarize_str(["10.1.0.4/24",
                                                                    "7.0.0.0/0",
                                                                    "1.2.3.4/4"])
      ),
                   ["0.0.0.0/0"]);
    XCTAssertEqual(IPAddress.to_string_vec(IPAddress.summarize_str(["2000:1::/32",
                                                                    "3000:1::/32",
                                                                    "2000:2::/32",
                                                                    "2000:3::/32",
                                                                    "2000:4::/32",
                                                                    "2000:5::/32",
                                                                    "2000:6::/32",
                                                                    "2000:7::/32",
                                                                    "2000:8::/32"])
      ),
                   ["2000:1::/32", "2000:2::/31", "2000:4::/30", "2000:8::/32", "3000:1::/32"]);
    
    XCTAssertEqual(IPAddress.to_string_vec(IPAddress.summarize_str(["10.0.1.1/24",
                                                                    "30.0.1.0/16",
                                                                    "10.0.2.0/24",
                                                                    "10.0.3.0/24",
                                                                    "10.0.4.0/24",
                                                                    "10.0.5.0/24",
                                                                    "10.0.6.0/24",
                                                                    "10.0.7.0/24",
                                                                    "10.0.8.0/24"])
      ),
                   ["10.0.1.0/24", "10.0.2.0/23", "10.0.4.0/22", "10.0.8.0/24", "30.0.0.0/16"]);
    
    XCTAssertEqual(IPAddress.to_string_vec(IPAddress.summarize_str(["10.0.0.0/23",
                                                                    "10.0.2.0/24"])
      ),
                   ["10.0.0.0/23", "10.0.2.0/24"]);
    XCTAssertEqual(IPAddress.to_string_vec(IPAddress.summarize_str(["10.0.0.0/24",
                                                                    "10.0.1.0/24",
                                                                    "10.0.2.0/23"])
      ),
                   ["10.0.0.0/22"]);
    
    
    XCTAssertEqual(IPAddress.to_string_vec(IPAddress.summarize_str(["10.0.0.0/16",
                                                                    "10.0.2.0/24"])
      ),
                   ["10.0.0.0/16"]);
    
    
    let cnt = 10;
    for _ in 0...cnt {
      XCTAssertEqual(IPAddress.to_string_vec(IPAddress.summarize(ip_addresses)),
                     ["1.0.0.0/8",
                      "2.0.0.0/7",
                      "4.0.0.0/6",
                      "8.0.0.0/7",
                      "11.0.0.0/8",
                      "12.0.0.0/6",
                      "16.0.0.0/4",
                      "32.0.0.0/3",
                      "64.0.0.0/3",
                      "96.0.0.0/4",
                      "112.0.0.0/5",
                      "120.0.0.0/6",
                      "124.0.0.0/7",
                      "126.0.0.0/8",
                      "128.0.0.0/3",
                      "160.0.0.0/5",
                      "168.0.0.0/8",
                      "169.0.0.0/9",
                      "169.128.0.0/10",
                      "169.192.0.0/11",
                      "169.224.0.0/12",
                      "169.240.0.0/13",
                      "169.248.0.0/14",
                      "169.252.0.0/15",
                      "169.255.0.0/16",
                      "170.0.0.0/7",
                      "172.0.0.0/12",
                      "172.32.0.0/11",
                      "172.64.0.0/10",
                      "172.128.0.0/9",
                      "173.0.0.0/8",
                      "174.0.0.0/7",
                      "176.0.0.0/4",
                      "192.0.0.0/9",
                      "192.128.0.0/11",
                      "192.160.0.0/13",
                      "192.169.0.0/16",
                      "192.170.0.0/15",
                      "192.172.0.0/14",
                      "192.176.0.0/12",
                      "192.192.0.0/10",
                      "193.0.0.0/8",
                      "194.0.0.0/7",
                      "196.0.0.0/6",
                      "200.0.0.0/5",
                      "208.0.0.0/4"]);
    }
    // end
    // printer = RubyProf.GraphPrinter.new(result)
    // printer.print(STDOUT, {})
    // test imutable input parameters
    let a1 = IPAddress.parse("10.0.0.1/24")!;
    let a2 = IPAddress.parse("10.0.1.1/24")!;
    XCTAssertEqual(IPAddress.to_string_vec(IPAddress.summarize([a1.clone(), a2.clone()])),
                   ["10.0.0.0/23"]);
    XCTAssertEqual("10.0.0.1/24", a1.to_string());
    XCTAssertEqual("10.0.1.1/24", a2.to_string());
  }
  
  static var allTests : [(String, (IPAddressTests) -> () throws -> Void)] {
    return [
      ("test_method_ipaddress", test_method_ipaddress),
      ("test_module_method_valid", test_module_method_valid),
      ("test_module_method_valid_ipv4_netmark", test_module_method_valid_ipv4_netmark),
      ("test_summarize", test_summarize)
    ]
  }
  
}
