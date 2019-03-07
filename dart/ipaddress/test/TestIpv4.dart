import 'package:test/test.dart';

import '../IPAddress.dart';
import '../IpV4.dart';

void expectListIpAddress(List<IPAddress> ips1, List<IPAddress> ips2) {
  expect(ips1.length, ips2.length);
  for (var i = 0; i < ips1.length; i++) {
    expect(ips1[i].equal(ips2[0]), true);
  }
}

class IPv4Prefix {
  String ip;
  int prefix;
  IPv4Prefix(String ip, int prefix) {
    this.ip = ip;
    this.prefix = prefix;
  }
}

class IPv4Test {
  Map<String, IPv4Prefix> valid_ipv4 = Map<String, IPv4Prefix>();
  List<String> invalid_ipv4;
  List<String> valid_ipv4_range;
  Map<String, String> netmask_values = Map<String, String>();
  Map<String, int> decimal_values = Map<String, int>();
  IPAddress ip;
  IPAddress network;
  Map<String, String> networks = Map<String, String>();
  Map<String, String> broadcast = Map<String, String>();
  IPAddress class_a;
  IPAddress class_b;
  IPAddress class_c;
  Map<String, int> classful = Map<String, int>();

  IPv4Test(
      List<String> invalid_ipv4,
      List<String> valid_ipv4_range,
      IPAddress ip,
      IPAddress network,
      IPAddress class_a,
      IPAddress class_b,
      IPAddress class_c) {
    this.invalid_ipv4 = invalid_ipv4;
    this.valid_ipv4_range = valid_ipv4_range;
    this.ip = ip;
    this.network = network;
    this.class_a = class_a;
    this.class_b = class_b;
    this.class_c = class_c;
  }
}

IPv4Test setup() {
  final ipv4t = IPv4Test(
      ["10.0.0.256", "10.0.0.0.0"],
      ["10.0.0.1-254", "10.0.1-254.0", "10.1-254.0.0"],
      IpV4.create("172.16.10.1/24").unwrap(),
      IpV4.create("172.16.10.0/24").unwrap(),
      IpV4.create("10.0.0.1/8").unwrap(),
      IpV4.create("172.16.0.1/16").unwrap(),
      IpV4.create("192.168.0.1/24").unwrap());
  ipv4t.valid_ipv4["9.9/17"] = IPv4Prefix("9.0.0.9", 17);
  ipv4t.valid_ipv4["100.1.100"] = IPv4Prefix("100.1.0.100", 32);
  ipv4t.valid_ipv4["0.0.0.0/0"] = IPv4Prefix("0.0.0.0", 0);
  ipv4t.valid_ipv4["10.0.0.0"] = IPv4Prefix("10.0.0.0", 32);
  ipv4t.valid_ipv4["10.0.0.1"] = IPv4Prefix("10.0.0.1", 32);
  ipv4t.valid_ipv4["10.0.0.1/24"] = IPv4Prefix("10.0.0.1", 24);
  ipv4t.valid_ipv4["10.0.0.9/255.255.255.0"] = IPv4Prefix("10.0.0.9", 24);

  ipv4t.netmask_values["0.0.0.0/0"] = "0.0.0.0";
  ipv4t.netmask_values["10.0.0.0/8"] = "255.0.0.0";
  ipv4t.netmask_values["172.16.0.0/16"] = "255.255.0.0";
  ipv4t.netmask_values["192.168.0.0/24"] = "255.255.255.0";
  ipv4t.netmask_values["192.168.100.4/30"] = "255.255.255.252";

  ipv4t.decimal_values["0.0.0.0/0"] = 0;
  ipv4t.decimal_values["10.0.0.0/8"] = 167772160;
  ipv4t.decimal_values["172.16.0.0/16"] = 2886729728;
  ipv4t.decimal_values["192.168.0.0/24"] = 3232235520;
  ipv4t.decimal_values["192.168.100.4/30"] = 3232261124;

  ipv4t.ip = IPAddress.parse("172.16.10.1/24").unwrap();
  ipv4t.network = IPAddress.parse("172.16.10.0/24").unwrap();

  ipv4t.broadcast["10.0.0.0/8"] = "10.255.255.255/8";
  ipv4t.broadcast["172.16.0.0/16"] = "172.16.255.255/16";
  ipv4t.broadcast["192.168.0.0/24"] = "192.168.0.255/24";
  ipv4t.broadcast["192.168.100.4/30"] = "192.168.100.7/30";

  ipv4t.networks["10.5.4.3/8"] = "10.0.0.0/8";
  ipv4t.networks["172.16.5.4/16"] = "172.16.0.0/16";
  ipv4t.networks["192.168.4.3/24"] = "192.168.4.0/24";
  ipv4t.networks["192.168.100.5/30"] = "192.168.100.4/30";

  ipv4t.class_a = IPAddress.parse("10.0.0.1/8").unwrap();
  ipv4t.class_b = IPAddress.parse("172.16.0.1/16").unwrap();
  ipv4t.class_c = IPAddress.parse("192.168.0.1/24").unwrap();

  ipv4t.classful["10.1.1.1"] = 8;
  ipv4t.classful["150.1.1.1"] = 16;
  ipv4t.classful["200.1.1.1"] = 24;
  return ipv4t;
}

void main() {
  test("test_initialize", () {
    final _setup = setup();
    _setup.valid_ipv4.forEach((i, x) {
      final ip = IPAddress.parse(i).unwrap();
      expect(true, ip.is_ipv4() && !ip.is_ipv6());
    });
    expect(32, _setup.ip.prefix.ip_bits.bits);
    expect(true, IPAddress.parse("1.f.13.1/-3").isErr());
    expect(true, IPAddress.parse("10.0.0.0/8").isOk());
  });

  test("test_initialize_format_error", () {
    setup()
        .invalid_ipv4
        .forEach((i) => expect(true, IPAddress.parse(i).isErr()));
    expect(true, IPAddress.parse("10.0.0.0/asd").isErr());
  });

  test("test_initialize_without_prefix", () {
    expect(true, IPAddress.parse("10.10.0.0").isOk());
    final ip = IPAddress.parse("10.10.0.0").unwrap();
    expect(true, !ip.is_ipv6() && ip.is_ipv4());
    expect(32, ip.prefix.num);
  });

  test("test_attributes", () {
    setup().valid_ipv4.forEach((arg, attr) {
      final ip = IPAddress.parse(arg).unwrap();
      // println!("test_attributes:{}:{:?}", arg, attr);
      expect(attr.ip, ip.to_s());
      expect(attr.prefix, ip.prefix.num);
    });
  });

  test("test_octets", () {
    final ip = IPAddress.parse("10.1.2.3/8").unwrap();
    expect(ip.parts(), [10, 1, 2, 3]);
  });

  test("test_method_to_string", () {
    setup().valid_ipv4.forEach((arg, addr) {
      final ip = IPAddress.parse(arg).unwrap();
      expect("${addr.ip}/${addr.prefix}", ip.to_string());
    });
  });

  test("test_method_to_s", () {
    setup().valid_ipv4.forEach((arg, attr) {
      final ip = IPAddress.parse(arg).unwrap();
      expect(attr.ip, ip.to_s());
      // final ip_c = IPAddress.parse(arg).unwrap();
      // expect(attr.ip, ip.to_s());
    });
  });

  test("test_netmask", () {
    setup().netmask_values.forEach((addr, mask) {
      final ip = IPAddress.parse(addr);
      print(
          "test_netmask:${ip.unwrap().to_s()}:${ip.unwrap().netmask()}:${ip.unwrap().netmask()}");
      expect(ip.unwrap().netmask().to_s(), mask);
    });
  });

  test("test_method_to_u32", () {
    setup().decimal_values.forEach((addr, value) {
      final ip = IPAddress.parse(addr).unwrap();
      expect(ip.host_address.toInt(), value);
    });
  });

  test("test_method_is_network", () {
    expect(true, setup().network.is_network());
    expect(false, setup().ip.is_network());
  });

  test("test_one_address_network", () {
    final network = IPAddress.parse("172.16.10.1/32").unwrap();
    expect(false, network.is_network());
  });

  test("test_method_broadcast", () {
    setup().broadcast.forEach((addr, bcast) {
      final ip = IPAddress.parse(addr).unwrap();
      expect(bcast, ip.broadcast().to_string());
    });
  });

  test("test_method_network", () {
    setup().networks.forEach((addr, net) {
      final ip = IPAddress.parse(addr).unwrap();
      expect(net, ip.network().to_string());
    });
  });

  test("test_method_bits", () {
    final ip = IPAddress.parse("127.0.0.1").unwrap();
    expect("01111111000000000000000000000001", ip.bits());
  });

  test("test_method_first", () {
    var ip = IPAddress.parse("192.168.100.0/24").unwrap();
    expect("192.168.100.1", ip.first().to_s());
    ip = IPAddress.parse("192.168.100.50/24").unwrap();
    expect("192.168.100.1", ip.first().to_s());
  });

  test("test_method_last", () {
    var ip = IPAddress.parse("192.168.100.0/24").unwrap();
    expect("192.168.100.254", ip.last().to_s());
    ip = IPAddress.parse("192.168.100.50/24").unwrap();
    expect("192.168.100.254", ip.last().to_s());
  });

  test("test_method_each_host", () {
    final ip = IPAddress.parse("10.0.0.1/29").unwrap();
    final arr = List<String>();
    ip.each_host((i) => arr.add(i.to_s()));
    expect(arr, [
      "10.0.0.1",
      "10.0.0.2",
      "10.0.0.3",
      "10.0.0.4",
      "10.0.0.5",
      "10.0.0.6"
    ]);
  });

  test("test_method_each", () {
    final ip = IPAddress.parse("10.0.0.1/29").unwrap();
    final arr = List<String>();
    ip.each((i) => arr.add(i.to_s()));
    expect(arr, [
      "10.0.0.0",
      "10.0.0.1",
      "10.0.0.2",
      "10.0.0.3",
      "10.0.0.4",
      "10.0.0.5",
      "10.0.0.6",
      "10.0.0.7"
    ]);
  });

  test("test_method_size", () {
    final ip = IPAddress.parse("10.0.0.1/29").unwrap();
    expect(ip.size(), BigInt.from((8)));
  });

  test("test_method_network_u32", () {
    expect(2886732288, setup().ip.network().host_address.toInt());
  });

  test("test_method_broadcast_u32", () {
    expect(2886732543, setup().ip.broadcast().host_address.toInt());
  });

  test("test_method_include", () {
    var ip = IPAddress.parse("192.168.10.100/24").unwrap();
    final addr = IPAddress.parse("192.168.10.102/24").unwrap();
    expect(true, ip.includes(addr));
    expect(false, ip.includes(IPAddress.parse("172.16.0.48").unwrap()));
    ip = IPAddress.parse("10.0.0.0/8").unwrap();
    expect(true, ip.includes(IPAddress.parse("10.0.0.0/9").unwrap()));
    expect(true, ip.includes(IPAddress.parse("10.1.1.1/32").unwrap()));
    expect(true, ip.includes(IPAddress.parse("10.1.1.1/9").unwrap()));
    expect(false, ip.includes(IPAddress.parse("172.16.0.0/16").unwrap()));
    expect(false, ip.includes(IPAddress.parse("10.0.0.0/7").unwrap()));
    expect(false, ip.includes(IPAddress.parse("5.5.5.5/32").unwrap()));
    expect(false, ip.includes(IPAddress.parse("11.0.0.0/8").unwrap()));
    ip = IPAddress.parse("13.13.0.0/13").unwrap();
    expect(false, ip.includes(IPAddress.parse("13.16.0.0/32").unwrap()));
  });

  test("test_method_include_all", () {
    final ip = IPAddress.parse("192.168.10.100/24").unwrap();
    final addr1 = IPAddress.parse("192.168.10.102/24").unwrap();
    final addr2 = IPAddress.parse("192.168.10.103/24").unwrap();
    expect(true, ip.includes_all([addr1, addr2]));
    expect(false,
        ip.includes_all([addr1, IPAddress.parse("13.16.0.0/32").unwrap()]));
  });

  test("test_method_ipv4", () {
    expect(true, setup().ip.is_ipv4());
  });

  test("test_method_ipv6", () {
    expect(false, setup().ip.is_ipv6());
  });

  test("test_method_private", () {
    expect(true, IPAddress.parse("169.254.10.50/24").unwrap().is_private());
    expect(true, IPAddress.parse("192.168.10.50/24").unwrap().is_private());
    expect(true, IPAddress.parse("192.168.10.50/16").unwrap().is_private());
    expect(true, IPAddress.parse("172.16.77.40/24").unwrap().is_private());
    expect(true, IPAddress.parse("172.16.10.50/14").unwrap().is_private());
    expect(true, IPAddress.parse("10.10.10.10/10").unwrap().is_private());
    expect(true, IPAddress.parse("10.0.0.0/8").unwrap().is_private());
    expect(false, IPAddress.parse("192.168.10.50/12").unwrap().is_private());
    expect(false, IPAddress.parse("3.3.3.3").unwrap().is_private());
    expect(false, IPAddress.parse("10.0.0.0/7").unwrap().is_private());
    expect(false, IPAddress.parse("172.32.0.0/12").unwrap().is_private());
    expect(false, IPAddress.parse("172.16.0.0/11").unwrap().is_private());
    expect(false, IPAddress.parse("192.0.0.2/24").unwrap().is_private());
  });

  test("test_method_octet", () {
    expect(setup().ip.parts()[0], 172);
    expect(setup().ip.parts()[1], 16);
    expect(setup().ip.parts()[2], 10);
    expect(setup().ip.parts()[3], 1);
  });

  test("test_method_a", () {
    expect(true, IpV4.is_class_a(setup().class_a));
    expect(false, IpV4.is_class_a(setup().class_b));
    expect(false, IpV4.is_class_a(setup().class_c));
  });

  test("test_method_b", () {
    expect(true, IpV4.is_class_b(setup().class_b));
    expect(false, IpV4.is_class_b(setup().class_a));
    expect(false, IpV4.is_class_b(setup().class_c));
  });

  test("test_method_c", () {
    expect(true, IpV4.is_class_c(setup().class_c));
    expect(false, IpV4.is_class_c(setup().class_a));
    expect(false, IpV4.is_class_c(setup().class_b));
  });

  test("test_method_to_ipv6", () {
    expect("::ac10:a01", setup().ip.to_ipv6().to_s());
  });

  test("test_method_reverse", () {
    expect(setup().ip.dns_reverse(), "10.16.172.in-addr.arpa");
  });

  test("test_method_dns_rev_domains", () {
    expect(IPAddress.parse("173.17.5.1/23").unwrap().dns_rev_domains(),
        ["4.17.173.in-addr.arpa", "5.17.173.in-addr.arpa"]);
    expect(IPAddress.parse("173.17.1.1/15").unwrap().dns_rev_domains(),
        ["16.173.in-addr.arpa", "17.173.in-addr.arpa"]);
    expect(IPAddress.parse("173.17.1.1/7").unwrap().dns_rev_domains(),
        ["172.in-addr.arpa", "173.in-addr.arpa"]);
    expect(IPAddress.parse("173.17.1.1/29").unwrap().dns_rev_domains(), [
      "0.1.17.173.in-addr.arpa",
      "1.1.17.173.in-addr.arpa",
      "2.1.17.173.in-addr.arpa",
      "3.1.17.173.in-addr.arpa",
      "4.1.17.173.in-addr.arpa",
      "5.1.17.173.in-addr.arpa",
      "6.1.17.173.in-addr.arpa",
      "7.1.17.173.in-addr.arpa"
    ]);
    expect(IPAddress.parse("174.17.1.1/24").unwrap().dns_rev_domains(),
        ["1.17.174.in-addr.arpa"]);
    expect(IPAddress.parse("175.17.1.1/16").unwrap().dns_rev_domains(),
        ["17.175.in-addr.arpa"]);
    expect(IPAddress.parse("176.17.1.1/8").unwrap().dns_rev_domains(),
        ["176.in-addr.arpa"]);
    expect(IPAddress.parse("177.17.1.1/0").unwrap().dns_rev_domains(),
        ["in-addr.arpa"]);
    expect(IPAddress.parse("178.17.1.1/32").unwrap().dns_rev_domains(),
        ["1.1.17.178.in-addr.arpa"]);
  });

  test("test_method_compare", () {
    var ip1 = IPAddress.parse("10.1.1.1/8").unwrap();
    var ip2 = IPAddress.parse("10.1.1.1/16").unwrap();
    var ip3 = IPAddress.parse("172.16.1.1/14").unwrap();
    final ip4 = IPAddress.parse("10.1.1.1/8").unwrap();

    // ip2 should be greater than ip1
    expect(true, ip1.lt(ip2));
    expect(false, ip1.gt(ip2));
    expect(false, ip2.lt(ip1));
    // ip2 should be less than ip3
    expect(true, ip2.lt(ip3));
    expect(false, ip2.gt(ip3));
    // ip1 should be less than ip3
    expect(true, ip1.lt(ip3));
    expect(false, ip1.gt(ip3));
    expect(false, ip3.lt(ip1));
    // ip1 should be equal to itself
    expect(true, ip1.equal(ip1));
    // ip1 should be equal to ip4
    expect(true, ip1.equal(ip4));
    // test sorting
    var res = IPAddress.sort([ip1, ip2, ip3]);
    expect(IPAddress.to_string_vec(res),
        ["10.1.1.1/8", "10.1.1.1/16", "172.16.1.1/14"]);
    // test same prefix
    ip1 = IPAddress.parse("10.0.0.0/24").unwrap();
    ip2 = IPAddress.parse("10.0.0.0/16").unwrap();
    ip3 = IPAddress.parse("10.0.0.0/8").unwrap();
    {
      res = IPAddress.sort([ip1, ip2, ip3]);
      expect(IPAddress.to_string_vec(res),
          ["10.0.0.0/8", "10.0.0.0/16", "10.0.0.0/24"]);
    }
  });

  test("test_method_minus", () {
    final ip1 = IPAddress.parse("10.1.1.1/8").unwrap();
    final ip2 = IPAddress.parse("10.1.1.10/8").unwrap();
    expect(9, ip2.sub(ip1).toInt());
    expect(9, ip1.sub(ip2).toInt());
  });

  test("test_method_plus", () {
    var ip1 = IPAddress.parse("172.16.10.1/24").unwrap();
    var ip2 = IPAddress.parse("172.16.11.2/24").unwrap();
    expect(IPAddress.to_string_vec(ip1.add(ip2)), ["172.16.10.0/23"]);

    ip2 = IPAddress.parse("172.16.12.2/24").unwrap();
    expect(IPAddress.to_string_vec(ip1.add(ip2)),
        [ip1.network().to_string(), ip2.network().to_string()]);

    ip1 = IPAddress.parse("10.0.0.0/23").unwrap();
    ip2 = IPAddress.parse("10.0.2.0/24").unwrap();
    expect(
        IPAddress.to_string_vec(ip1.add(ip2)), ["10.0.0.0/23", "10.0.2.0/24"]);

    ip1 = IPAddress.parse("10.0.0.0/23").unwrap();
    ip2 = IPAddress.parse("10.0.2.0/24").unwrap();
    expect(
        IPAddress.to_string_vec(ip1.add(ip2)), ["10.0.0.0/23", "10.0.2.0/24"]);

    ip1 = IPAddress.parse("10.0.0.0/16").unwrap();
    ip2 = IPAddress.parse("10.0.2.0/24").unwrap();
    expect(IPAddress.to_string_vec(ip1.add(ip2)), ["10.0.0.0/16"]);

    ip1 = IPAddress.parse("10.0.0.0/23").unwrap();
    ip2 = IPAddress.parse("10.1.0.0/24").unwrap();
    expect(
        IPAddress.to_string_vec(ip1.add(ip2)), ["10.0.0.0/23", "10.1.0.0/24"]);
  });

  test("test_method_netmask_equal", () {
    final ip = IPAddress.parse("10.1.1.1/16").unwrap();
    expect(16, ip.prefix.num);
    final ip2 = ip.change_netmask("255.255.255.0").unwrap();
    expect(24, ip2.prefix.num);
  });

  test("test_method_split", () {
    expect(true, setup().ip.split(0).isErr());
    expect(true, setup().ip.split(257).isErr());

    expectListIpAddress(setup().ip.split(1).unwrap(), [setup().ip.network()]);

    expect(IPAddress.to_string_vec(setup().network.split(8).unwrap()), [
      "172.16.10.0/27",
      "172.16.10.32/27",
      "172.16.10.64/27",
      "172.16.10.96/27",
      "172.16.10.128/27",
      "172.16.10.160/27",
      "172.16.10.192/27",
      "172.16.10.224/27"
    ]);

    expect(IPAddress.to_string_vec(setup().network.split(7).unwrap()), [
      "172.16.10.0/27",
      "172.16.10.32/27",
      "172.16.10.64/27",
      "172.16.10.96/27",
      "172.16.10.128/27",
      "172.16.10.160/27",
      "172.16.10.192/26"
    ]);

    expect(IPAddress.to_string_vec(setup().network.split(6).unwrap()), [
      "172.16.10.0/27",
      "172.16.10.32/27",
      "172.16.10.64/27",
      "172.16.10.96/27",
      "172.16.10.128/26",
      "172.16.10.192/26"
    ]);
    expect(IPAddress.to_string_vec(setup().network.split(5).unwrap()), [
      "172.16.10.0/27",
      "172.16.10.32/27",
      "172.16.10.64/27",
      "172.16.10.96/27",
      "172.16.10.128/25"
    ]);
    expect(IPAddress.to_string_vec(setup().network.split(4).unwrap()), [
      "172.16.10.0/26",
      "172.16.10.64/26",
      "172.16.10.128/26",
      "172.16.10.192/26"
    ]);
    expect(IPAddress.to_string_vec(setup().network.split(3).unwrap()),
        ["172.16.10.0/26", "172.16.10.64/26", "172.16.10.128/25"]);
    expect(IPAddress.to_string_vec(setup().network.split(2).unwrap()),
        ["172.16.10.0/25", "172.16.10.128/25"]);
    expect(IPAddress.to_string_vec(setup().network.split(1).unwrap()),
        ["172.16.10.0/24"]);
  });

  test("test_method_subnet", () {
    expect(true, setup().network.subnet(23).isErr());
    expect(true, setup().network.subnet(33).isErr());
    expect(true, setup().ip.subnet(30).isOk());
    expect(IPAddress.to_string_vec(setup().network.subnet(26).unwrap()), [
      "172.16.10.0/26",
      "172.16.10.64/26",
      "172.16.10.128/26",
      "172.16.10.192/26"
    ]);
    expect(IPAddress.to_string_vec(setup().network.subnet(25).unwrap()),
        ["172.16.10.0/25", "172.16.10.128/25"]);
    expect(IPAddress.to_string_vec(setup().network.subnet(24).unwrap()),
        ["172.16.10.0/24"]);
  });

  test("test_method_supernet", () {
    expect(true, setup().ip.supernet(24).isErr());
    expect("0.0.0.0/0", setup().ip.supernet(0).unwrap().to_string());
    // expect("0.0.0.0/0", setup().ip.supernet(-2).unwrap().to_string());
    expect("172.16.10.0/23", setup().ip.supernet(23).unwrap().to_string());
    expect("172.16.8.0/22", setup().ip.supernet(22).unwrap().to_string());
  });

  test("test_classmethod_parse_u32", () {
    setup().decimal_values.forEach((addr, value) {
      final ip = IpV4.from_u32(value.toInt(), 32).unwrap();
      final splitted = addr.split("/");
      final ip2 = ip.change_prefix_int(int.parse(splitted[1])).unwrap();
      expect(ip2.to_string(), addr);
    });
  });

  // test_classhmethod_extract() {
  //   final str = "foobar172.16.10.1barbaz";
  //   expect("172.16.10.1", IPAddress.extract(str).to_s
  // }

  test("test_classmethod_summarize", () {
    // Should return self if only one network given
    expectListIpAddress(
        IPAddress.summarize([setup().ip]), [setup().ip.network()]);

    // Summarize homogeneous networks
    var ip1 = IPAddress.parse("172.16.10.1/24").unwrap();
    var ip2 = IPAddress.parse("172.16.11.2/24").unwrap();
    expect(IPAddress.to_string_vec(IPAddress.summarize([ip1, ip2])),
        ["172.16.10.0/23"]);

    ip1 = IPAddress.parse("10.0.0.1/24").unwrap();
    ip2 = IPAddress.parse("10.0.1.1/24").unwrap();
    var ip3 = IPAddress.parse("10.0.2.1/24").unwrap();
    var ip4 = IPAddress.parse("10.0.3.1/24").unwrap();
    expect(IPAddress.to_string_vec(IPAddress.summarize([ip1, ip2, ip3, ip4])),
        ["10.0.0.0/22"]);

    ip1 = IPAddress.parse("10.0.0.1/24").unwrap();
    ip2 = IPAddress.parse("10.0.1.1/24").unwrap();
    ip3 = IPAddress.parse("10.0.2.1/24").unwrap();
    ip4 = IPAddress.parse("10.0.3.1/24").unwrap();
    expect(IPAddress.to_string_vec(IPAddress.summarize([ip4, ip3, ip2, ip1])),
        ["10.0.0.0/22"]);

    // Summarize non homogeneous networks
    ip1 = IPAddress.parse("10.0.0.0/23").unwrap();
    ip2 = IPAddress.parse("10.0.2.0/24").unwrap();
    expect(IPAddress.to_string_vec(IPAddress.summarize([ip1, ip2])),
        ["10.0.0.0/23", "10.0.2.0/24"]);

    ip1 = IPAddress.parse("10.0.0.0/16").unwrap();
    ip2 = IPAddress.parse("10.0.2.0/24").unwrap();
    expect(IPAddress.to_string_vec(IPAddress.summarize([ip1, ip2])),
        ["10.0.0.0/16"]);

    ip1 = IPAddress.parse("10.0.0.0/23").unwrap();
    ip2 = IPAddress.parse("10.1.0.0/24").unwrap();
    expect(IPAddress.to_string_vec(IPAddress.summarize([ip1, ip2])),
        ["10.0.0.0/23", "10.1.0.0/24"]);

    ip1 = IPAddress.parse("10.0.0.0/23").unwrap();
    ip2 = IPAddress.parse("10.0.2.0/23").unwrap();
    ip3 = IPAddress.parse("10.0.4.0/24").unwrap();
    ip4 = IPAddress.parse("10.0.6.0/24").unwrap();
    expect(IPAddress.to_string_vec(IPAddress.summarize([ip1, ip2, ip3, ip4])),
        ["10.0.0.0/22", "10.0.4.0/24", "10.0.6.0/24"]);

    ip1 = IPAddress.parse("10.0.1.1/24").unwrap();
    ip2 = IPAddress.parse("10.0.2.1/24").unwrap();
    ip3 = IPAddress.parse("10.0.3.1/24").unwrap();
    ip4 = IPAddress.parse("10.0.4.1/24").unwrap();
    expect(IPAddress.to_string_vec(IPAddress.summarize([ip1, ip2, ip3, ip4])),
        ["10.0.1.0/24", "10.0.2.0/23", "10.0.4.0/24"]);

    ip1 = IPAddress.parse("10.0.1.1/24").unwrap();
    ip2 = IPAddress.parse("10.0.2.1/24").unwrap();
    ip3 = IPAddress.parse("10.0.3.1/24").unwrap();
    ip4 = IPAddress.parse("10.0.4.1/24").unwrap();
    expect(IPAddress.to_string_vec(IPAddress.summarize([ip4, ip3, ip2, ip1])),
        ["10.0.1.0/24", "10.0.2.0/23", "10.0.4.0/24"]);

    ip1 = IPAddress.parse("10.0.1.1/24").unwrap();
    ip2 = IPAddress.parse("10.10.2.1/24").unwrap();
    ip3 = IPAddress.parse("172.16.0.1/24").unwrap();
    ip4 = IPAddress.parse("172.16.1.1/24").unwrap();
    expect(IPAddress.to_string_vec(IPAddress.summarize([ip1, ip2, ip3, ip4])),
        ["10.0.1.0/24", "10.10.2.0/24", "172.16.0.0/23"]);

    var ips = [
      IPAddress.parse("10.0.0.12/30").unwrap(),
      IPAddress.parse("10.0.100.0/24").unwrap()
    ];
    expect(IPAddress.to_string_vec(IPAddress.summarize(ips)),
        ["10.0.0.12/30", "10.0.100.0/24"]);

    ips = [
      IPAddress.parse("172.16.0.0/31").unwrap(),
      IPAddress.parse("10.10.2.1/32").unwrap()
    ];
    expect(IPAddress.to_string_vec(IPAddress.summarize(ips)),
        ["10.10.2.1/32", "172.16.0.0/31"]);

    ips = [
      IPAddress.parse("172.16.0.0/32").unwrap(),
      IPAddress.parse("10.10.2.1/32").unwrap()
    ];
    expect(IPAddress.to_string_vec(IPAddress.summarize(ips)),
        ["10.10.2.1/32", "172.16.0.0/32"]);
  });

  test("test_classmethod_parse_classful", () {
    setup().classful.forEach((ip, prefix) {
      final res = IpV4.parse_classful(ip).unwrap();
      expect(prefix, res.prefix.num);
      expect("${ip}/${prefix}", res.to_string());
    });
    expect(true, IpV4.parse_classful("192.168.256.257").isErr());
  });
}
