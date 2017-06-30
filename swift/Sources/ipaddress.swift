import Foundation

import BigInt

typealias Is = (_ source: IPAddress) -> Bool;

typealias ToIpv4 = (_ source: IPAddress) -> IPAddress;

public typealias EachFn = (_ source: IPAddress) -> Void;

extension String {
  public func index(of char: Character) -> Int? {
    if let idx = characters.index(of: char) {
      return characters.distance(from: startIndex, to: idx)
    }
    return nil
  }
}

extension Array {
  func clone() -> Array {
    var copiedArray = Array<Element>()
    for element in self {
      copiedArray.append(element)
    }
    return copiedArray
  }
}


public class ResultBigUIntParts {
  var crunchy: BigUInt;
  var parts: Int;
  
  init(_ crunchy: BigUInt, _ parts: Int) {
    self.crunchy = crunchy;
    self.parts = parts;
    // console.log("ResultBigUIntParts:", this);
  }
}

public class IPAddress : Equatable, CustomStringConvertible {
  var ip_bits: IpBits;
  public var host_address: BigUInt;
  public var prefix: Prefix;
  public var mapped: IPAddress?;
  let vt_is_private: Is;
  let vt_is_loopback: Is;
  let vt_to_ipv6: ToIpv4;
  
  init(ip_bits: IpBits, host_address: BigUInt, prefix: Prefix,
       mapped: IPAddress?,
       vt_is_private: @escaping Is,
       vt_is_loopback: @escaping Is,
       vt_to_ipv6: @escaping ToIpv4) {
    self.ip_bits = ip_bits;
    self.host_address = host_address;
    self.prefix = prefix;
    self.mapped = mapped;
    self.vt_is_private = vt_is_private;
    self.vt_is_loopback = vt_is_loopback;
    self.vt_to_ipv6 = vt_to_ipv6;
  }
  public var description: String {
    return "<IPAddress:\(self.to_string())>";
  }
  
  public func clone()-> IPAddress {
    var mapped: IPAddress? = nil;
    if (self.mapped != nil) {
      mapped = self.mapped!.clone();
    }
    return IPAddress(
      ip_bits: self.ip_bits.clone(),
      host_address: self.host_address,
      prefix: self.prefix.clone(),
      mapped: mapped,
      vt_is_private: self.vt_is_private,
      vt_is_loopback: self.vt_is_loopback,
      vt_to_ipv6: self.vt_to_ipv6
    );
  }
  
  public func lt(_ oth: IPAddress)-> Bool {
    return self.cmp(oth) < 0;
  }
  
  public func lte(_ oth: IPAddress)-> Bool {
    return self.cmp(oth) <= 0;
  }
  
  public func gt(_ oth: IPAddress)-> Bool {
    return self.cmp(oth) > 0;
  }
  
  public func gte(_ oth: IPAddress)-> Bool {
    return self.cmp(oth) >= 0;
  }
  
  public func cmp(_ oth: IPAddress) -> Int {
    if (self.ip_bits.version != oth.ip_bits.version) {
      if (self.ip_bits.version == IpVersion.V6) {
        return 1;
      }
      return -1;
    }
    //let adr_diff = self.host_address - oth.host_address;
    if (self.host_address > oth.host_address) {
      return 1;
    } else if (self.host_address < oth.host_address) {
      return -1;
    }
    return self.prefix.cmp(oth.prefix);
  }
  
  public final class func ==(lhs: IPAddress, rhs: IPAddress) -> Bool {
    return lhs.eq(rhs)
  }
  
  public func eq(_ other: IPAddress)-> Bool {
    // if (!!self.mapped != !!self.mapped) {
    //     return false;
    // }
    // if (self.mapped) {
    //     if (!self.mapped.eq(other.mapped)) {
    //         return false;
    //     }
    // }
    // console.log("************", this);
    return self.ip_bits.version == other.ip_bits.version &&
      self.prefix.eq(other.prefix) &&
      self.host_address == other.host_address;
  }
  public func ne(_ other: IPAddress) -> Bool {
    return !self.eq(other);
  }
  // Parse the argument string to create a new
  // IPv4, IPv6 or Mapped IP object
  //
  //   ip  = IPAddress.parse "172.16.10.1/24"
  //   ip6 = IPAddress.parse "2001:db8.8:800:200c:417a/64"
  //   ip_mapped = IPAddress.parse ".ffff:172.16.10.1/128"
  //
  // All the object created will be instances of the
  // correct class:
  //
  //  ip.class
  //    //=> IPAddress.IPv4
  //  ip6.class
  //    //=> IPAddress.IPv6
  //  ip_mapped.class
  //    //=> IPAddress.IPv6.Mapped
  //
  public class func parse(_ str: String) -> IPAddress? {
    let colon = str.index(of: ":")
    let dot = str.index(of: ".")
    if (colon != nil && dot != nil && colon! < dot!) {
      return Ipv6Mapped.create(str);
    } else {
      if (dot != nil && colon == nil) {
        // console.log("ipv4:", str);
        return Ipv4.create(str);
      } else if (dot == nil && colon != nil) {
        // console.log("ipv6:", str);
        return Ipv6.create(str);
      }
    }
    return nil;
  }
  
  public class func split_at_slash(_ str: String)-> (String, String?) {
    let slash: [String] = str.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "/")
    var addr = "";
    if (slash.count >= 1) {
      addr += slash[0].trimmingCharacters(in: .whitespacesAndNewlines)
    }
    if (slash.count >= 2) {
      return (addr, slash[1].trimmingCharacters(in: .whitespacesAndNewlines));
    } else {
      return (addr, nil)
    }
  }
  public func from(_ addr: BigUInt, _ prefix: Prefix) -> IPAddress {
    var mapped: IPAddress? = nil;
    if (self.mapped != nil) {
      mapped = self.mapped!.clone();
    }
    return IPAddress(
      ip_bits: self.ip_bits,
      host_address: addr,
      prefix: prefix.clone(),
      mapped: mapped,
      vt_is_private: self.vt_is_private,
      vt_is_loopback: self.vt_is_loopback,
      vt_to_ipv6: self.vt_to_ipv6
    );
  }
  
  // True if the object is an IPv4 address
  //
  //   ip = IPAddress("192.168.10.100/24")
  //
  //   ip.ipv4?
  //     //-> true
  //
  public func is_ipv4() -> Bool {
    return self.ip_bits.version == IpVersion.V4;
  }
  
  // True if the object is an IPv6 address
  //
  //   ip = IPAddress("192.168.10.100/24")
  //
  //   ip.ipv6?
  //     //-> false
  //
  public func is_ipv6() -> Bool {
    return self.ip_bits.version == IpVersion.V6
  }
  
  // Checks if the given string is a valid IP address,
  // either IPv4 or IPv6
  //
  // Example:
  //
  //   IPAddress.valid? "2002.1"
  //     //=> true
  //
  //   IPAddress.valid? "10.0.0.256"
  //     //=> false
  //
  public class func is_valid(_ addr: String) -> Bool {
    return IPAddress.is_valid_ipv4(addr) || IPAddress.is_valid_ipv6(addr);
  }
  
  class func parse_dec_str(_ str: String) -> UInt? {
    let part = UInt(str);
    if (part == nil) {
      // console.log("parse_dec_str:-2:", str, part);
      return nil;
    }
    // console.log("parse_dec_str:-3:", str, part);
    return part;
  }
  
  class func parse_hex_str(_ str: String)-> Int? {
    return Int(str, radix: 16);
  }
  
  
  // Checks if the given string is a valid IPv4 address
  //
  // Example:
  //
  //   IPAddress.valid_ipv4? "2002.1"
  //     //=> false
  //
  //   IPAddress.valid_ipv4? "172.16.10.1"
  //     //=> true
  //
  class func parse_ipv4_part(_ i: String) -> UInt8? {
    let part = IPAddress.parse_dec_str(i);
    //console.log("i=", i, part);
    if (part == nil || part! >= 256) {
      return nil;
    }
    return UInt8(part!);
  }
  
  class func split_to_u32(_ addr: String) -> BigUInt? {
    var ip = BigUInt(0);
    var shift = 24;
    var split_addr = addr.components(separatedBy: ".");
    if (split_addr.count > 4) {
      return nil;
    }
    let split_addr_len = split_addr.count;
    if (1 <= split_addr_len && split_addr_len < 4) {
      let part = IPAddress.parse_ipv4_part(split_addr[split_addr_len - 1]);
      if (part == nil) {
        return nil;
      }
      ip = BigUInt(part!);
      split_addr = Array(split_addr.dropLast(1))
    }
    for i in split_addr {
      let part = IPAddress.parse_ipv4_part(i);
      // console.log("u32-", addr, i, part);
      if (part == nil) {
        return nil;
      }
      //println!("{}-{}", part_num, shift);
      ip = ip + (BigUInt(part!) << shift);
      shift -= 8;
    }
    return ip;
  }
  
  public class func is_valid_ipv4(_ addr: String) -> Bool {
    return IPAddress.split_to_u32(addr) != nil
  }
  
  
  // Checks if the given string is a valid IPv6 address
  //
  // Example:
  //
  //   IPAddress.valid_ipv6? "2002.1"
  //     //=> true
  //
  //   IPAddress.valid_ipv6? "2002.DEAD.BEEF"
  //     //=> false
  //
  class func split_on_colon(_ addr: String) -> ResultBigUIntParts? {
    let parts = addr.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: ":");
    var ip = BigUInt(0);
    if (parts.count == 1 && parts[0].isEmpty) {
      return ResultBigUIntParts(ip, 0);
    }
    let parts_len = parts.count;
    var shift = ((parts_len - 1) * 16);
    for i in parts {
      //println!("{}={}", addr, i);
      let part = IPAddress.parse_hex_str(i);
      if (part == nil || part! >= 65536) {
        return nil;
      }
      ip = ip + (BigUInt(part!) << shift);
      shift -= 16;
    }
    return ResultBigUIntParts(ip, parts_len);
  }
  
  class func split_to_num(_ addr: String) -> ResultBigUIntParts? {
    //let ip = 0;
    let pre_post = addr.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "::");
    if (pre_post.count > 2) {
      return nil;
    }
    if (pre_post.count == 2) {
      //println!("{}=.={}", pre_post[0], pre_post[1]);
      let pre = IPAddress.split_on_colon(pre_post[0]);
      if (pre == nil) {
        return pre;
      }
      let post = IPAddress.split_on_colon(pre_post[1]);
      if (post == nil) {
        return post;
      }
      // println!("pre:{} post:{}", pre_parts, post_parts);
      return ResultBigUIntParts(
        (pre!.crunchy << (128 - (pre!.parts * 16))) + post!.crunchy, 128 / 16);
    }
    //println!("split_to_num:no double:{}", addr);
    let ret = IPAddress.split_on_colon(addr);
    if (ret == nil || ret!.parts != 128 / 16) {
      return nil;
    }
    return ret;
  }
  
  public class func is_valid_ipv6(_ addr: String) -> Bool {
    return IPAddress.split_to_num(addr) != nil;
  }
  
  
  // private helper for summarize
  // assumes that networks is output from reduce_networks
  // means it should be sorted lowers first and uniq
  //
  
  class func pos_to_idx(_ pos: Int, _ len: Int) -> Int {
    let ilen = len;
    // let ret = pos % ilen;
    let rem = ((pos % ilen) + ilen) % ilen;
    // println!("pos_to_idx:{}:{}=>{}:{}", pos, len, ret, rem);
    return rem;
  }
  
  public class func aggregate(_ networks: [IPAddress]) -> [IPAddress] {
    if (networks.count == 0) {
      return [];
    }
    if (networks.count == 1) {
      // console.log("aggregate:", networks[0], networks[0].network());
      return [networks[0].network()];
    }
    var stack = networks.map({ $0.network() }).sorted(by: { $0.lt($1) });
    // console.log(IPAddress.to_string_vec(stack));
    //     for i in stack {
    //         print("\(i)");
    //     }
    var pos = 0
    while (true) {
      if (pos < 0) {
        pos = 0
      }
      let stack_len = stack.count; // borrow checker
      // println!("loop:{}:{}", pos, stack_len);
      // if stack_len == 1 {
      //     println!("exit 1");
      //     break;
      // }
      if (pos >= stack_len) {
        // println!("exit first:{}:{}", stack_len, pos);
        break;
      }
      let first = IPAddress.pos_to_idx(pos, stack_len);
      pos = pos + 1;
      if (pos >= stack_len) {
        // println!("exit second:{}:{}", stack_len, pos);
        break;
      }
      let second = IPAddress.pos_to_idx(pos, stack_len);
      pos = pos + 1;
      //let firstUnwrap = first;
      if (stack[first].includes(stack[second])) {
        pos = pos - 2;
        // println!("remove:1:{}:{}:{}=>{}", first, second, stack_len, pos + 1);
        let pidx = IPAddress.pos_to_idx(pos + 1, stack_len);
        stack = Array(stack[0...pidx-1] + stack.dropFirst(pidx + 1));
      } else {
        stack[first].prefix = stack[first].prefix.sub(1)!;
        // println!("complex:{}:{}:{}:{}:P1:{}:P2:{}", pos, stack_len,
        // first, second,
        // stack[first].to_string(), stack[second].to_string());
        if ((stack[first].prefix.num + 1) == stack[second].prefix.num &&
          stack[first].includes(stack[second])) {
          pos = pos - 2;
          let idx = IPAddress.pos_to_idx(pos, stack_len);
          stack[idx] = stack[first].clone(); // kaputt
          let pidx = IPAddress.pos_to_idx(pos + 1, stack_len);
          stack = Array(stack[0...pidx-1] + stack.dropFirst(pidx + 1));
          // println!("remove-2:{}:{}", pos + 1, stack_len);
          pos = pos - 1; // backtrack
        } else {
          stack[first].prefix = stack[first].prefix.add(1)!; //reset prefix
          // println!("easy:{}:{}=>{}", pos, stack_len, stack[first].to_string());
          pos = pos - 1; // do it with second as first
        }
      }
    }
    // println!("agg={}:{}", pos, stack.count);
    return stack//[0...stack.count];
  }
  
  public func parts() -> [UInt] {
    return self.ip_bits.parts(self.host_address);
  }
  
  public func parts_hex_str() -> [String] {
    var ret = [String]();
    let leading = 1 << UInt(self.ip_bits.part_bits);
    for i in self.parts() {
      ret.append(String(String(leading + UInt(i), radix: 16).characters.dropFirst(1)));
    }
    return ret;
  }
  
  //  Returns the IP address in in-addr.arpa format
  //  for DNS Domain definition entries like SOA Records
  //
  //    ip = IPAddress("172.17.100.50/15")
  //
  //    ip.dns_rev_domains
  //      // => ["16.172.in-addr.arpa","17.172.in-addr.arpa"]
  //
  public func dns_rev_domains() -> [String] {
    var ret = [String]();
    for net in self.dns_networks() {
      // console.log("dns_rev_domains:", self.to_string(), net.to_string());
      ret.append(net.dns_reverse());
    }
    return ret;
  }
  
  
  public func dns_reverse() -> String {
    var ret = "";
    var dot = "";
    let dns_parts = self.dns_parts();
    for i in stride(from: Int((self.prefix.host_prefix() + (self.ip_bits.dns_bits - 1)) / self.ip_bits.dns_bits),
                    to: self.dns_parts().count, by:1) {
                      // console.log("dns_r", i);
                      ret += dot;
                      ret += self.ip_bits.dns_part_format(dns_parts[i]);
                      dot = ".";
    }
    ret += dot;
    ret += self.ip_bits.rev_domain;
    return ret;
  }
  
  
  public func dns_parts() -> [UInt] {
    var ret: [UInt] = [UInt]();
    var num = self.host_address;
    let mask = BigUInt(1) << Int(self.ip_bits.dns_bits);
    for _ in 1...(self.ip_bits.bits / self.ip_bits.dns_bits) {
      let part = UInt(String(num % mask))!
      num = num >> Int(self.ip_bits.dns_bits);
      ret.append(part);
    }
    return ret;
  }
  
  public func dns_networks() -> [IPAddress] {
    // +self.ip_bits.dns_bits-1
    let next_bit_mask = self.ip_bits.bits -
      ((((self.prefix.host_prefix()) / self.ip_bits.dns_bits)) * self.ip_bits.dns_bits);
    // console.log("dns_networks-1", self.to_string(), self.prefix.host_prefix();j
    // self.ip_bits.dns_bits, next_bit_mask);
    if (next_bit_mask <= 0) {
      return [self.network()];
    }
    //  println!("dns_networks:{}:{}", self.to_string(), next_bit_mask);
    // dns_bits
    let step_bit_net = BigUInt(1) << Int(self.ip_bits.bits - next_bit_mask);
    if (step_bit_net == BigUInt(0)) {
      // console.log("dns_networks-2", self.to_string());
      return [self.network()];
    }
    var ret: [IPAddress] = [IPAddress]();
    var step = self.network().host_address;
    let prefix = self.prefix.from(next_bit_mask)!;
    while (step <= self.broadcast().host_address) {
      // console.log("dns_networks-3", self.to_string(), step.toString(), next_bit_mask, step_bit_net.toString());
      ret.append(self.from(step, prefix));
      step = step + step_bit_net;
    }
    return ret;
  }
  
  
  // Summarization (or aggregation) is the process when two or more
  // networks are taken together to check if a supernet, including all
  // and only these networks, exists. If it exists then this supernet
  // is called the summarized (or aggregated) network.
  //
  // It is very important to understand that summarization can only
  // occur if there are no holes in the aggregated network, or, in other
  // words, if the given networks fill completely the address space
  // of the supernet. So the two rules are:
  //
  // 1) The aggregate network must contain +all+ the IP addresses of the
  //    original networks;
  // 2) The aggregate network must contain +only+ the IP addresses of the
  //    original networks;
  //
  // A few examples will help clarify the above. Let's consider for
  // instance the following two networks:
  //
  //   ip1 = IPAddress("172.16.10.0/24")
  //   ip2 = IPAddress("172.16.11.0/24")
  //
  // These two networks can be expressed using only one IP address
  // network if we change the prefix. Let Ruby do the work:
  //
  //   IPAddress.IPv4.summarize(ip1,ip2).to_s
  //     //=> "172.16.10.0/23"
  //
  // We note how the network "172.16.10.0/23" includes all the addresses
  // specified in the above networks, and (more important) includes
  // ONLY those addresses.
  //
  // If we summarized +ip1+ and +ip2+ with the following network:
  //
  //   "172.16.0.0/16"
  //
  // we would have satisfied rule //1 above, but not rule //2. So "172.16.0.0/16"
  // is not an aggregate network for +ip1+ and +ip2+.
  //
  // If it's not possible to compute a single aggregated network for all the
  // original networks, the method returns an array with all the aggregate
  // networks found. For example, the following four networks can be
  // aggregated in a single /22:
  //
  //   ip1 = IPAddress("10.0.0.1/24")
  //   ip2 = IPAddress("10.0.1.1/24")
  //   ip3 = IPAddress("10.0.2.1/24")
  //   ip4 = IPAddress("10.0.3.1/24")
  //
  //   IPAddress.IPv4.summarize(ip1,ip2,ip3,ip4).to_string
  //     //=> "10.0.0.0/22",
  //
  // But the following networks can't be summarized in a single network:
  //
  //   ip1 = IPAddress("10.0.1.1/24")
  //   ip2 = IPAddress("10.0.2.1/24")
  //   ip3 = IPAddress("10.0.3.1/24")
  //   ip4 = IPAddress("10.0.4.1/24")
  //
  //   IPAddress.IPv4.summarize(ip1,ip2,ip3,ip4).map{|i| i.to_string}
  //     //=> ["10.0.1.0/24","10.0.2.0/23","10.0.4.0/24"]
  //
  //
  //  Summarization (or aggregation) is the process when two or more
  //  networks are taken together to check if a supernet, including all
  //  and only these networks, exists. If it exists then this supernet
  //  is called the summarized (or aggregated) network.
  //
  //  It is very important to understand that summarization can only
  //  occur if there are no holes in the aggregated network, or, in other
  //  words, if the given networks fill completely the address space
  //  of the supernet. So the two rules are:
  //
  //  1) The aggregate network must contain +all+ the IP addresses of the
  //     original networks;
  //  2) The aggregate network must contain +only+ the IP addresses of the
  //     original networks;
  //
  //  A few examples will help clarify the above. Let's consider for
  //  instance the following two networks:
  //
  //    ip1 = IPAddress("2000:0.4/32")
  //    ip2 = IPAddress("2000:1.6/32")
  //
  //  These two networks can be expressed using only one IP address
  //  network if we change the prefix. Let Ruby do the work:
  //
  //    IPAddress.IPv6.summarize(ip1,ip2).to_s
  //      // => "2000:0./31"
  //
  //  We note how the network "2000:0./31" includes all the addresses
  //  specified in the above networks, and (more important) includes
  //  ONLY those addresses.
  //
  //  If we summarized +ip1+ and +ip2+ with the following network:
  //
  //    "2000./16"
  //
  //  we would have satisfied rule // 1 above, but not rule // 2. So "2000./16"
  //  is not an aggregate network for +ip1+ and +ip2+.
  //
  //  If it's not possible to compute a single aggregated network for all the
  //  original networks, the method returns an array with all the aggregate
  //  networks found. For example, the following four networks can be
  //  aggregated in a single /22:
  //
  //    ip1 = IPAddress("2000:0./32")
  //    ip2 = IPAddress("2000:1./32")
  //    ip3 = IPAddress("2000:2./32")
  //    ip4 = IPAddress("2000:3./32")
  //
  //    IPAddress.IPv6.summarize(ip1,ip2,ip3,ip4).to_string
  //      // => ""2000:3./30",
  //
  //  But the following networks can't be summarized in a single network:
  //
  //    ip1 = IPAddress("2000:1./32")
  //    ip2 = IPAddress("2000:2./32")
  //    ip3 = IPAddress("2000:3./32")
  //    ip4 = IPAddress("2000:4./32")
  //
  //    IPAddress.IPv4.summarize(ip1,ip2,ip3,ip4).map{|i| i.to_string}
  //      // => ["2000:1./32","2000:2./31","2000:4./32"]
  //
  public class func summarize(_ networks: [IPAddress]) -> [IPAddress]? {
    return IPAddress.aggregate(networks);
  }
  
  public class func summarize_str(_ netstr: [String]) -> [IPAddress]? {
    let vec = IPAddress.to_ipaddress_vec(netstr);
    // console.log(netstr, vec);
    if (vec == nil) {
      return vec;
    }
    return IPAddress.aggregate(vec!);
  }
  
  public func ip_same_kind(_ oth: IPAddress) -> Bool {
    return self.ip_bits.version == oth.ip_bits.version
  }
  
  //  Returns true if the address is an unspecified address
  //
  //  See IPAddress.IPv6.Unspecified for more information
  //
  public func is_unspecified() -> Bool {
    return self.host_address == BigUInt(0);
  }
  
  //  Returns true if the address is a loopback address
  //
  //  See IPAddress.IPv6.Loopback for more information
  //
  public func is_loopback() -> Bool {
    return (self.vt_is_loopback)(self);
  }
  
  
  //  Returns true if the address is a mapped address
  //
  //  See IPAddress.IPv6.Mapped for more information
  //
  public  func is_mapped() -> Bool {
    let ret = self.mapped != nil &&
      (self.host_address >> 32) == ((BigUInt(1) << 16) - BigUInt(1));
    // console.log("+++++++++++", self.mapped, ret);
    return ret;
  }
  
  
  //  Returns the prefix portion of the IPv4 object
  //  as a IPAddress.Prefix32 object
  //
  //    ip = IPAddress("172.16.100.4/22")
  //
  //    ip.prefix
  //      // => 22
  //
  //    ip.prefix.class
  //      // => IPAddress.Prefix32
  //
  // func prefix() -> Prefix {
  //     return self.prefix;
  // }
  
  
  // Checks if the argument is a valid IPv4 netmask
  // expressed in dotted decimal format.
  //
  //   IPAddress.valid_ipv4_netmask? "255.255.0.0"
  //     //=> true
  //
  public class func is_valid_netmask(_ addr: String) -> Bool {
    return IPAddress.parse_netmask_to_prefix(addr) != nil;
  }
  
  class func netmask_to_prefix(_ nm: BigUInt, _ bits: UInt8) -> UInt8? {
    var prefix : UInt8 = 0;
    var addr = nm;
    var in_host_part = true;
    // let two = BigUInt.two();
    for _ in 1...bits {
      let bit = addr % 2;
      // console.log(">>>", bits, bit, addr, nm);
      if (in_host_part && bit == 0) {
        prefix = prefix + 1;
      } else if (in_host_part && bit == 1) {
        in_host_part = false;
      } else if (!in_host_part && bit == 0) {
        return nil;
      }
      addr = addr >> 1
    }
    return bits - prefix;
  }
  
  
  public class func parse_netmask_to_prefix(_ netmask: String) -> UInt8? {
    // console.log("--1", netmask);
    let is_number = IPAddress.parse_dec_str(netmask);
    if (is_number != nil) {
      // console.log("--2", netmask, is_number);
      return UInt8(is_number!);
    }
    let my = IPAddress.parse(netmask);
    // console.log("--3", netmask, my);
    if (my == nil) {
      // console.log("--4", netmask, my);
      return nil;
    }
    // console.log("--5", netmask, my);
    return IPAddress.netmask_to_prefix(my!.host_address, my!.ip_bits.bits);
  }
  
  
  //  Set a new prefix Int for the object
  //
  //  This is useful if you want to change the prefix
  //  to an object created with IPv4.parse_u32 or
  //  if the object was created using the classful
  //  mask.
  //
  //    ip = IPAddress("172.16.100.4")
  //
  //    puts ip
  //      // => 172.16.100.4/16
  //
  //    ip.prefix = 22
  //
  //    puts ip
  //      // => 172.16.100.4/22
  //
  public func change_prefix(_ num: UInt8) -> IPAddress? {
    let prefix = self.prefix.from(num);
    if (prefix == nil) {
      return nil;
    }
    return self.from(self.host_address, prefix!);
  }
  
  public func change_netmask(_ str: String) -> IPAddress? {
    let nm = IPAddress.parse_netmask_to_prefix(str);
    if (nm == nil) {
      return nil;
    }
    return self.change_prefix(nm!);
  }
  
  //  Returns a string with the IP address in canonical
  //  form.
  //
  //    ip = IPAddress("172.16.100.4/22")
  //
  //    ip.to_string
  //      // => "172.16.100.4/22"
  //
  public func to_string() -> String {
    var ret = "";
    ret += self.to_s();
    ret += "/";
    ret += self.prefix.to_s();
    return ret;
  }
  
  public func to_s() -> String {
    return self.ip_bits.as_compressed_string(self.host_address);
  }
  
  public func to_string_uncompressed() -> String {
    var ret = "";
    ret += self.to_s_uncompressed();
    ret += "/";
    ret += self.prefix.to_s();
    return ret;
  }
  public func to_s_uncompressed() -> String {
    return self.ip_bits.as_uncompressed_string(self.host_address);
  }
  
  public func to_s_mapped() -> String {
    if (self.is_mapped()) {
      return "::ffff:\(self.mapped!.to_s())";
    }
    return self.to_s();
  }
  
  public func to_string_mapped() -> String {
    if (self.is_mapped()) {
      let mapped = self.mapped!.clone();
      return "\(self.to_s_mapped())/\(mapped.prefix.num)";
    }
    return self.to_string();
  }
  
  //  Returns the address portion of an IP in binary format,
  //  as a string containing a sequence of 0 and 1
  //
  //    ip = IPAddress("127.0.0.1")
  //
  //    ip.bits
  //      // => "01111111000000000000000000000001"
  //
  public func bits() -> String {
    let num = String(self.host_address, radix: 2);
    var ret = "";
    for _ in num.characters.count...Int(self.ip_bits.bits-1) {
      ret += "0";
    }
    ret += num;
    return ret;
  }
  public func to_hex() -> String {
    return String(self.host_address, radix: 16);
  }
  
  public func netmask() -> IPAddress {
    return self.from(self.prefix.netmask(), self.prefix);
  }
  
  //  Returns the broadcast address for the given IP.
  //
  //    ip = IPAddress("172.16.10.64/24")
  //
  //    ip.broadcast.to_s
  //      // => "172.16.10.255"
  //
  public func broadcast() -> IPAddress {
    return self.from(self.network().host_address + (self.size() - BigUInt(1)), self.prefix);
    // IPv4.parse_u32(self.broadcast_u32, self.prefix)
  }
  
  //  Checks if the IP address is actually a network
  //
  //    ip = IPAddress("172.16.10.64/24")
  //
  //    ip.network?
  //      // => false
  //
  //    ip = IPAddress("172.16.10.64/26")
  //
  //    ip.network?
  //      // => true
  //
  public func is_network() -> Bool {
    return self.prefix.num != self.ip_bits.bits &&
      self.host_address == self.network().host_address;
  }
  
  //  Returns a new IPv4 object with the network Int
  //  for the given IP.
  //
  //    ip = IPAddress("172.16.10.64/24")
  //
  //    ip.network.to_s
  //      // => "172.16.10.0"
  //
  public func network() -> IPAddress {
    return self.from(IPAddress.to_network(self.host_address, self.prefix.host_prefix()), self.prefix);
  }
  class func to_network(_ adr: BigUInt, _ host_prefix: UInt8) -> BigUInt {
    return (adr >> Int(host_prefix)) << Int(host_prefix);
  }
  
  public func sub(_ other: IPAddress) -> BigUInt {
    if (self.host_address > other.host_address) {
      return self.host_address - other.host_address;
    }
    return other.host_address - self.host_address;
  }
  
  public func add(_ other: IPAddress) -> [IPAddress] {
    return IPAddress.aggregate([self.clone(), other.clone()]);
  }
  
  public class func to_s_vec(_ vec: [IPAddress]) -> [String] {
    var ret: [String] = [String]();
    for i in vec {
      ret.append(i.to_s());
    }
    return ret;
  }
  
  public class func to_string_vec(_ vec: [IPAddress]) -> [String] {
    var ret: [String] = [String]();
    for i in vec {
      ret.append(i.to_string());
    }
    return ret;
  }
  public class func to_string_vec(_ vec: [IPAddress]?) -> [String] {
    return to_string_vec(vec!);
  }
  
  public class func to_ipaddress_vec(_ vec: [String]) -> [IPAddress]? {
    var ret: [IPAddress] = [IPAddress]();
    for ipstr in vec {
      let ipa = IPAddress.parse(ipstr);
      if (ipa == nil) {
        return nil;
      }
      ret.append(ipa!);
    }
    return ret;
  }
  
  //  Returns a new IPv4 object with the
  //  first host IP address in the range.
  //
  //  Example: given the 192.168.100.0/24 network, the first
  //  host IP address is 192.168.100.1.
  //
  //    ip = IPAddress("192.168.100.0/24")
  //
  //    ip.first.to_s
  //      // => "192.168.100.1"
  //
  //  The object IP doesn't need to be a network: the method
  //  automatically gets the network Int from it
  //
  //    ip = IPAddress("192.168.100.50/24")
  //
  //    ip.first.to_s
  //      // => "192.168.100.1"
  //
  public func first() -> IPAddress {
    return self.from(self.network().host_address + self.ip_bits.host_ofs, self.prefix);
  }
  
  //  Like its sibling method IPv4// first, this method
  //  returns a new IPv4 object with the
  //  last host IP address in the range.
  //
  //  Example: given the 192.168.100.0/24 network, the last
  //  host IP address is 192.168.100.254
  //
  //    ip = IPAddress("192.168.100.0/24")
  //
  //    ip.last.to_s
  //      // => "192.168.100.254"
  //
  //  The object IP doesn't need to be a network: the method
  //  automatically gets the network Int from it
  //
  //    ip = IPAddress("192.168.100.50/24")
  //
  //    ip.last.to_s
  //      // => "192.168.100.254"
  //
  public func last() -> IPAddress {
    return self.from(self.broadcast().host_address - self.ip_bits.host_ofs, self.prefix);
  }
  
  //  Iterates over all the hosts IP addresses for the given
  //  network (or IP address).
  //
  //    ip = IPAddress("10.0.0.1/29")
  //
  //    ip.each_host do |i|
  //      p i.to_s
  //    end
  //      // => "10.0.0.1"
  //      // => "10.0.0.2"
  //      // => "10.0.0.3"
  //      // => "10.0.0.4"
  //      // => "10.0.0.5"
  //      // => "10.0.0.6"
  //
  public func each_host(_ fn: EachFn) {
    var i = self.first().host_address;
    while (i <= self.last().host_address) {
      fn(self.from(i, self.prefix));
      i = i + BigUInt(1);
    }
  }
  
  public func inc() -> IPAddress? {
    let ret = self.clone();
    ret.host_address = ret.host_address + BigUInt(1);
    if (ret.lte(self.last())) {
      return ret;
    }
    return nil;
  }
  
  public func dec() -> IPAddress? {
    let ret = self.clone();
    ret.host_address = ret.host_address - BigUInt(1);
    if (ret.lte(self.first())) {
      return ret;
    }
    return nil;
  }
  
  //  Iterates over all the IP addresses for the given
  //  network (or IP address).
  //
  //  The object yielded is a new IPv4 object created
  //  from the iteration.
  //
  //    ip = IPAddress("10.0.0.1/29")
  //
  //    ip.each do |i|
  //      p i.address
  //    end
  //      // => "10.0.0.0"
  //      // => "10.0.0.1"
  //      // => "10.0.0.2"
  //      // => "10.0.0.3"
  //      // => "10.0.0.4"
  //      // => "10.0.0.5"
  //      // => "10.0.0.6"
  //      // => "10.0.0.7"
  //
  public func each(_ fn: EachFn) {
    var i = self.network().host_address;
    while (i <= self.broadcast().host_address) {
      fn(self.from(i, self.prefix));
      i = i + BigUInt(1);
    }
  }
  
  //  Spaceship operator to compare IPv4 objects
  //
  //  Comparing IPv4 addresses is useful to ordinate
  //  them into lists that match our intuitive
  //  perception of ordered IP addresses.
  //
  //  The first comparison criteria is the u32 value.
  //  For example, 10.100.100.1 will be considered
  //  to be less than 172.16.0.1, because, in a ordered list,
  //  we expect 10.100.100.1 to come before 172.16.0.1.
  //
  //  The second criteria, in case two IPv4 objects
  //  have identical addresses, is the prefix. An higher
  //  prefix will be considered greater than a lower
  //  prefix. This is because we expect to see
  //  10.100.100.0/24 come before 10.100.100.0/25.
  //
  //  Example:
  //
  //    ip1 = IPAddress "10.100.100.1/8"
  //    ip2 = IPAddress "172.16.0.1/16"
  //    ip3 = IPAddress "10.100.100.1/16"
  //
  //    ip1 < ip2
  //      // => true
  //    ip1 > ip3
  //      // => false
  //
  //    [ip1,ip2,ip3].sort.map{|i| i.to_string}
  //      // => ["10.100.100.1/8","10.100.100.1/16","172.16.0.1/16"]
  //
  
  //  Returns the Int of IP addresses included
  //  in the network. It also counts the network
  //  address and the broadcast address.
  //
  //    ip = IPAddress("10.0.0.1/29")
  //
  //    ip.size
  //      // => 8
  //
  public func size() -> BigUInt {
    return BigUInt(1) << Int(self.prefix.host_prefix());
  }
  public func is_same_kind(_ oth: IPAddress) -> Bool {
    return self.is_ipv4() == oth.is_ipv4() &&
      self.is_ipv6() == oth.is_ipv6();
  }
  
  //  Checks whether a subnet includes the given IP address.
  //
  //  Accepts an IPAddress.IPv4 object.
  //
  //    ip = IPAddress("192.168.10.100/24")
  //
  //    addr = IPAddress("192.168.10.102/24")
  //
  //    ip.include? addr
  //      // => true
  //
  //    ip.include? IPAddress("172.16.0.48/16")
  //      // => false
  //
  public func includes(_ oth: IPAddress) -> Bool {
    let ret = self.is_same_kind(oth) &&
      self.prefix.num <= oth.prefix.num &&
      self.network().host_address == IPAddress.to_network(oth.host_address, self.prefix.host_prefix());
    // println!("includes:{}=={}=>{}", self.to_string(), oth.to_string(), ret);
    return ret
  }
  
  //  Checks whether a subnet includes all the
  //  given IPv4 objects.
  //
  //    ip = IPAddress("192.168.10.100/24")
  //
  //    addr1 = IPAddress("192.168.10.102/24")
  //    addr2 = IPAddress("192.168.10.103/24")
  //
  //    ip.include_all?(addr1,addr2)
  //      // => true
  //
  public func includes_all(_ oths: [IPAddress]) -> Bool {
    for oth in oths {
      if (!self.includes(oth)) {
        return false;
      }
    }
    return true;
  }
  //  Checks if an IPv4 address objects belongs
  //  to a private network RFC1918
  //
  //  Example:
  //
  //    ip = IPAddress "10.1.1.1/24"
  //    ip.private?
  //      // => true
  //
  public func is_private() -> Bool {
    return self.vt_is_private(self);
  }
  
  
  //  Splits a network into different subnets
  //
  //  If the IP Address is a network, it can be divided into
  //  multiple networks. If +self+ is not a network, this
  //  method will calculate the network from the IP and then
  //  subnet it.
  //
  //  If +subnets+ is an power of two Int, the resulting
  //  networks will be divided evenly from the supernet.
  //
  //    network = IPAddress("172.16.10.0/24")
  //
  //    network / 4   //  implies map{|i| i.to_string}
  //      // => ["172.16.10.0/26",
  //           "172.16.10.64/26",
  //           "172.16.10.128/26",
  //           "172.16.10.192/26"]
  //
  //  If +num+ is any other Int, the supernet will be
  //  divided into some networks with a even Int of hosts and
  //  other networks with the remaining addresses.
  //
  //    network = IPAddress("172.16.10.0/24")
  //
  //    network / 3   //  implies map{|i| i.to_string}
  //      // => ["172.16.10.0/26",
  //           "172.16.10.64/26",
  //           "172.16.10.128/25"]
  //
  //  Returns an array of IPv4 objects
  //
  func sum_first_found(_ arr: [IPAddress]) -> [IPAddress] {
    var dup = arr.clone();
    if (dup.count < 2) {
      return dup;
    }
    for i in stride(from: dup.count - 2, to: 0, by: -1) {
      // console.log("sum_first_found:", dup[i], dup[i + 1]);
      let a = IPAddress.summarize([dup[i], dup[i + 1]]);
      // println!("dup:{}:{}:{}", dup.count, i, a.count);
      if (a!.count == 1) {
        dup[i] = a![0];
        dup = Array(dup[0...(i)] + dup.dropFirst(i + 2));
        break;
      }
    }
    return dup;
  }
  public func split(_ subnets: UInt) -> [IPAddress]? {
    if (subnets == 0 || (1 << UInt(self.prefix.host_prefix())) <= subnets) {
      return nil;
    }
    let networks = self.subnet(self.newprefix(UInt8(subnets))!.num);
    if (networks == nil) {
      return networks;
    }
    var net = networks!;
    while (net.count != Int(subnets)) {
      net = self.sum_first_found(net);
    }
    return net;
  }
  // alias_method :/, :split
  
  //  Returns a new IPv4 object from the supernetting
  //  of the instance network.
  //
  //  Supernetting is similar to subnetting, except
  //  that you getting as a result a network with a
  //  smaller prefix (bigger host space). For example,
  //  given the network
  //
  //    ip = IPAddress("172.16.10.0/24")
  //
  //  you can supernet it with a new /23 prefix
  //
  //    ip.supernet(23).to_string
  //      // => "172.16.10.0/23"
  //
  //  However if you supernet it with a /22 prefix, the
  //  network address will change:
  //
  //    ip.supernet(22).to_string
  //      // => "172.16.8.0/22"
  //
  //  If +new_prefix+ is less than 1, returns 0.0.0.0/0
  //
  public func supernet(_ new_prefix: UInt8) -> IPAddress? {
    if (new_prefix >= self.prefix.num) {
      return nil;
    }
    // let new_ip = self.host_address.clone();
    // for _ in new_prefix..self.prefix.num {
    //     new_ip = new_ip << 1;
    // }
    return self.from(self.host_address, self.prefix.from(new_prefix)!).network();
  }
  
  //  This method implements the subnetting function
  //  similar to the one described in RFC3531.
  //
  //  By specifying a new prefix, the method calculates
  //  the network Int for the given IPv4 object
  //  and calculates the subnets associated to the new
  //  prefix.
  //
  //  For example, given the following network:
  //
  //    ip = IPAddress "172.16.10.0/24"
  //
  //  we can calculate the subnets with a /26 prefix
  //
  //    ip.subnets(26).map(:to_string)
  //      // => ["172.16.10.0/26", "172.16.10.64/26",
  //           "172.16.10.128/26", "172.16.10.192/26"]
  //
  //  The resulting Int of subnets will of course always be
  //  a power of two.
  //
  public func subnet(_ subprefix: UInt8) -> [IPAddress]? {
    if (subprefix < self.prefix.num || self.ip_bits.bits < subprefix) {
      return nil;
    }
    var ret: [IPAddress] = [];
    var net = self.network();
    net.prefix = net.prefix.from(subprefix)!;
    for _ in 1...(1 << Int(subprefix - self.prefix.num)) {
      ret.append(net.clone());
      net = net.from(net.host_address, net.prefix);
      let size = net.size();
      net.host_address = net.host_address + size;
    }
    return ret;
  }
  
  //  Return the ip address in a format compatible
  //  with the IPv6 Mapped IPv4 addresses
  //
  //  Example:
  //
  //    ip = IPAddress("172.16.10.1/24")
  //
  //    ip.to_ipv6
  //      // => "ac10:0a01"
  //
  public func to_ipv6() -> IPAddress {
    return self.vt_to_ipv6(self);
  }
  
  public func newprefix(_ num: UInt8) -> Prefix? {
    for i in num...self.ip_bits.bits-1 {
      let a = Float(Int(log2(Float(i))));
      if (a == log2(Float(i))) {
        return self.prefix.add(UInt8(a));
      }
    }
    return nil
  }
  
  
}
