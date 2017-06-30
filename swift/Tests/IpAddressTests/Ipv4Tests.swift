import Foundation
import XCTest

import BigInt

@testable import IpAddress

class IPv4Prefix {
  let ip: String;
  let prefix: UInt8;
  init(ip : String, prefix: UInt8) {
    self.ip = ip
    self.prefix = prefix
  }
}

class IPv4Test {
  var valid_ipv4 = [String: IPv4Prefix]();
  let invalid_ipv4 = ["10.0.0.256", "10.0.0.0.0"];
  let valid_ipv4_range = ["10.0.0.1-254", "10.0.1-254.0", "10.1-254.0.0"];
  var netmask_values = [String: String]();
  var decimal_values = [String: BigUInt]();
  let ip: IPAddress = IPAddress.parse("172.16.10.1/24")!;
  let network: IPAddress = IPAddress.parse("172.16.10.0/24")!;
  var networks = [String: String]();
  var broadcast = [String: String]();
  let class_a: IPAddress = IPAddress.parse("10.0.0.1/8")!;
  let class_b: IPAddress = IPAddress.parse("172.16.0.1/16")!;
  let class_c: IPAddress = IPAddress.parse("192.168.0.1/24")!;
  var classful = [String: UInt8]()
}


class Ipv4Tests : XCTestCase {


  func setup() -> IPv4Test {
    let ipv4t = IPv4Test();
    ipv4t.valid_ipv4["9.9/17"] = IPv4Prefix(
        ip: ("9.0.0.9"),
        prefix: 17
        )
      ipv4t.valid_ipv4["100.1.100"] = IPv4Prefix(
          ip: ("100.1.0.100"),
          prefix: 32
          )
      ipv4t.valid_ipv4["0.0.0.0/0"] = IPv4Prefix(
          ip: ("0.0.0.0"),
          prefix: 0
          )
      ipv4t.valid_ipv4["10.0.0.0"] = IPv4Prefix(
          ip: ("10.0.0.0"),
          prefix: 32
          )
      ipv4t.valid_ipv4["10.0.0.1"] = IPv4Prefix(
          ip: ("10.0.0.1"),
          prefix: 32
          )
      ipv4t.valid_ipv4["10.0.0.1/24"] = IPv4Prefix(
          ip: ("10.0.0.1"),
          prefix: 24
          )
      ipv4t.valid_ipv4["10.0.0.9/255.255.255.0"] = IPv4Prefix(
          ip: ("10.0.0.9"),
          prefix: 24
          )

      ipv4t.netmask_values["0.0.0.0/0"] = "0.0.0.0"
      ipv4t.netmask_values["10.0.0.0/8"] = "255.0.0.0"
      ipv4t.netmask_values["172.16.0.0/16"] = "255.255.0.0"
      ipv4t.netmask_values["192.168.0.0/24"] = "255.255.255.0"
      ipv4t.netmask_values["192.168.100.4/30"] = "255.255.255.252"

      ipv4t.decimal_values["0.0.0.0/0"] = BigUInt("0")!
      ipv4t.decimal_values["10.0.0.0/8"] = BigUInt("167772160")!
      ipv4t.decimal_values["172.16.0.0/16"] = BigUInt("2886729728")!
      ipv4t.decimal_values["192.168.0.0/24"] = BigUInt("3232235520")!
      ipv4t.decimal_values["192.168.100.4/30"] = BigUInt("3232261124")!


      ipv4t.broadcast["10.0.0.0/8"] = "10.255.255.255/8"
      ipv4t.broadcast["172.16.0.0/16"] = "172.16.255.255/16"
      ipv4t.broadcast["192.168.0.0/24"] = "192.168.0.255/24"
      ipv4t.broadcast["192.168.100.4/30"] = "192.168.100.7/30"

      ipv4t.networks["10.5.4.3/8"] = "10.0.0.0/8"
      ipv4t.networks["172.16.5.4/16"] = "172.16.0.0/16"
      ipv4t.networks["192.168.4.3/24"] = "192.168.4.0/24"
      ipv4t.networks["192.168.100.5/30"] = "192.168.100.4/30"


      ipv4t.classful["10.1.1.1"] = 8
      ipv4t.classful["150.1.1.1"] = 16
      ipv4t.classful["200.1.1.1"] = 24
      return ipv4t;
  }


  func test_initialize() {
    for (addr, _) in setup().valid_ipv4 {
      //console.log(i[0]);
      let ip = IPAddress.parse(addr)!;
      XCTAssertTrue(ip.is_ipv4() && ip.is_ipv6() == false);
    }
    XCTAssertEqual(32, setup().ip.prefix.ip_bits.bits);
    XCTAssertNil(IPAddress.parse("1.f.13.1/-3"));
    XCTAssertNotNil(IPAddress.parse("10.0.0.0/8"));
  }
  func test_initialize_format_error() {
    for i in setup().invalid_ipv4 {
      XCTAssertNil(IPAddress.parse(i));
    }
    XCTAssertNil(IPAddress.parse("10.0.0.0/asd"));
  }
  func test_initialize_without_prefix() {
    XCTAssertNotNil(IPAddress.parse("10.10.0.0"));
    let ip = IPAddress.parse("10.10.0.0")!;
    XCTAssertTrue(ip.is_ipv6()==false && ip.is_ipv4());
    XCTAssertEqual(32, ip.prefix.num);
  }
  func test_attributes() {
    for (arg, attr) in setup().valid_ipv4 {
      let ip = IPAddress.parse(arg)!;
      // println!("test_attributes:{}:{:?}", arg, attr);
      XCTAssertEqual(attr.ip, ip.to_s());
      XCTAssertEqual(attr.prefix, ip.prefix.num);
    }
  }
  func test_octets() {
    let ip = IPAddress.parse("10.1.2.3/8")!;
    XCTAssertEqual(ip.parts(), [10, 1, 2, 3]);
  }
  func test_method_to_string() {
    for (arg, attr) in setup().valid_ipv4 {
      let ip = IPAddress.parse(arg)!;
      XCTAssertEqual("\(attr.ip)/\(attr.prefix)", ip.to_string());
    }
  }
  func test_method_to_s() {
    for (arg, attr) in setup().valid_ipv4 {
      let ip = IPAddress.parse(arg)!;
      XCTAssertEqual(attr.ip, ip.to_s());
      // let ip_c = IPAddress.parse(arg);
      // XCTAssertEqual(attr.ip, ip.to_s());
    }
  }
  func test_netmask() {
    for (addr, mask) in setup().netmask_values {
      let ip = IPAddress.parse(addr)!;
      XCTAssertEqual(ip.netmask().to_s(), mask);
    }
  }
  func test_method_to_u32() {
    for (addr, int) in setup().decimal_values {
      let ip = IPAddress.parse(addr)!;
      XCTAssertEqual(ip.host_address, int);
    }
  }
  func test_method_is_network() {
    XCTAssertEqual(true, setup().network.is_network());
    XCTAssertEqual(false, setup().ip.is_network());
  }
  func test_one_address_network() {
    let network = IPAddress.parse("172.16.10.1/32")!;
    XCTAssertEqual(false, network.is_network());
  }
  func test_method_broadcast() {
    for (addr, bcast) in setup().broadcast {
      let ip = IPAddress.parse(addr)!;
      XCTAssertEqual(bcast, ip.broadcast().to_string());
    }
  }

  func test_method_network() {
    for (addr, net) in setup().networks {
      let ip = IPAddress.parse(addr)!;
      XCTAssertEqual(net, ip.network().to_string());
    }
  }


  func test_method_bits() {
    let ip = IPAddress.parse("127.0.0.1")!;
    XCTAssertEqual("01111111000000000000000000000001", ip.bits());
  }

  func test_method_first() {
    var ip = IPAddress.parse("192.168.100.0/24")!;
    XCTAssertEqual("192.168.100.1", ip.first().to_s());
    ip = IPAddress.parse("192.168.100.50/24")!;
    XCTAssertEqual("192.168.100.1", ip.first().to_s());
  }

  func test_method_last() {
    var ip = IPAddress.parse("192.168.100.0/24")!;
    XCTAssertEqual("192.168.100.254", ip.last().to_s());
    ip = IPAddress.parse("192.168.100.50/24")!;
    XCTAssertEqual("192.168.100.254", ip.last().to_s());
  }

  func test_method_each_host() {
    let ip = IPAddress.parse("10.0.0.1/29")!;
    var arr = [String]();
    ip.each_host({ arr.append($0.to_s()) });
    XCTAssertEqual(arr, ["10.0.0.1", "10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6"]);
  }

  func test_method_each() {
    let ip = IPAddress.parse("10.0.0.1/29")!;
    var arr = [String]();
    ip.each({ arr.append($0.to_s()) });
    XCTAssertEqual(arr, ["10.0.0.0", "10.0.0.1", "10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5",
        "10.0.0.6", "10.0.0.7"]);
  }

  func test_method_size() {
    let ip = IPAddress.parse("10.0.0.1/29")!;
    XCTAssertEqual(ip.size(), BigUInt(8));
  }

  func test_method_network_u32() {
    XCTAssertEqual("2886732288", String(setup().ip.network().host_address));
  }

  func test_method_broadcast_u32() {
    XCTAssertEqual("2886732543", String(setup().ip.broadcast().host_address));
  }

  func test_method_include() {
    var ip = IPAddress.parse("192.168.10.100/24")!;
    let addr = IPAddress.parse("192.168.10.102/24")!;
    XCTAssertEqual(true, ip.includes(addr));
    XCTAssertEqual(false, ip.includes(IPAddress.parse("172.16.0.48")!));
    ip = IPAddress.parse("10.0.0.0/8")!;
    XCTAssertEqual(true, ip.includes(IPAddress.parse("10.0.0.0/9")!));
    XCTAssertEqual(true, ip.includes(IPAddress.parse("10.1.1.1/32")!));
    XCTAssertEqual(true, ip.includes(IPAddress.parse("10.1.1.1/9")!));
    XCTAssertEqual(false,
        ip.includes(IPAddress.parse("172.16.0.0/16")!));
    XCTAssertEqual(false, ip.includes(IPAddress.parse("10.0.0.0/7")!));
    XCTAssertEqual(false, ip.includes(IPAddress.parse("5.5.5.5/32")!));
    XCTAssertEqual(false, ip.includes(IPAddress.parse("11.0.0.0/8")!));
    ip = IPAddress.parse("13.13.0.0/13")!;
    XCTAssertEqual(false,
        ip.includes(IPAddress.parse("13.16.0.0/32")!));
  }

  func test_method_include_all() {
    let ip = IPAddress.parse("192.168.10.100/24")!;
    let addr1 = IPAddress.parse("192.168.10.102/24")!;
    let addr2 = IPAddress.parse("192.168.10.103/24")!;
    XCTAssertEqual(true, ip.includes_all([addr1, addr2]));
    XCTAssertEqual(false, ip.includes_all([addr1, IPAddress.parse("13.16.0.0/32")!]));
  }

  func test_method_ipv4() {
    XCTAssertEqual(true, setup().ip.is_ipv4());
  }

  func test_method_ipv6() {
    XCTAssertEqual(false, setup().ip.is_ipv6());
  }

  func test_method_private() {
    XCTAssertEqual(true, IPAddress.parse("169.254.99.4/24")!.is_private());
    XCTAssertEqual(true, IPAddress.parse("192.168.10.50/24")!.is_private());
    XCTAssertEqual(true, IPAddress.parse("192.168.10.50/16")!.is_private());
    XCTAssertEqual(true, IPAddress.parse("172.16.77.40/24")!.is_private());
    XCTAssertEqual(true, IPAddress.parse("172.16.10.50/14")!.is_private());
    XCTAssertEqual(true, IPAddress.parse("10.10.10.10/10")!.is_private());
    XCTAssertEqual(true, IPAddress.parse("10.0.0.0/8")!.is_private());
    XCTAssertEqual(false, IPAddress.parse("192.168.10.50/12")!.is_private());
    XCTAssertEqual(false, IPAddress.parse("3.3.3.3")!.is_private());
    XCTAssertEqual(false, IPAddress.parse("10.0.0.0/7")!.is_private());
    XCTAssertEqual(false, IPAddress.parse("172.32.0.0/12")!.is_private());
    XCTAssertEqual(false, IPAddress.parse("172.16.0.0/11")!.is_private());
    XCTAssertEqual(false, IPAddress.parse("192.0.0.2/24")!.is_private());
  }

  func test_method_octet() {
    XCTAssertEqual(setup().ip.parts()[0], 172);
    XCTAssertEqual(setup().ip.parts()[1], 16);
    XCTAssertEqual(setup().ip.parts()[2], 10);
    XCTAssertEqual(setup().ip.parts()[3], 1);
  }

  func test_method_a() {
    XCTAssertEqual(true, Ipv4.is_class_a(setup().class_a));
    XCTAssertEqual(false, Ipv4.is_class_a(setup().class_b));
    XCTAssertEqual(false, Ipv4.is_class_a(setup().class_c));
  }

  func test_method_b() {
    XCTAssertEqual(true, Ipv4.is_class_b(setup().class_b));
    XCTAssertEqual(false, Ipv4.is_class_b(setup().class_a));
    XCTAssertEqual(false, Ipv4.is_class_b(setup().class_c));
  }

  func test_method_c() {
    XCTAssertEqual(true, Ipv4.is_class_c(setup().class_c));
    XCTAssertEqual(false, Ipv4.is_class_c(setup().class_a));
    XCTAssertEqual(false, Ipv4.is_class_c(setup().class_b));
  }

  func test_method_to_ipv6() {
    XCTAssertEqual("::ac10:a01", setup().ip.to_ipv6().to_s());
  }

  func test_method_reverse() {
    XCTAssertEqual(setup().ip.dns_reverse(), "10.16.172.in-addr.arpa");
  }

  func test_method_dns_rev_domains() {
    XCTAssertEqual(IPAddress.parse("173.17.5.1/23")!.dns_rev_domains(),
        ["4.17.173.in-addr.arpa", "5.17.173.in-addr.arpa"]);
    XCTAssertEqual(IPAddress.parse("173.17.1.1/15")!.dns_rev_domains(),
        ["16.173.in-addr.arpa", "17.173.in-addr.arpa"]);
    XCTAssertEqual(IPAddress.parse("173.17.1.1/7")!.dns_rev_domains(),
        ["172.in-addr.arpa", "173.in-addr.arpa"]);
    XCTAssertEqual(IPAddress.parse("173.17.1.1/29")!.dns_rev_domains(),
        [
        "0.1.17.173.in-addr.arpa",
        "1.1.17.173.in-addr.arpa",
        "2.1.17.173.in-addr.arpa",
        "3.1.17.173.in-addr.arpa",
        "4.1.17.173.in-addr.arpa",
        "5.1.17.173.in-addr.arpa",
        "6.1.17.173.in-addr.arpa",
        "7.1.17.173.in-addr.arpa"
        ]);
    XCTAssertEqual(IPAddress.parse("174.17.1.1/24")!.dns_rev_domains(),
        ["1.17.174.in-addr.arpa"]);
    XCTAssertEqual(IPAddress.parse("175.17.1.1/16")!.dns_rev_domains(),
        ["17.175.in-addr.arpa"]);
    XCTAssertEqual(IPAddress.parse("176.17.1.1/8")!.dns_rev_domains(),
        ["176.in-addr.arpa"]);
    XCTAssertEqual(IPAddress.parse("177.17.1.1/0")!.dns_rev_domains(),
        ["in-addr.arpa"]);
    XCTAssertEqual(IPAddress.parse("178.17.1.1/32")!.dns_rev_domains(),
        ["1.1.17.178.in-addr.arpa"]);
  }

  func test_method_compare() {
    var ip1 = IPAddress.parse("10.1.1.1/8")!;
    var ip2 = IPAddress.parse("10.1.1.1/16")!;
    var ip3 = IPAddress.parse("172.16.1.1/14")!;
    let ip4 = IPAddress.parse("10.1.1.1/8")!;

    // ip2 should be greater than ip1
    XCTAssertEqual(true, ip1.lt(ip2));
    XCTAssertEqual(false, ip1.gt(ip2));
    XCTAssertEqual(false, ip2.lt(ip1));
    // ip2 should be less than ip3
    XCTAssertEqual(true, ip2.lt(ip3));
    XCTAssertEqual(false, ip2.gt(ip3));
    // ip1 should be less than ip3
    XCTAssertEqual(true, ip1.lt(ip3));
    XCTAssertEqual(false, ip1.gt(ip3));
    XCTAssertEqual(false, ip3.lt(ip1));
    // ip1 should be equal to itself
    XCTAssertEqual(true, ip1.eq(ip1));
    // ip1 should be equal to ip4
    XCTAssertEqual(true, ip1.eq(ip4));
    // test sorting
    let res = [ip1, ip2, ip3].sorted(by: { $0.lt($1) })
    XCTAssertEqual(IPAddress.to_string_vec(res), ["10.1.1.1/8", "10.1.1.1/16", "172.16.1.1/14"]);
    // test same prefix
    ip1 = IPAddress.parse("10.0.0.0/24")!;
    ip2 = IPAddress.parse("10.0.0.0/16")!;
    ip3 = IPAddress.parse("10.0.0.0/8")!;

    let rres = [ip1, ip2, ip3].sorted(by: { $0.lt($1) })
    XCTAssertEqual(IPAddress.to_string_vec(rres), ["10.0.0.0/8", "10.0.0.0/16", "10.0.0.0/24"]);

  }

  func test_method_minus() {
    let ip1 = IPAddress.parse("10.1.1.1/8")!;
    let ip2 = IPAddress.parse("10.1.1.10/8")!;
    XCTAssertEqual("9", String(ip2.sub(ip1)));
    XCTAssertEqual("9", String(ip1.sub(ip2)));
  }

  func test_method_plus() {
    var ip1 = IPAddress.parse("172.16.10.1/24")!;
    var ip2 = IPAddress.parse("172.16.11.2/24")!;
    XCTAssertEqual(IPAddress.to_string_vec(ip1.add(ip2)), ["172.16.10.0/23"]);

    ip2 = IPAddress.parse("172.16.12.2/24")!;
    XCTAssertEqual(IPAddress.to_string_vec(ip1.add(ip2)),
        [ip1.network().to_string(), ip2.network().to_string()]);

    ip1 = IPAddress.parse("10.0.0.0/23")!;
    ip2 = IPAddress.parse("10.0.2.0/24")!;
    XCTAssertEqual(IPAddress.to_string_vec(ip1.add(ip2)),
        ["10.0.0.0/23", "10.0.2.0/24"]);

    ip1 = IPAddress.parse("10.0.0.0/23")!;
    ip2 = IPAddress.parse("10.0.2.0/24")!;
    XCTAssertEqual(IPAddress.to_string_vec(ip1.add(ip2)),
        ["10.0.0.0/23", "10.0.2.0/24"]);

    ip1 = IPAddress.parse("10.0.0.0/16")!;
    ip2 = IPAddress.parse("10.0.2.0/24")!;
    XCTAssertEqual(IPAddress.to_string_vec(ip1.add(ip2)), ["10.0.0.0/16"]);

    ip1 = IPAddress.parse("10.0.0.0/23")!;
    ip2 = IPAddress.parse("10.1.0.0/24")!;
    XCTAssertEqual(IPAddress.to_string_vec(ip1.add(ip2)),
        ["10.0.0.0/23", "10.1.0.0/24"]);
  }

  func test_method_netmask_equal() {
    let ip = IPAddress.parse("10.1.1.1/16")!;
    XCTAssertEqual(16, ip.prefix.num);
    let ip2 = ip.change_netmask("255.255.255.0")!;
    XCTAssertEqual(24, ip2.prefix.num);
  }

  func test_method_split() {
    XCTAssertNil(setup().ip.split(0));
    //XCTAssertNil(setup().ip.split(257));

    XCTAssertEqual(IPAddress.to_string_vec(setup().ip.split(1)), [setup().ip.network().to_string()]);

    XCTAssertEqual(IPAddress.to_string_vec(setup().network.split(8)),
        ["172.16.10.0/27",
        "172.16.10.32/27",
        "172.16.10.64/27",
        "172.16.10.96/27",
        "172.16.10.128/27",
        "172.16.10.160/27",
        "172.16.10.192/27",
        "172.16.10.224/27"]);

    XCTAssertEqual(IPAddress.to_string_vec(setup().network.split(7)),
        ["172.16.10.0/27",
        "172.16.10.32/27",
        "172.16.10.64/27",
        "172.16.10.96/27",
        "172.16.10.128/27",
        "172.16.10.160/27",
        "172.16.10.192/26"]);

    XCTAssertEqual(IPAddress.to_string_vec(setup().network.split(6)),
        ["172.16.10.0/27",
        "172.16.10.32/27",
        "172.16.10.64/27",
        "172.16.10.96/27",
        "172.16.10.128/26",
        "172.16.10.192/26"]);
    XCTAssertEqual(IPAddress.to_string_vec(setup().network.split(5)),
        ["172.16.10.0/27",
        "172.16.10.32/27",
        "172.16.10.64/27",
        "172.16.10.96/27",
        "172.16.10.128/25"]);
    XCTAssertEqual(IPAddress.to_string_vec(setup().network.split(4)),
        ["172.16.10.0/26", "172.16.10.64/26", "172.16.10.128/26", "172.16.10.192/26"]);
    XCTAssertEqual(IPAddress.to_string_vec(setup().network.split(3)),
        ["172.16.10.0/26", "172.16.10.64/26", "172.16.10.128/25"]);
    XCTAssertEqual(IPAddress.to_string_vec(setup().network.split(2)),
        ["172.16.10.0/25", "172.16.10.128/25"]);
    XCTAssertEqual(IPAddress.to_string_vec(setup().network.split(1)),
        ["172.16.10.0/24"]);
  }

  func test_method_subnet() {
    XCTAssertNil(setup().network.subnet(23));
    XCTAssertNil(setup().network.subnet(33));
    XCTAssertNotNil(setup().ip.subnet(30));
    XCTAssertEqual(IPAddress.to_string_vec(setup().network.subnet(26)),
        ["172.16.10.0/26",
        "172.16.10.64/26",
        "172.16.10.128/26",
        "172.16.10.192/26"]);
    XCTAssertEqual(IPAddress.to_string_vec(setup().network.subnet(25)),
        ["172.16.10.0/25", "172.16.10.128/25"]);
    XCTAssertEqual(IPAddress.to_string_vec(setup().network.subnet(24)),
        ["172.16.10.0/24"]);
  }

  func test_method_supernet() {
    XCTAssertNil(setup().ip.supernet(24));
    XCTAssertEqual("0.0.0.0/0", setup().ip.supernet(0)!.to_string());
    // XCTAssertEqual("0.0.0.0/0", setup().ip.supernet(-2).to_string());
    XCTAssertEqual("172.16.10.0/23", setup().ip.supernet(23)!.to_string());
    XCTAssertEqual("172.16.8.0/22", setup().ip.supernet(22)!.to_string());
  }

  func test_classmethod_parse_u32() {
    for (addr, int) in setup().decimal_values {
      let ip = Ipv4.from_int(int, 32)!;
      let splitted = addr.components(separatedBy: "/");
      let ip2 = ip.change_prefix(UInt8(splitted[1], radix: 10)!)!;
      XCTAssertEqual(ip2.to_string(), addr);
    }
  }

  func test_classmethod_summarize() {
    let s = setup();
    // Should return self if only one network given
    XCTAssertEqual(IPAddress.summarize([s.ip])!, [s.ip.network()]);

    // Summarize homogeneous networks
    var ip1 = IPAddress.parse("172.16.10.1/24")!;
    var ip2 = IPAddress.parse("172.16.11.2/24")!;
    XCTAssertEqual(IPAddress.to_string_vec(IPAddress.summarize([ip1, ip2])),
        ["172.16.10.0/23"]);

    ip1 = IPAddress.parse("10.0.0.1/24")!;
    ip2 = IPAddress.parse("10.0.1.1/24")!;
    var ip3 = IPAddress.parse("10.0.2.1/24")!;
    var ip4 = IPAddress.parse("10.0.3.1/24")!;
    XCTAssertEqual(IPAddress.to_string_vec(IPAddress.summarize([ip1, ip2, ip3, ip4])),
        ["10.0.0.0/22"]);
    ip1 = IPAddress.parse("10.0.0.1/24")!;
    ip2 = IPAddress.parse("10.0.1.1/24")!;
    ip3 = IPAddress.parse("10.0.2.1/24")!;
    ip4 = IPAddress.parse("10.0.3.1/24")!;
    XCTAssertEqual(IPAddress.to_string_vec(IPAddress.summarize([ip4, ip3, ip2, ip1])),
        ["10.0.0.0/22"]);

    // Summarize non homogeneous networks
    ip1 = IPAddress.parse("10.0.0.0/23")!;
    ip2 = IPAddress.parse("10.0.2.0/24")!;
    XCTAssertEqual(IPAddress.to_string_vec(IPAddress.summarize([ip1, ip2])),
        ["10.0.0.0/23", "10.0.2.0/24"]);

    ip1 = IPAddress.parse("10.0.0.0/16")!;
    ip2 = IPAddress.parse("10.0.2.0/24")!;
    XCTAssertEqual(IPAddress.to_string_vec(IPAddress.summarize([ip1, ip2])),
        ["10.0.0.0/16"]);

    ip1 = IPAddress.parse("10.0.0.0/23")!;
    ip2 = IPAddress.parse("10.1.0.0/24")!;
    XCTAssertEqual(IPAddress.to_string_vec(IPAddress.summarize([ip1, ip2])),
        ["10.0.0.0/23", "10.1.0.0/24"]);

    ip1 = IPAddress.parse("10.0.0.0/23")!;
    ip2 = IPAddress.parse("10.0.2.0/23")!;
    ip3 = IPAddress.parse("10.0.4.0/24")!;
    ip4 = IPAddress.parse("10.0.6.0/24")!;
    XCTAssertEqual(IPAddress.to_string_vec(IPAddress.summarize([ip1, ip2, ip3, ip4])),
        ["10.0.0.0/22", "10.0.4.0/24", "10.0.6.0/24"]);

    ip1 = IPAddress.parse("10.0.1.1/24")!;
    ip2 = IPAddress.parse("10.0.2.1/24")!;
    ip3 = IPAddress.parse("10.0.3.1/24")!;
    ip4 = IPAddress.parse("10.0.4.1/24")!;
    XCTAssertEqual(IPAddress.to_string_vec(IPAddress.summarize([ip1, ip2, ip3, ip4])),
        ["10.0.1.0/24", "10.0.2.0/23", "10.0.4.0/24"]);


    ip1 = IPAddress.parse("10.0.1.1/24")!;
    ip2 = IPAddress.parse("10.0.2.1/24")!;
    ip3 = IPAddress.parse("10.0.3.1/24")!;
    ip4 = IPAddress.parse("10.0.4.1/24")!;
    XCTAssertEqual(IPAddress.to_string_vec(IPAddress.summarize([ip4, ip3, ip2, ip1])),
        ["10.0.1.0/24", "10.0.2.0/23", "10.0.4.0/24"]);


    ip1 = IPAddress.parse("10.0.1.1/24")!;
    ip2 = IPAddress.parse("10.10.2.1/24")!;
    ip3 = IPAddress.parse("172.16.0.1/24")!;
    ip4 = IPAddress.parse("172.16.1.1/24")!;
    XCTAssertEqual(IPAddress.to_string_vec(IPAddress.summarize([ip1, ip2, ip3, ip4])),
        ["10.0.1.0/24", "10.10.2.0/24", "172.16.0.0/23"]);

    var ips = [IPAddress.parse("10.0.0.12/30")!,
        IPAddress.parse("10.0.100.0/24")!];
    XCTAssertEqual(IPAddress.to_string_vec(IPAddress.summarize(ips)),
        ["10.0.0.12/30", "10.0.100.0/24"]);

    ips = [IPAddress.parse("172.16.0.0/31")!,
        IPAddress.parse("10.10.2.1/32")!];
    XCTAssertEqual(IPAddress.to_string_vec(IPAddress.summarize(ips)),
        ["10.10.2.1/32", "172.16.0.0/31"]);

    ips = [IPAddress.parse("172.16.0.0/32")!, IPAddress.parse("10.10.2.1/32")!];
    XCTAssertEqual(IPAddress.to_string_vec(IPAddress.summarize(ips)),
        ["10.10.2.1/32", "172.16.0.0/32"]);
  }

  func test_classmethod_parse_classful() {
    for (ip, prefix) in setup().classful {
      let res = Ipv4.parse_classful(ip)!;
      XCTAssertEqual(prefix, res.prefix.num);
      XCTAssertEqual("\(ip)/\(prefix)", res.to_string());
    }
    XCTAssertNil(Ipv4.parse_classful("192.168.256.257"));
  }
}
