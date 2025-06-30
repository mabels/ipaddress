import 'dart:math';

import 'package:result_monad/result_monad.dart';

import 'IpV4.dart';
import 'IpV6.dart';
import 'IpVersion.dart';
import 'IpBits.dart';
import 'Ipv6Mapped.dart';
import 'Prefix.dart';

typedef bool VtBool(IPAddress ipa);
typedef IPAddress VtIPAddress(IPAddress ipa);
typedef void Each(IPAddress ipa);

class AddrNetmask {
  final String addr;
  final String? netmask;
  AddrNetmask(this.addr, this.netmask);
}

class SplitOnColon {
  final BigInt ip;
  final int size;
  SplitOnColon(this.ip, this.size);
}

String dumpStack(List<IPAddress> args) {
  return args.map((ip) => ip.to_string()).join('][');
}

class IPAddress {
  static final RE_MAPPED = RegExp(":.+\\.");
  static final RE_IPV4 = RegExp("\\.");
  static final RE_IPV6 = RegExp(":");

  final IpBits ip_bits;
  final BigInt host_address;
  final Prefix prefix;
  final IPAddress? mapped;
  final VtBool vt_is_private;
  final VtBool vt_is_loopback;
  final VtIPAddress vt_to_ipv6;

  static List<IPAddress> sort(List<IPAddress> ipas) {
    final ret = List<IPAddress>.from(ipas);
    ret.sort((a, b) => a.compare(b));
    return ret;
  }

  /// Parse the argument string to create a new
  /// IPv4, IPv6 or Mapped IP object
  ///
  ///   ip  = IPAddress.parse "172.16.10.1/24"
  ///  ip6 = IPAddress.parse "2001:db8::8:800:200c:417a/64"
  ///  ip_mapped = IPAddress.parse "::ffff:172.16.10.1/128"
  ///
  /// All the object created will be instances of the
  /// correct class:
  ///
  ///  ip.class
  ///   //=> IPAddress::IPv4
  /// ip6.class
  ///   //=> IPAddress::IPv6
  /// ip_mapped.class
  ///   //=> IPAddress::IPv6::Mapped
  ///
  static Result<IPAddress, String> parse(String str) {
    if (IPAddress.RE_MAPPED.hasMatch(str)) {
      // println!("mapped:{}", &str);
      return Ipv6Mapped.create(str);
    } else {
      if (IPAddress.RE_IPV4.hasMatch(str)) {
        // println!("ipv4:{}", &str);
        return IpV4.create(str);
      } else if (IPAddress.RE_IPV6.hasMatch(str)) {
        // println!("ipv6:{}", &str);
        return IpV6.create(str);
      }
    }
    return Result.error("Unknown IP Address ${str}");
  }

  static int? parseInt(String s, int radix) {
    return int.tryParse(s, radix: radix);
  }

  static AddrNetmask split_at_slash(String str) {
    final slash = str.trim().split("/");
    var addr = "";
    if (slash.length >= 1) {
      addr = slash.first.trim();
    }
    if (slash.length >= 2) {
      return AddrNetmask(addr, slash[1].trim());
    } else {
      return AddrNetmask(addr, null);
    }
  }

  /// Checks if the given string is a valid IPv4 address
  ///
  /// Example:
  ///
  ///   IPAddress::valid_ipv4? "2002::1"
  ///     //=> false
  ///
  ///   IPAddress::valid_ipv4? "172.16.10.1"
  ///     //=> true
  ///
  static Result<int, String> parse_ipv4_part(String i, String addr) {
    final part = i;
    if (int.tryParse(part) == null) {
      return Result.error("IP must contain numbers ${addr}");
    }
    if (int.parse(part) >= 256) {
      return Result.error("IP items has to lower than 256. ${addr}");
    }
    return Result.ok(int.parse(part));
  }

  static Result<int, String> split_to_u32(String addr) {
    var ip = 0;
    var shift = 24;
    var split_addr = addr.split("."); //.collect::<Vec<&str}();
    if (split_addr.length > 4) {
      return Result.error("IP has not the right format:${addr}");
    }
    final split_addr_len = split_addr.length;
    if (split_addr_len < 4) {
      final part =
          IPAddress.parse_ipv4_part(split_addr[split_addr_len - 1], addr);
      if (part.isFailure) {
        return Result.error(part.error);
      }
      ip = part.value;
      split_addr = split_addr.sublist(0, split_addr_len - 1);
    }
    for (var i in split_addr) {
      final part = IPAddress.parse_ipv4_part(i, addr);
      if (part.isFailure) {
        return Result.error(part.error);
      }
      // println!("{}-{}", part_num, shift);
      ip = ip | (part.value.toInt() << shift);
      shift -= 8;
    }
    return Result.ok(ip);
  }

  static bool is_valid_ipv4(String addr) {
    return IPAddress.split_to_u32(addr).isSuccess;
  }

  IPAddress(this.ip_bits, this.host_address, this.prefix, this.mapped,
      this.vt_is_private, this.vt_is_loopback, this.vt_to_ipv6);

  IPAddress clone() {
    if (this.mapped == null) {
      return this.setMappedIpaddress(null);
    } else {
      return this.setMappedIpaddress(this.mapped?.clone());
    }
  }

  IPAddress from(BigInt addr, Prefix prefix) {
    IPAddress? map = null;
    if (this.mapped != null) {
      map = this.mapped?.clone();
    }
    return setMapped(addr, map, prefix.clone());
  }

  IPAddress setMappedIpaddress(IPAddress? mapped) {
    return setMapped(this.host_address, mapped, this.prefix.clone());
  }

  IPAddress setMapped(BigInt hostAddr, IPAddress? mapped, Prefix prefix) {
    return IPAddress(this.ip_bits, hostAddr, prefix, mapped, this.vt_is_private,
        this.vt_is_loopback, this.vt_to_ipv6);
  }

  bool equals(Object oth) {
    return compare(oth as IPAddress) == 0;
  }

  int compare(IPAddress oth) {
    if (this.ip_bits.version != oth.ip_bits.version) {
      if (this.ip_bits.version == IpVersion.V6) {
        return 1;
      }
      return -1;
    }
    //let adr_diff = this.host_address - oth.host_address;
    final comp = this.host_address.compareTo(oth.host_address);
    if (comp < 0) {
      return -1;
    } else if (comp > 0) {
      return 1;
    }
    return this.prefix.compare(oth.prefix);
  }

  bool equal(IPAddress other) {
    return this.ip_bits.version == other.ip_bits.version &&
        this.prefix.equal(other.prefix) &&
        this.host_address == other.host_address &&
        ((this.mapped == null && this.mapped == other.mapped) ||
            this.mapped!.equal(other.mapped!));
  }

  bool lt(IPAddress ipa) {
    return this.compare(ipa) < 0;
  }

  bool gt(IPAddress ipa) {
    return this.compare(ipa) > 0;
  }

  /// True if the object is an IPv4 address
  ///
  ///   ip = IPAddress("192.168.10.100/24")
  ///
  ///   ip.ipv4?
  ///     //-> true
  ///
  bool is_ipv4() {
    return this.ip_bits.version == IpVersion.V4;
  }

  /// True if the object is an IPv6 address
  ///
  ///   ip = IPAddress("192.168.10.100/24")
  ///
  ///   ip.ipv6?
  ///     //-> false
  ///
  bool is_ipv6() {
    return this.ip_bits.version == IpVersion.V6;
  }

  /// Checks if the given string is a valid IP address,
  /// either IPv4 or IPv6
  ///
  /// Example:
  ///
  ///  IPAddress::valid? "2002::1"
  ///    //=> true
  ///
  ///  IPAddress::valid? "10.0.0.256"
  ///    //=> false
  ///
  static bool is_valid(String addr) {
    return IPAddress.is_valid_ipv4(addr) || IPAddress.is_valid_ipv6(addr);
  }

  /// Checks if the given string is a valid IPv6 address
  ///
  /// Example:
  ///
  ///   IPAddress::valid_ipv6? "2002::1"
  ///     //=> true
  ///
  ///   IPAddress::valid_ipv6? "2002::DEAD::BEEF"
  ///     // => false
  ///
  static Result<SplitOnColon, String> split_on_colon(String addr) {
    final parts = addr.trim().split(":");
    var ip = BigInt.zero;
    if (parts.length == 1 && parts.first.isEmpty) {
      return Result.ok(SplitOnColon(ip, 0));
    }
    final parts_len = parts.length;
    var shift = ((parts_len - 1) * 16);
    for (var i in parts) {
      //println!("{}={}", addr, i);
      final part = IPAddress.parseInt(i, 16);
      if (part == null) {
        return Result.error("IP must contain hex numbers ${addr}->${i}");
      }
      final part_num = part;
      if (part_num >= 65536) {
        return Result.error("IP items has to lower than 65536. ${addr}");
      }
      ip = ip + (BigInt.from(part_num) << shift);
      shift -= 16;
    }
    return Result.ok(SplitOnColon(ip, parts_len));
  }

  static Result<BigInt, String> split_to_num(String addr) {
    var pre_post = addr.trim().split("::");
    if (pre_post.length == 0 && addr.contains("::")) {
      pre_post = pre_post.sublist(0, pre_post.length + 1);
      pre_post[pre_post.length - 1] = "";
    }
    if (pre_post.length == 1 && addr.contains("::")) {
      pre_post = pre_post.sublist(pre_post.length + 1);
      pre_post[pre_post.length - 1] = "";
    }
    if (pre_post.length > 2) {
      return Result.error("IPv6 only allow one :: ${addr}");
    }
    if (pre_post.length == 2) {
      //println!("{}=::={}", pre_post[0], pre_post[1]);
      final pre = IPAddress.split_on_colon(pre_post.first);
      if (pre.isFailure) {
        return Result.error(pre.error);
      }
      final post = IPAddress.split_on_colon(pre_post[1]);
      if (post.isFailure) {
        return Result.error(post.error);
      }
      // println!("pre:{} post:{}", pre_parts, post_parts);
      return Result.ok(
          (pre.value.ip << (128 - (pre.value.size * 16))) + post.value.ip);
    }
    //println!("split_to_num:no double:{}", addr);
    final ret = IPAddress.split_on_colon(addr);
    if (ret.isFailure || ret.value.size != 128 / 16) {
      return Result.error("incomplete IPv6");
    }
    return Result.ok(ret.value.ip);
  }

  static bool is_valid_ipv6(String addr) {
    return IPAddress.split_to_num(addr).isSuccess;
  }

  /// private helper for summarize
  /// assumes that networks is output from reduce_networks
  /// means it should be sorted lowers first and uniq
  ///

  static int pos_to_idx(int pos, int len) {
    final ilen = len; //as isize;
    // let ret = pos % ilen;
    final rem = ((pos % ilen) + ilen) % ilen;
    // println!("pos_to_idx:{}:{}=>{}:{}", pos, len, ret, rem);
    return rem;
  }

  static List<IPAddress> aggregate(List<IPAddress> networks) {
    if (networks.length == 0) {
      return List<IPAddress>.empty();
    }
    if (networks.length == 1) {
      return [networks.first.network()];
    }
    final stack = IPAddress.sort(networks.map((i) => i.network()).toList());

    // for (var i in stack) {
    //   print("${i.to_string_uncompressed()}");
    // }
    var pos = 0;
    while (true) {
      if (pos < 0) {
        pos = 0;
      }
      final stack_len = stack.length; // borrow checker
      // print("loop:${pos}:${stack_len}");
      if (pos >= stack_len) {
        // print("exit first:${stack_len}:${pos}");
        return stack; //.map[i| return i.network()];
      }
      final first = IPAddress.pos_to_idx(pos, stack_len);
      pos = pos + 1;
      if (pos >= stack_len) {
        // print("exit second:${stack_len}:${pos}");
        return stack; //.map[i| return i.network()];
      }
      final second = IPAddress.pos_to_idx(pos, stack_len);
      pos = pos + 1;
      //let mut firstUnwrap = first.unwrap();
      if (stack.first.includes(stack[second])) {
        pos = pos - 2;
        // print("remove:1:${first}:${second}:${stack_len}=>${pos+1}");
        stack.removeAt(IPAddress.pos_to_idx(pos + 1, stack_len));
      } else {
        final ipFirst = stack[first];
        stack[first] = ipFirst.change_prefix(ipFirst.prefix.sub(1).value).value;
        // print("complex:${pos}:${stack_len}:${first}:${second}:P1:${stack[first].to_string()}:P2:${stack[second].to_string()}:${dumpStack(stack)}");
        if ((stack[first].prefix.num + 1) == stack[second].prefix.num &&
            stack[first].includes(stack[second])) {
          pos = pos - 2;
          final idx = IPAddress.pos_to_idx(pos, stack_len);
          stack[idx] = stack[first].clone(); // kaputt
          stack.removeAt(IPAddress.pos_to_idx(pos + 1, stack_len));
          // print("remove-2:${pos+1}:${stack_len}:${dumpStack(stack)}");
          pos = pos - 1; // backtrack
        } else {
          final myFirst = stack[first];
          stack[first] =
              myFirst.change_prefix(myFirst.prefix.add(1).value).value;
          // print("easy:${pos}:${stack_len}=>${myFirst.hashCode}:${myFirst.to_string()}:${stack[first].hashCode}:${stack[first].to_string()}:${dumpStack(stack)}");
          pos = pos - 1; // do it with second as first
        }
      }
    }
    // print("agg=${pos}, ${stack.length}");
    // return stack;
  }

  List<int> parts() {
    return this.ip_bits.parts(this.host_address);
  }

  List<String> parts_hex_str() {
    final parts = this.parts();
    List<String> ret = List.generate(parts.length, (i) => "");
    for (var i = 0; i < parts.length; i++) {
      ret[i] = parts[i].toRadixString(16).padLeft(4, '0');
    }
    return ret;
  }

  ///  Returns the IP address in in-addr.arpa format
  ///  for DNS Domain definition entries like SOA Records
  ///
  ///    ip = IPAddress("172.17.100.50/15")
  ///
  ///    ip.dns_rev_domains
  ///      // => ["16.172.in-addr.arpa","17.172.in-addr.arpa"]
  ///
  List<String> dns_rev_domains() {
    final dns_networks = this.dns_networks();
    List<String> ret = List.generate(dns_networks.length, (_) => "");
    for (var i = 0; i < dns_networks.length; i++) {
      // println!("dns_rev_domains:{}:{}", this.to_string(), net.to_string());
      ret[i] = dns_networks[i].dns_reverse();
    }
    return ret;
  }

  String dns_reverse() {
    var ret = "";
    var dot = "";
    final dns_parts = this.dns_parts();
    for (var i = ((this.prefix.host_prefix() + (this.ip_bits.dns_bits - 1)) ~/
            this.ip_bits.dns_bits);
        i < dns_parts.length;
        i++) {
      ret += dot;
      ret += this.ip_bits.dns_part_format(dns_parts[i]);
      dot = ".";
    }
    ret += dot;
    ret += this.ip_bits.rev_domain;
    return ret.toString();
  }

  List<int> dns_parts() {
    final len = this.ip_bits.bits ~/ this.ip_bits.dns_bits;
    List<int> ret = List.generate(len, (_) => 0);
    var num = this.host_address;
    var mask = BigInt.one << this.ip_bits.dns_bits;
    for (var i = 0; i < len; i++) {
      var part = num % mask;
      num = num >> this.ip_bits.dns_bits;
      ret[i] = part.toInt();
    }
    return ret;
  }

  List<IPAddress> dns_networks() {
    // +this.ip_bits.dns_bits-1
    final next_bit_mask = this.ip_bits.bits -
        (((this.prefix.host_prefix()) ~/ this.ip_bits.dns_bits) *
            this.ip_bits.dns_bits);
    if (next_bit_mask <= 0) {
      return [this.network()];
    }
    //  println!("dns_networks:{}:{}", this.to_string(), next_bit_mask);
    // dns_bits
    final step_bit_net = BigInt.one << (this.ip_bits.bits - next_bit_mask);
    if (step_bit_net == BigInt.zero) {
      return [this.network()];
    }
    List<IPAddress> ret = [];
    var step = this.network().host_address;
    final prefix = this.prefix.from(next_bit_mask).value;
    while (step.compareTo(this.broadcast().host_address) <= 0) {
      ret.add(this.from(step, prefix));
      step = step + step_bit_net;
    }
    return ret;
  }

  /// Summarization (or aggregation) is the process when two or more
  /// networks are taken together to check if a supernet, including all
  /// and only these networks, exists. If it exists then this supernet
  /// is called the summarized (or aggregated) network.
  ///
  /// It is very important to understand that summarization can only
  /// occur if there are no holes in the aggregated network, or, in other
  /// words, if the given networks fill completely the address space
  /// of the supernet. So the two rules are:
  ///
  /// 1) The aggregate network must contain +all+ the IP addresses of the
  ///    original networks;
  /// 2) The aggregate network must contain +only+ the IP addresses of the
  ///    original networks;
  ///
  /// A few examples will help clarify the above. Let's consider for
  /// instance the following two networks:
  ///
  ///   ip1 = IPAddress("172.16.10.0/24")
  ///   ip2 = IPAddress("172.16.11.0/24")
  ///
  /// These two networks can be expressed using only one IP address
  /// network if we change the prefix. Let Ruby do the work:
  ///
  ///   IPAddress::IPv4::summarize(ip1,ip2).to_s
  ///     ///  "172.16.10.0/23"
  ///
  /// We note how the network "172.16.10.0/23" includes all the addresses
  /// specified in the above networks, and (more important) includes
  /// ONLY those addresses.
  ///
  /// If we summarized +ip1+ and +ip2+ with the following network:
  ///
  ///   "172.16.0.0/16"
  ///
  /// we would have satisfied rule /// 1 above, but not rule /// 2. So "172.16.0.0/16"
  /// is not an aggregate network for +ip1+ and +ip2+.
  ///
  /// If it's not possible to compute a single aggregated network for all the
  /// original networks, the method returns an array with all the aggregate
  /// networks found. For example, the following four networks can be
  /// aggregated in a single /22:
  ///
  ///   ip1 = IPAddress("10.0.0.1/24")
  ///   ip2 = IPAddress("10.0.1.1/24")
  ///   ip3 = IPAddress("10.0.2.1/24")
  ///   ip4 = IPAddress("10.0.3.1/24")
  ///
  ///   IPAddress::IPv4::summarize(ip1,ip2,ip3,ip4).to_string
  ///     ///  "10.0.0.0/22",
  ///
  /// But the following networks can't be summarized in a single network:
  ///
  ///   ip1 = IPAddress("10.0.1.1/24")
  ///   ip2 = IPAddress("10.0.2.1/24")
  ///   ip3 = IPAddress("10.0.3.1/24")
  ///   ip4 = IPAddress("10.0.4.1/24")
  ///
  ///   IPAddress::IPv4::summarize(ip1,ip2,ip3,ip4).map{|i| i.to_string}
  ///     ///  ["10.0.1.0/24","10.0.2.0/23","10.0.4.0/24"]
  ///
  ///
  ///  Summarization (or aggregation) is the process when two or more
  ///  networks are taken together to check if a supernet, including all
  ///  and only these networks, exists. If it exists then this supernet
  ///  is called the summarized (or aggregated) network.
  ///
  ///  It is very important to understand that summarization can only
  ///  occur if there are no holes in the aggregated network, or, in other
  ///  words, if the given networks fill completely the address space
  ///  of the supernet. So the two rules are:
  ///
  ///  1) The aggregate network must contain +all+ the IP addresses of the
  ///     original networks;
  ///  2) The aggregate network must contain +only+ the IP addresses of the
  ///     original networks;
  ///
  ///  A few examples will help clarify the above. Let's consider for
  ///  instance the following two networks:
  ///
  ///    ip1 = IPAddress("2000:0::4/32")
  ///    ip2 = IPAddress("2000:1::6/32")
  ///
  ///  These two networks can be expressed using only one IP address
  ///  network if we change the prefix. Let Ruby do the work:
  ///
  ///    IPAddress::IPv6::summarize(ip1,ip2).to_s
  ///      ///  "2000:0::/31"
  ///
  ///  We note how the network "2000:0::/31" includes all the addresses
  ///  specified in the above networks, and (more important) includes
  ///  ONLY those addresses.
  ///
  ///  If we summarized +ip1+ and +ip2+ with the following network:
  ///
  ///    "2000::/16"
  ///
  ///  we would have satisfied rule /// 1 above, but not rule /// 2. So "2000::/16"
  ///  is not an aggregate network for +ip1+ and +ip2+.
  ///
  ///  If it's not possible to compute a single aggregated network for all the
  ///  original networks, the method returns an array with all the aggregate
  ///  networks found. For example, the following four networks can be
  ///  aggregated in a single /22:
  ///
  ///    ip1 = IPAddress("2000:0::/32")
  ///    ip2 = IPAddress("2000:1::/32")
  ///    ip3 = IPAddress("2000:2::/32")
  ///    ip4 = IPAddress("2000:3::/32")
  ///
  ///    IPAddress::IPv6::summarize(ip1,ip2,ip3,ip4).to_string
  ///      ///  ""2000:3::/30",
  ///
  ///  But the following networks can't be summarized in a single network:
  ///
  ///    ip1 = IPAddress("2000:1::/32")
  ///    ip2 = IPAddress("2000:2::/32")
  ///    ip3 = IPAddress("2000:3::/32")
  ///    ip4 = IPAddress("2000:4::/32")
  ///
  ///    IPAddress::IPv4::summarize(ip1,ip2,ip3,ip4).map{|i| i.to_string}
  ///      ///  ["2000:1::/32","2000:2::/31","2000:4::/32"]
  ///

  static List<IPAddress> summarize(List<IPAddress> networks) {
    return IPAddress.aggregate(networks);
  }

  static Result<List<IPAddress>, String> summarize_str(List<String> netstr) {
    final vec = IPAddress.to_ipaddress_vec(netstr);
    if (vec.isFailure) {
      return Result.error(vec.error);
    }
    return Result.ok(IPAddress.aggregate(vec.value));
  }

  bool ip_same_kind(IPAddress oth) {
    return this.ip_bits.version == oth.ip_bits.version;
  }

  ///  Returns true if the address is an unspecified address
  ///
  ///  See IPAddress::IPv6::Unspecified for more information
  ///

  bool is_unspecified() {
    return this.host_address == BigInt.zero;
  }

  ///  Returns true if the address is a loopback address
  ///
  ///  See IPAddress::IPv6::Loopback for more information
  ///

  bool is_loopback() {
    return this.vt_is_loopback(this);
  }

  ///  Returns true if the address is a mapped address
  ///
  ///  See IPAddress::IPv6::Mapped for more information
  ///

  bool is_mapped() {
    final ffff = BigInt.from(0xffff); //.ONE.shiftLeft(16).sub(BigInt.ONE)
    return (this.mapped != null && (this.host_address >> 32) == ffff);
  }

  ///  Returns the prefix portion of the IPv4 object
  ///  as a IPAddress::Prefix32 object
  ///
  ///    ip = IPAddress("172.16.100.4/22")
  ///
  ///    ip.prefix
  ///      ///  22
  ///
  ///    ip.prefix.class
  ///      ///  IPAddress::Prefix32
  ///

  //  Prefix prefix() {
  //     return this.prefix;
  // }

  /// Checks if the argument is a valid IPv4 netmask
  /// expressed in dotted decimal format.
  ///
  ///   IPAddress.valid_ipv4_netmask? "255.255.0.0"
  ///     ///  true
  ///

  static bool is_valid_netmask(String addr) {
    return IPAddress.parse_netmask_to_prefix(addr).isSuccess;
  }

  static Result<int, String> netmask_to_prefix(BigInt nm, int bits) {
    var prefix = 0;
    var addr = nm;
    var in_host_part = true;
    final two = BigInt.from(2);
    for (var i = 0; i < bits; i++) {
      final bit = addr % two;
      if (in_host_part && bit == BigInt.zero) {
        prefix = prefix + 1;
      } else if (in_host_part && bit == BigInt.one) {
        in_host_part = false;
      } else if (!in_host_part && bit == BigInt.zero) {
        return Result.error("this is not a net mask ${nm}");
      }
      addr = addr >> 1;
    }
    return Result.ok(bits - prefix);
  }

  static Result<int, String> parse_netmask_to_prefix(String my_str) {
    final is_number = IPAddress.parseInt(my_str, 10);
    if (is_number != null) {
      return Result.ok(is_number.toInt());
    }
    final my = IPAddress.parse(my_str);
    if (my.isFailure) {
      return Result.error("illegal netmask ${my.error}");
    }
    final my_ip = my.value;
    return IPAddress.netmask_to_prefix(my_ip.host_address, my_ip.ip_bits.bits);
  }

  ///  Set a prefix number for the object
  ///
  ///  This is useful if you want to change the prefix
  ///  to an object created with IPv4::parse_u32 or
  ///  if the object was created using the classful
  ///  mask.
  ///
  ///    ip = IPAddress("172.16.100.4")
  ///
  ///    puts ip
  ///      ///  172.16.100.4/16
  ///
  ///    ip.prefix = 22
  ///
  ///    puts ip
  ///      ///  172.16.100.4/22
  ///
  Result<IPAddress, String> change_prefix(Prefix prefix) {
    return Result.ok(this.from(this.host_address, prefix));
  }

  Result<IPAddress, String> change_prefix_int(int num) {
    final prefix = this.prefix.from(num);
    if (prefix.isFailure) {
      return Result.error(prefix.error);
    }
    // print("change_prefix_int:${num}:${prefix.unwrap().num}:${prefix.unwrap().net_mask}");
    return Result.ok(this.from(this.host_address, prefix.value));
  }

  Result<IPAddress, String> change_netmask(String my_str) {
    final nm = IPAddress.parse_netmask_to_prefix(my_str);
    if (nm.isFailure) {
      return Result.error(nm.error);
    }
    return this.change_prefix_int(nm.value);
  }

  ///  Returns a string with the IP address in canonical
  ///  form.
  ///
  ///    ip = IPAddress("172.16.100.4/22")
  ///
  ///    ip.to_string
  ///      ///  "172.16.100.4/22"
  ///
  String to_string() {
    var ret = "";
    ret += this.to_s();
    ret += "/";
    ret += this.prefix.to_s();
    return ret;
  }

  String to_s() {
    return this.ip_bits.as_compressed_string(this.host_address);
  }

  String to_string_uncompressed() {
    var ret = "";
    ret += this.to_s_uncompressed();
    ret += "/";
    ret += this.prefix.to_s();
    return ret.toString();
  }

  String to_s_uncompressed() {
    return this.ip_bits.as_uncompressed_string(this.host_address);
  }

  String to_s_mapped() {
    if (this.is_mapped()) {
      return "::ffff:${this.mapped?.to_s()}";
    }
    return this.to_s();
  }

  String to_string_mapped() {
    if (this.is_mapped()) {
      final mapped = this.mapped;
      return "${this.to_s_mapped()}/${mapped?.prefix.num}";
    }
    return this.to_string();
  }

  ///  Returns the address portion of an IP in binary format,
  ///  as a string containing a sequence of 0 and 1
  ///
  ///    ip = IPAddress("127.0.0.1")
  ///
  ///    ip.bits
  ///      ///  "01111111000000000000000000000001"
  ///

  String bits() {
    final num = this.host_address.toRadixString(2);
    var ret = "";
    for (var i = num.length; i < this.ip_bits.bits; i++) {
      ret += "0";
    }
    ret += num;
    return ret.toString();
  }

  String to_hex() {
    return this.host_address.toRadixString(16);
  }

  IPAddress netmask() {
    // print("netmask:${this.prefix.netmask()}:${this.prefix.to_s()}");
    return this.from(this.prefix.netmask(), this.prefix);
  }

  ///  Returns the broadcast address for the given IP.
  ///
  ///    ip = IPAddress("172.16.10.64/24")
  ///
  ///    ip.broadcast.to_s
  ///      ///  "172.16.10.255"
  ///

  IPAddress broadcast() {
    final bcast = (this.network().host_address + this.size()) - BigInt.one;
    return this.from(bcast, this.prefix);
    // IPv4::parse_u32(this.broadcast_u32, this.prefix)
  }

  ///  Checks if the IP address is actually a network
  ///
  ///    ip = IPAddress("172.16.10.64/24")
  ///
  ///    ip.network?
  ///      ///  false
  ///
  ///    ip = IPAddress("172.16.10.64/26")
  ///
  ///    ip.network?
  ///      ///  true
  ///

  bool is_network() {
    return this.prefix.num != this.ip_bits.bits &&
        this.host_address == this.network().host_address;
  }

  ///  Returns a IPv4 object with the network number
  ///  for the given IP.
  ///
  ///    ip = IPAddress("172.16.10.64/24")
  ///
  ///    ip.network.to_s
  ///      ///  "172.16.10.0"
  ///

  IPAddress network() {
    return this.from(
        IPAddress.to_network(this.host_address, this.prefix.host_prefix()),
        this.prefix);
  }

  static BigInt to_network(BigInt adr, int host_prefix) {
    return (adr >> host_prefix) << host_prefix;
  }

  BigInt sub(IPAddress other) {
    if (this.host_address.compareTo(other.host_address) >= 0) {
      return this.host_address - other.host_address;
    }
    return other.host_address - this.host_address;
  }

  List<IPAddress> add(IPAddress other) {
    return IPAddress.aggregate([this, other]);
  }

  Iterable<String> to_s_vec(List<IPAddress> vec) {
    return vec.map((i) => i.to_s());
  }

  static List<String> to_string_vec(List<IPAddress> vec) {
    return vec.map((i) => i.to_string()).toList();
  }

  static Result<List<IPAddress>, String> to_ipaddress_vec(List<String> vec) {
    List<IPAddress> ret = [];
    for (var ipstr in vec) {
      final ipa = IPAddress.parse(ipstr);
      if (ipa.isFailure) {
        return Result.error(ipa.error);
      }
      ret.add(ipa.value);
    }
    return Result.ok(ret);
  }

  ///  Returns a IPv4 object with the
  ///  first host IP address in the range.
  ///
  ///  Example: given the 192.168.100.0/24 network, the first
  ///  host IP address is 192.168.100.1.
  ///
  ///    ip = IPAddress("192.168.100.0/24")
  ///
  ///    ip.first.to_s
  ///      ///  "192.168.100.1"
  ///
  ///  The object IP doesn't need to be a network: the method
  ///  automatically gets the network number from it
  ///
  ///    ip = IPAddress("192.168.100.50/24")
  ///
  ///    ip.first.to_s
  ///      ///  "192.168.100.1"
  ///
  IPAddress first() {
    return this
        .from(this.network().host_address + this.ip_bits.host_ofs, this.prefix);
  }

  ///  Like its sibling method IPv4/// first, this method
  ///  returns a IPv4 object with the
  ///  last host IP address in the range.
  ///
  ///  Example: given the 192.168.100.0/24 network, the last
  ///  host IP address is 192.168.100.254
  ///
  ///    ip = IPAddress("192.168.100.0/24")
  ///
  ///    ip.last.to_s
  ///      ///  "192.168.100.254"
  ///
  ///  The object IP doesn't need to be a network: the method
  ///  automatically gets the network number from it
  ///
  ///    ip = IPAddress("192.168.100.50/24")
  ///
  ///    ip.last.to_s
  ///      ///  "192.168.100.254"
  ///

  IPAddress last() {
    return this.from(
        this.broadcast().host_address - this.ip_bits.host_ofs, this.prefix);
  }

  ///  Iterates over all the hosts IP addresses for the given
  ///  network (or IP address).
  ///
  ///    ip = IPAddress("10.0.0.1/29")
  ///
  ///    ip.each_host do |i|
  ///      p i.to_s
  ///    end
  ///      ///  "10.0.0.1"
  ///      ///  "10.0.0.2"
  ///      ///  "10.0.0.3"
  ///      ///  "10.0.0.4"
  ///      ///  "10.0.0.5"
  ///      ///  "10.0.0.6"
  ///

  each_host(Each func) {
    var i = this.first().host_address;
    while (i.compareTo(this.last().host_address) <= 0) {
      func(this.from(i, this.prefix));
      i = i + BigInt.one;
    }
  }

  ///  Iterates over all the IP addresses for the given
  ///  network (or IP address).
  ///
  ///  The object yielded is a IPv4 object created
  ///  from the iteration.
  ///
  ///    ip = IPAddress("10.0.0.1/29")
  ///
  ///    ip.each do |i|
  ///      p i.address
  ///    end
  ///      ///  "10.0.0.0"
  ///      ///  "10.0.0.1"
  ///      ///  "10.0.0.2"
  ///      ///  "10.0.0.3"
  ///      ///  "10.0.0.4"
  ///      ///  "10.0.0.5"
  ///      ///  "10.0.0.6"
  ///      ///  "10.0.0.7"
  ///

  void each(Each func) {
    var i = this.network().host_address;
    while (i.compareTo(this.broadcast().host_address) <= 0) {
      func(this.from(i, this.prefix));
      i = i + BigInt.one;
    }
  }

  ///  Spaceship operator to compare IPv4 objects
  ///
  ///  Comparing IPv4 addresses is useful to ordinate
  ///  them into lists that match our intuitive
  ///  perception of ordered IP addresses.
  ///
  ///  The first comparison criteria is the u32 value.
  ///  For example, 10.100.100.1 will be considered
  ///  to be less than 172.16.0.1, because, in a ordered list,
  ///  we expect 10.100.100.1 to come before 172.16.0.1.
  ///
  ///  The second criteria, in case two IPv4 objects
  ///  have identical addresses, is the prefix. An higher
  ///  prefix will be considered greater than a lower
  ///  prefix. This is because we expect to see
  ///  10.100.100.0/24 come before 10.100.100.0/25.
  ///
  ///  Example:
  ///
  ///    ip1 = IPAddress "10.100.100.1/8"
  ///    ip2 = IPAddress "172.16.0.1/16"
  ///    ip3 = IPAddress "10.100.100.1/16"
  ///
  ///    ip1 < ip2
  ///      ///  true
  ///    ip1 > ip3
  ///      ///  false
  ///
  ///    [ip1,ip2,ip3].sort.map{|i| i.to_string}
  ///      ///  ["10.100.100.1/8","10.100.100.1/16","172.16.0.1/16"]
  ///
  ///  Returns the number of IP addresses included
  ///  in the network. It also counts the network
  ///  address and the broadcast address.
  ///
  ///    ip = IPAddress("10.0.0.1/29")
  ///
  ///    ip.size
  ///      ///  8
  ///

  BigInt size() {
    return BigInt.one << this.prefix.host_prefix();
  }

  bool is_same_kind(IPAddress oth) {
    return this.is_ipv4() == oth.is_ipv4() && this.is_ipv6() == oth.is_ipv6();
  }

  ///  Checks whether a subnet includes the given IP address.
  ///
  ///  Accepts an IPAddress::IPv4 object.
  ///
  ///    ip = IPAddress("192.168.10.100/24")
  ///
  ///    addr = IPAddress("192.168.10.102/24")
  ///
  ///    ip.include? addr
  ///      ///  true
  ///
  ///    ip.include? IPAddress("172.16.0.48/16")
  ///      ///  false
  ///

  bool includes(IPAddress oth) {
    final ret = this.is_same_kind(oth) &&
        this.prefix.num <= oth.prefix.num &&
        this.network().host_address ==
            IPAddress.to_network(oth.host_address, this.prefix.host_prefix());
    // println!("includes:{}=={}=>{}", this.to_string(), oth.to_string(), ret);
    return ret;
  }

  ///  Checks whether a subnet includes all the
  ///  given IPv4 objects.
  ///
  ///    ip = IPAddress("192.168.10.100/24")
  ///
  ///    addr1 = IPAddress("192.168.10.102/24")
  ///    addr2 = IPAddress("192.168.10.103/24")
  ///
  ///    ip.include_all?(addr1,addr2)
  ///      ///  true
  ///

  bool includes_all(List<IPAddress> oths) {
    return oths.indexWhere((oth) => !this.includes(oth)) < 0;
  }

  ///  Checks if an IPv4 address objects belongs
  ///  to a private network RFC1918
  ///
  ///  Example:
  ///
  ///    ip = IPAddress "10.1.1.1/24"
  ///    ip.private?
  ///      ///  true
  ///

  bool is_private() {
    return this.vt_is_private(this);
  }

  ///  Splits a network into different subnets
  ///
  ///  If the IP Address is a network, it can be divided into
  ///  multiple networks. If +self+ is not a network, this
  ///  method will calculate the network from the IP and then
  ///  subnet it.
  ///
  ///  If +subnets+ is an power of two number, the resulting
  ///  networks will be divided evenly from the supernet.
  ///
  ///    network = IPAddress("172.16.10.0/24")
  ///
  ///    network / 4   ///  implies map{|i| i.to_string}
  ///      ///  ["172.16.10.0/26",
  ///           "172.16.10.64/26",
  ///           "172.16.10.128/26",
  ///           "172.16.10.192/26"]
  ///
  ///  If +num+ is any other number, the supernet will be
  ///  divided into some networks with a even number of hosts and
  ///  other networks with the remaining addresses.
  ///
  ///    network = IPAddress("172.16.10.0/24")
  ///
  ///    network / 3   ///  implies map{|i| i.to_string}
  ///      ///  ["172.16.10.0/26",
  ///           "172.16.10.64/26",
  ///           "172.16.10.128/25"]
  ///
  ///  Returns an array of IPv4 objects
  ///

  static List<IPAddress> sum_first_found(List<IPAddress> arr) {
    var dup = List<IPAddress>.from(arr);
    if (dup.length < 2) {
      return dup;
    }
    for (var i = dup.length - 2; i >= 0; i--) {
      final a = IPAddress.summarize([dup[i], dup[i + 1]]);
      // println!("dup:{}:{}:{}", dup.len(), i, a.len());
      if (a.length == 1) {
        dup[i] = a[0];
        dup.removeAt(i + 1);
        return dup;
      }
    }
    return dup;
  }

  Result<List<IPAddress>, String> split(int subnets) {
    if (subnets == 0 || (1 << this.prefix.host_prefix()) <= subnets) {
      return Result.error("Value ${subnets} out of range");
    }
    final networks = this.subnet(this.newprefix(subnets).value.num);
    if (networks.isFailure) {
      return Result.error(networks.error);
    }
    var net = networks.value;
    while (net.length != subnets) {
      net = IPAddress.sum_first_found(net);
    }
    return Result.ok(net);
  }

  ///  Returns a IPv4 object from the supernetting
  ///  of the instance network.
  ///
  ///  Supernetting is similar to subnetting, except
  ///  that you getting as a result a network with a
  ///  smaller prefix (bigger host space). For example,
  ///  given the network
  ///
  ///    ip = IPAddress("172.16.10.0/24")
  ///
  ///  you can supernet it with a /23 prefix
  ///
  ///    ip.supernet(23).to_string
  ///      ///  "172.16.10.0/23"
  ///
  ///  However if you supernet it with a /22 prefix, the
  ///  network address will change:
  ///
  ///    ip.supernet(22).to_string
  ///      ///  "172.16.8.0/22"
  ///
  ///  If +new_prefix+ is less than 1, returns 0.0.0.0/0
  ///

  Result<IPAddress, String> supernet(int new_prefix) {
    if (new_prefix >= this.prefix.num) {
      return Result.error(
          "prefix must be smaller than existing prefix: ${new_prefix} >= ${this.prefix.num}");
    }
    // let mut new_ip = this.host_address.clone();
    // for _ in new_prefix..this.prefix.num {
    //     new_ip = new_ip ${ 1;
    // }
    return Result.ok(this
        .from(this.host_address, this.prefix.from(new_prefix).value)
        .network());
  }

  ///  This method implements the subnetting function
  ///  similar to the one described in RFC3531.
  ///
  ///  By specifying a prefix, the method calculates
  ///  the network number for the given IPv4 object
  ///  and calculates the subnets associated to the new
  ///  prefix.
  ///
  ///  For example, given the following network:
  ///
  ///    ip = IPAddress "172.16.10.0/24"
  ///
  ///  we can calculate the subnets with a /26 prefix
  ///
  ///    ip.subnets(26).map(&:to_string)
  ///      ///  ["172.16.10.0/26", "172.16.10.64/26",
  ///           "172.16.10.128/26", "172.16.10.192/26"]
  ///
  ///  The resulting number of subnets will of course always be
  ///  a power of two.
  ///

  Result<List<IPAddress>, String> subnet(int subprefix) {
    if (subprefix < this.prefix.num || this.ip_bits.bits < subprefix) {
      return Result.error(
          "prefix must be between prefix${this.prefix.num} ${subprefix} and ${this.ip_bits.bits}");
    }
    List<IPAddress> ret = [];
    var net = this.network();
    var prefix = net.prefix.from(subprefix).value;
    var host_address = net.host_address;
    for (var i = 0; i < (1 << (subprefix - this.prefix.num)); i++) {
      net = net.from(host_address, prefix);
      ret.add(net);
      final size = net.size();
      host_address = host_address + size;
    }
    return Result.ok(ret);
  }

  ///  Return the ip address in a format compatible
  ///  with the IPv6 Mapped IPv4 addresses
  ///
  ///  Example:
  ///
  ///    ip = IPAddress("172.16.10.1/24")
  ///
  ///    ip.to_ipv6
  ///      ///  "ac10:0a01"
  ///

  IPAddress to_ipv6() {
    return this.vt_to_ipv6(this);
  }

  //  private methods
  //

  Result<Prefix, String> newprefix(int num) {
    for (var i = num; i < this.ip_bits.bits; i++) {
      var a = log(i) ~/ log(2);
      if (a == log(i) / log(2)) {
        return this.prefix.add(a as int);
      }
    }
    return Result.error("newprefix not found ${num},${this.ip_bits.bits}");
  }

  String toString() {
    return "IPAddress:${this.to_string()}@${this.hashCode}";
  }
}
