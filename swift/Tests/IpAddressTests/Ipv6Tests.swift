import Foundation
import XCTest
@testable import IpAddress

import BigInt

class IPv6Test {
  var compress_addr = [String: String]();
  var valid_ipv6 = [String: BigUInt]();
  let invalid_ipv6 = [":1:2:3:4:5:6:7", ":1:2:3:4:5:6:7", "2002:516:2:200", "dd"];
  var networks = [String: String]();
  let ip: IPAddress = IPAddress.parse("2001:db8::8:800:200c:417a/64")!;
  let network: IPAddress = IPAddress.parse("2001:db8:8:800::/64")!;
  let arr : [UInt]  = [8193, 3512, 0, 0, 8, 2048, 8204, 16762];
  let hex: String = "20010db80000000000080800200c417a";
}


class Ipv6Tests : XCTestCase {
  
  
  func setup() -> IPv6Test {
    let ip6t = IPv6Test();
    ip6t.compress_addr["2001:db8:0000:0000:0008:0800:200c:417a"] = "2001:db8::8:800:200c:417a";
    ip6t.compress_addr["2001:db8:0:0:8:800:200c:417a"] = "2001:db8.8:800:200c:417a";
    ip6t.compress_addr["ff01:0:0:0:0:0:0:101"] = "ff01::101";
    ip6t.compress_addr["0:0:0:0:0:0:0:1"] = ".1";
    ip6t.compress_addr["0:0:0:0:0:0:0:0"] = ".";
    
    ip6t.valid_ipv6["FEDC:BA98:7654:3210:FEDC:BA98:7654:3210"] = BigUInt("338770000845734292534325025077361652240") ;
    ip6t.valid_ipv6["1080:0000:0000:0000:0008:0800:200C:417A"] = BigUInt("21932261930451111902915077091070067066") ;
    ip6t.valid_ipv6["1080:0:0:0:8:800:200C:417A"] = BigUInt("21932261930451111902915077091070067066") ;
    ip6t.valid_ipv6["1080:0::8:800:200C:417A"] = BigUInt("21932261930451111902915077091070067066") ;
    ip6t.valid_ipv6["1080::8:800:200C:417A"] = BigUInt("21932261930451111902915077091070067066") ;
    ip6t.valid_ipv6["FF01:0:0:0:0:0:0:43"] = BigUInt("338958331222012082418099330867817087043") ;
    ip6t.valid_ipv6["FF01:0::0:0:43"] = BigUInt("338958331222012082418099330867817087043") ;
    ip6t.valid_ipv6["FF01::43"] = BigUInt("338958331222012082418099330867817087043") ;
    ip6t.valid_ipv6["0:0:0:0:0:0:0:1"] = BigUInt("1");
    ip6t.valid_ipv6["0:0:0::0:0:1"] = BigUInt("1");
    ip6t.valid_ipv6["::1"] = BigUInt("1");
    ip6t.valid_ipv6["0:0:0:0:0:0:0:0"] = BigUInt("0");
    ip6t.valid_ipv6["0:0:0::0:0:0"] = BigUInt("0");
    ip6t.valid_ipv6["::"] = BigUInt("0");
    ip6t.valid_ipv6["::/0"] = BigUInt("0");
    ip6t.valid_ipv6["1080:0:0:0:8:800:200C:417A"] = BigUInt("21932261930451111902915077091070067066") ;
    ip6t.valid_ipv6["1080::8:800:200C:417A"] = BigUInt("21932261930451111902915077091070067066") ;
    
    ip6t.networks["2001:db8:1:1:1:1:1:1/32"] = "2001:db8::/32";
    ip6t.networks["2001:db8:1:1:1:1:1::/32"] = "2001:db8::/32";
    ip6t.networks["2001:db8::1/64"] = "2001:db8::/64";
    return ip6t;
  }
  
  func test_attribute_address() {
    let addr = "2001:0db8:0000:0000:0008:0800:200c:417a";
    XCTAssertEqual(addr, setup().ip.to_s_uncompressed());
  }
  func test_initialize() {
    XCTAssertEqual(false, setup().ip.is_ipv4());
    
    for (ip, _) in setup().valid_ipv6 {
      XCTAssertNotNil(IPAddress.parse(ip));
    }
    for ip in setup().invalid_ipv6 {
      XCTAssertNil(IPAddress.parse(ip));
    }
    XCTAssertEqual(64, setup().ip.prefix.num);
    
    XCTAssertNotNil(IPAddress.parse("::10.1.1.1"));
  }
  func test_attribute_groups() {
    XCTAssertEqual(setup().arr, setup().ip.parts())
  }
  func test_method_hexs() {
    let arr = ["2001", "0db8", "0000", "0000", "0008", "0800", "200c", "417a"];
    XCTAssertEqual(setup().ip.parts_hex_str(), arr);
  }
  
  func test_method_to_i() {
    for (ip, num) in setup().valid_ipv6 {
      XCTAssertEqual(num, IPAddress.parse(ip)!.host_address);
    }
  }
  func test_method_set_prefix() {
    let ip = IPAddress.parse("2001:db8::8:800:200c:417a")!;
    XCTAssertEqual(128, ip.prefix.num);
    XCTAssertEqual("2001:db8::8:800:200c:417a/128", ip.to_string());
    let nip = ip.change_prefix(64)!;
    XCTAssertEqual(64, nip.prefix.num);
    XCTAssertEqual("2001:db8::8:800:200c:417a/64", nip.to_string());
  }
  func test_method_mapped() {
    XCTAssertEqual(false, setup().ip.is_mapped());
    let ip6 = IPAddress.parse("::ffff:1234:5678")!;
    XCTAssertEqual(true, ip6.is_mapped());
  }
  func test_method_group() {
    let s = setup();
    XCTAssertEqual(s.ip.parts(), s.arr);
  }
  func test_method_ipv4() {
    XCTAssertEqual(false, setup().ip.is_ipv4());
  }
  func test_method_ipv6() {
    XCTAssertEqual(true, setup().ip.is_ipv6());
  }
  func test_method_network_known() {
    XCTAssertEqual(true, setup().network.is_network());
    XCTAssertEqual(false, setup().ip.is_network());
  }
  func test_method_network_u128() {
    XCTAssertNotNil(Ipv6.from_int(BigUInt("42540766411282592856903984951653826560")!, 64)!.eq(setup().ip.network()));
  }
  func test_method_broadcast_u128() {
    XCTAssertNotNil(Ipv6.from_int(BigUInt("42540766411282592875350729025363378175")!, 64)!.eq(setup().ip.broadcast()));
  }
  func test_method_size() {
    var ip = IPAddress.parse("2001:db8::8:800:200c:417a/64")!;
    XCTAssertEqual(BigUInt(1)<<64, ip.size());
    ip = IPAddress.parse("2001:db8::8:800:200c:417a/32")!;
    XCTAssertEqual(BigUInt(1)<<96, ip.size());
    ip = IPAddress.parse("2001:db8::8:800:200c:417a/120")!;
    XCTAssertEqual(BigUInt(1)<<8, ip.size());
    ip = IPAddress.parse("2001:db8::8:800:200c:417a/124")!;
    XCTAssertEqual(BigUInt(1)<<4, ip.size());
  }
  func test_method_includes() {
    let ip = setup().ip;
    XCTAssertEqual(true, ip.includes(ip));
    // test prefix on same address
    var included = IPAddress.parse("2001:db8::8:800:200c:417a/128")!;
    var not_included = IPAddress.parse("2001:db8::8:800:200c:417a/46")!;
    XCTAssertEqual(true, ip.includes(included));
    XCTAssertEqual(false, ip.includes(not_included));
    // test address on same prefix
    included = IPAddress.parse("2001:db8::8:800:200c:0/64")!;
    not_included = IPAddress.parse("2001:db8:1::8:800:200c:417a/64")!;
    XCTAssertEqual(true, ip.includes(included));
    XCTAssertEqual(false, ip.includes(not_included));
    // general test
    included = IPAddress.parse("2001:db8::8:800:200c:1/128")!;
    not_included = IPAddress.parse("2001:db8:1::8:800:200c:417a/76")!;
    XCTAssertEqual(true, ip.includes(included));
    XCTAssertEqual(false, ip.includes(not_included));
  }
  
  func test_method_to_hex() {
    XCTAssertEqual(setup().hex, setup().ip.to_hex());
  }
  
  func test_method_to_s() {
    XCTAssertEqual("2001:db8::8:800:200c:417a", setup().ip.to_s());
  }
  
  func test_method_to_string() {
    XCTAssertEqual("2001:db8::8:800:200c:417a/64", setup().ip.to_string());
  }
  
  func test_method_to_string_uncompressed() {
    let str = "2001:0db8:0000:0000:0008:0800:200c:417a/64";
    XCTAssertEqual(str, setup().ip.to_string_uncompressed());
  }
  
  func test_method_reverse() {
    let str = "f.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.2.0.0.0.5.0.5.0.e.f.f.3.ip6.arpa";
    XCTAssertEqual(str,
                   IPAddress.parse("3ffe:505:2::f")!.dns_reverse());
  }
  
  func test_method_dns_rev_domains() {
    XCTAssertEqual(IPAddress.parse("f000:f100::/3")!.dns_rev_domains(),
                   ["e.ip6.arpa", "f.ip6.arpa"]);
    XCTAssertEqual(IPAddress.parse("fea3:f120::/15")!.dns_rev_domains(),
                   ["2.a.e.f.ip6.arpa", "3.a.e.f.ip6.arpa"]);
    XCTAssertEqual(IPAddress.parse("3a03:2f80:f::/48")!.dns_rev_domains(),
                   ["f.0.0.0.0.8.f.2.3.0.a.3.ip6.arpa"]);
    
    XCTAssertEqual(IPAddress.parse("f000:f100::1234/125")!.dns_rev_domains(),
                   ["0.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
                    "1.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
                    "2.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
                    "3.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
                    "4.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
                    "5.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
                    "6.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
                    "7.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa"]);
  }
  
  func test_method_compressed() {
    XCTAssertEqual("1:1:1::1",
                   IPAddress.parse("1:1:1:0:0:0:0:1")!.to_s());
    XCTAssertEqual("1:0:1::1",
                   IPAddress.parse("1:0:1:0:0:0:0:1")!.to_s());
    XCTAssertEqual("1::1:1:1:2:3:1",
                   IPAddress.parse("1:0:1:1:1:2:3:1")!.to_s());
    XCTAssertEqual("1::1:1:0:2:3:1",
                   IPAddress.parse("1:0:1:1::2:3:1")!.to_s());
    XCTAssertEqual("1:0:0:1::1",
                   IPAddress.parse("1:0:0:1:0:0:0:1")!.to_s());
    XCTAssertEqual("1::1:0:0:1",
                   IPAddress.parse("1:0:0:0:1:0:0:1")!.to_s());
    XCTAssertEqual("1::1", IPAddress.parse("1:0:0:0:0:0:0:1")!.to_s());
    // XCTAssertEqual("1:1.1:2:0:0:1", IPAddress.parse("1:1:0:1:2.1")!.to_s
  }
  
  func test_method_unspecified() {
    XCTAssertEqual(true, IPAddress.parse("::")!.is_unspecified());
    XCTAssertEqual(false, setup().ip.is_unspecified());
  }
  
  func test_method_loopback() {
    XCTAssertEqual(true, IPAddress.parse("::1")!.is_loopback());
    XCTAssertEqual(false, setup().ip.is_loopback());
  }
  
  func test_method_network() {
    for (addr, net) in setup().networks {
      let ip = IPAddress.parse(addr)!;
      XCTAssertEqual(net, ip.network().to_string());
    }
  }
  func test_method_each() {
    let ip = IPAddress.parse("2001:db8::4/125")!;
    var arr: [String] = [String]();
    ip.each({ arr.append($0.to_s()) });
    XCTAssertEqual(arr, ["2001:db8::", "2001:db8::1", "2001:db8::2", "2001:db8::3",
                         "2001:db8::4", "2001:db8::5", "2001:db8::6", "2001:db8::7"]);
  }
  
  func test_method_each_net() {
    let test_addrs = ["0000:0000:0000:0000:0000:0000:0000:0000",
                      "1111:1111:1111:1111:1111:1111:1111:1111",
                      "2222:2222:2222:2222:2222:2222:2222:2222",
                      "3333:3333:3333:3333:3333:3333:3333:3333",
                      "4444:4444:4444:4444:4444:4444:4444:4444",
                      "5555:5555:5555:5555:5555:5555:5555:5555",
                      "6666:6666:6666:6666:6666:6666:6666:6666",
                      "7777:7777:7777:7777:7777:7777:7777:7777",
                      "8888:8888:8888:8888:8888:8888:8888:8888",
                      "9999:9999:9999:9999:9999:9999:9999:9999",
                      "aaaa:aaaa:aaaa:aaaa:aaaa:aaaa:aaaa:aaaa",
                      "bbbb:bbbb:bbbb:bbbb:bbbb:bbbb:bbbb:bbbb",
                      "cccc:cccc:cccc:cccc:cccc:cccc:cccc:cccc",
                      "dddd:dddd:dddd:dddd:dddd:dddd:dddd:dddd",
                      "eeee:eeee:eeee:eeee:eeee:eeee:eeee:eeee",
                      "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff"];
    for prefix in 0...128 {
      let nr_networks = 1 << ((128 - prefix) % 4);
      for adr in test_addrs {
        let net_adr = IPAddress.parse("\(adr)/\(prefix)")!;
        let ret = net_adr.dns_networks();
        XCTAssertEqual(ret[0].prefix.num % 4, 0);
        XCTAssertEqual(ret.count, nr_networks);
        XCTAssertEqual(net_adr.network().to_s(), ret[0].network().to_s());
        XCTAssertEqual(net_adr.broadcast().to_s(), ret[ret.count - 1].broadcast().to_s());
        //        puts "//{adr}///{prefix} //{nr_networks} //{ret}"
      }
    }
    var ret0 = [String]();
    for i in IPAddress.parse("fd01:db8::4/3")!.dns_networks() {
      ret0.append(i.to_string());
    }
    XCTAssertEqual(ret0, ["e000::/4", "f000::/4"]);
    var ret1 = [String]();
    for i in IPAddress.parse("3a03:2f80:f::/48")!.dns_networks() {
      ret1.append(i.to_string());
    }
    XCTAssertEqual(ret1, ["3a03:2f80:f::/48"]);
  }
  func test_method_compare() {
    let ip1 = IPAddress.parse("2001:db8:1::1/64")!;
    let ip2 = IPAddress.parse("2001:db8:2::1/64")!;
    let ip3 = IPAddress.parse("2001:db8:1::2/64")!;
    let ip4 = IPAddress.parse("2001:db8:1::1/65")!;
    
    // ip2 should be greater than ip1
    XCTAssertEqual(true, ip2.gt(ip1));
    XCTAssertEqual(false, ip1.gt(ip2));
    XCTAssertEqual(false, ip2.lt(ip1));
    // ip3 should be less than ip2
    XCTAssertEqual(true, ip2.gt(ip3));
    XCTAssertEqual(false, ip2.lt(ip3));
    // ip1 should be less than ip3
    XCTAssertEqual(true, ip1.lt(ip3));
    XCTAssertEqual(false, ip1.gt(ip3));
    XCTAssertEqual(false, ip3.lt(ip1));
    // ip1 should be equal to itself
    XCTAssertEqual(true, ip1.eq(ip1));
    // ip4 should be greater than ip1
    XCTAssertEqual(true, ip1.lt(ip4));
    XCTAssertEqual(false, ip1.gt(ip4));
    // test sorting
    let r = [ip1, ip2, ip3, ip4].sorted(by: { $0.lt($1) })
    var ret = [String]();
    for i in r {
      ret.append(i.to_string());
    }
    XCTAssertEqual(ret, ["2001:db8:1::1/64", "2001:db8:1::1/65", "2001:db8:1::2/64", "2001:db8:2::1/64"]);
  }
  
  // func test_classmethod_expand() {
  //   let compressed = "2001:db8:0:cd30.";
  //   let expanded = "2001:0db8:0000:cd30:0000:0000:0000:0000";
  //   XCTAssertEqual(expanded, @klass.expand(compressed));
  //   XCTAssertEqual(expanded, @klass.expand("2001:0db8:0.cd3"));
  //   XCTAssertEqual(expanded, @klass.expand("2001:0db8.cd30"));
  //   XCTAssertEqual(expanded, @klass.expand("2001:0db8.cd3"));
  // }
  
  func test_classmethod_compress() {
    let compressed = "2001:db8:0:cd30::";
    let expanded = "2001:0db8:0000:cd30:0000:0000:0000:0000";
    XCTAssertEqual(compressed, IPAddress.parse(expanded)!.to_s());
    XCTAssertEqual("2001:db8::cd3",
                   IPAddress.parse("2001:0db8:0::cd3")!.to_s());
    XCTAssertEqual("2001:db8::cd30",
                   IPAddress.parse("2001:0db8::cd30")!.to_s());
    XCTAssertEqual("2001:db8::cd3",
                   IPAddress.parse("2001:0db8::cd3")!.to_s());
  }
  func test_classhmethod_parse_u128() {
    for (ip, num) in setup().valid_ipv6 {
      //console.log(">>>>>>>>", i);
      XCTAssertEqual(IPAddress.parse(ip)!.to_s(), Ipv6.from_int(num, 128)!.to_s());
    }
  }
  func test_classmethod_parse_hex() {
    XCTAssertEqual(setup().ip.to_string(),
                   Ipv6.from_str(setup().hex, 16, 64)!.to_string());
  }
  static var allTests : [(String, (Ipv6Tests) -> () throws -> Void)] {
    return [
      ("test_attribute_address", test_attribute_address),
      ("test_initialize", test_initialize),
      ("test_attribute_groups", test_attribute_groups),
      ("test_method_hexs", test_method_hexs),
      ("test_method_to_i", test_method_to_i),
      ("test_method_set_prefix", test_method_set_prefix),
      ("test_method_mapped", test_method_mapped),
      ("test_method_group", test_method_group),
      ("test_method_ipv4", test_method_ipv4),
      ("test_method_ipv6", test_method_ipv6),
      ("test_method_network_known", test_method_network_known),
      ("test_method_network_u128", test_method_network_u128),
      ("test_method_broadcast_u128", test_method_broadcast_u128),
      ("test_method_size", test_method_size),
      ("test_method_includes", test_method_includes),
      ("test_method_to_hex", test_method_to_hex),
      ("test_method_to_s", test_method_to_s),
      ("test_method_to_string", test_method_to_string),
      ("test_method_to_string_uncompressed", test_method_to_string_uncompressed),
      ("test_method_reverse", test_method_reverse),
      ("test_method_dns_rev_domains", test_method_dns_rev_domains),
      ("test_method_compressed", test_method_compressed),
      ("test_method_unspecified", test_method_unspecified),
      ("test_method_loopback", test_method_loopback),
      ("test_method_network", test_method_network),
      ("test_method_each", test_method_each),
      ("test_method_each_net", test_method_each_net),
      ("test_method_compare", test_method_compare),
      ("test_classmethod_compress", test_classmethod_compress),
      ("test_classhmethod_parse_u128", test_classhmethod_parse_u128),
      ("test_classmethod_parse_hex", test_classmethod_parse_hex),
    ]
  }
}
