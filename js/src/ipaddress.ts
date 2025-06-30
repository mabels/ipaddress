import Prefix from "./prefix.js";
import IpBits from "./ip_bits.js";
import IpVersion from "./ip_version.js";
import Ipv4 from "./ipv4.js";
import Ipv6 from "./ipv6.js";
import Ipv6Mapped from "./ipv6_mapped.js";

import Crunchy from "./crunchy.js";

export type Is = (source: IPAddress) => boolean;

export type ToIpv4 = (source: IPAddress) => IPAddress;

export type EachFn = (source: IPAddress) => void;

export class ResultCrunchyParts {
  public crunchy: Crunchy;
  public parts: number;

  constructor(crunchy: Crunchy, parts: number) {
    this.crunchy = crunchy;
    this.parts = parts;
    // console.log("ResultCrunchyParts:", this);
  }
}

export interface IPAddressParams {
  ip_bits: IpBits;
  host_address: Crunchy;
  prefix: Prefix;
  mapped?: IPAddress;
  vt_is_private?: Is;
  vt_is_loopback?: Is;
  vt_to_ipv6?: ToIpv4;
}

export class IPAddress {
  ip_bits: IpBits;
  host_address: Crunchy;
  prefix: Prefix;
  mapped: IPAddress;
  vt_is_private: Is;
  vt_is_loopback: Is;
  vt_to_ipv6: ToIpv4;

  constructor(obj: IPAddressParams) {
    this.ip_bits = obj.ip_bits;
    this.host_address = obj.host_address;
    this.prefix = obj.prefix;
    this.mapped = obj.mapped;
    this.vt_is_private = obj.vt_is_private;
    this.vt_is_loopback = obj.vt_is_loopback;
    this.vt_to_ipv6 = obj.vt_to_ipv6;
  }

  public clone(): IPAddress {
    let mapped: IPAddress = null;
    if (this.mapped) {
      mapped = this.mapped.clone();
    }
    return new IPAddress({
      ip_bits: this.ip_bits.clone(),
      host_address: this.host_address.clone(),
      prefix: this.prefix.clone(),
      mapped,
      vt_is_private: this.vt_is_private,
      vt_is_loopback: this.vt_is_loopback,
      vt_to_ipv6: this.vt_to_ipv6,
    });
  }

  public lt(oth: IPAddress): boolean {
    return this.cmp(oth) < 0;
  }

  public lte(oth: IPAddress): boolean {
    return this.cmp(oth) <= 0;
  }

  public gt(oth: IPAddress): boolean {
    return this.cmp(oth) > 0;
  }

  public gte(oth: IPAddress): boolean {
    return this.cmp(oth) >= 0;
  }

  public cmp(oth: IPAddress): number {
    if (this.ip_bits.version != oth.ip_bits.version) {
      if (this.ip_bits.version == IpVersion.V6) {
        return 1;
      }
      return -1;
    }
    // let adr_diff = this.host_address - oth.host_address;
    const hostCmp = this.host_address.compare(oth.host_address);
    if (hostCmp != 0) {
      return hostCmp;
    }
    return this.prefix.cmp(oth.prefix);
  }

  public eq(other: IPAddress): boolean {
    // if (!!this.mapped != !!this.mapped) {
    //     return false;
    // }
    // if (this.mapped) {
    //     if (!this.mapped.eq(other.mapped)) {
    //         return false;
    //     }
    // }
    // console.log("************", this);
    return (
      this.ip_bits.version == other.ip_bits.version &&
      this.prefix.eq(other.prefix) &&
      this.host_address.eq(other.host_address)
    );
  }

  public ne(other: IPAddress): boolean {
    return !this.eq(other);
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
  public static parse(str: string): IPAddress {
    const re_mapped = new RegExp(":.+\\.");
    // const re_ipv4 = new RegExp('\\.')
    // const re_ipv6 = new RegExp(':')
    if (re_mapped.test(str)) {
      // console.log("mapped:", str);
      return Ipv6Mapped.create(str);
    } else {
      if (str.includes(".")) {
        // console.log("ipv4:", str);
        return Ipv4.create(str);
      } else if (str.includes(":")) {
        // console.log("ipv6:", str);
        return Ipv6.create(str);
      }
    }
    return null;
  }

  public static split_at_slash(str: string): [string, string] {
    const slash: string[] = str.trim().split("/");
    let addr = "";
    if (slash[0]) {
      addr += slash[0].trim();
    }
    if (slash[1]) {
      return [addr, slash[1].trim()];
    } else {
      return [addr, null];
    }
  }

  public from(addr: Crunchy, prefix: Prefix): IPAddress {
    let mapped: IPAddress = null;
    if (this.mapped) {
      mapped = this.mapped.clone();
    }
    return new IPAddress({
      ip_bits: this.ip_bits,
      host_address: addr.clone(),
      prefix: prefix.clone(),
      mapped,
      vt_is_private: this.vt_is_private,
      vt_is_loopback: this.vt_is_loopback,
      vt_to_ipv6: this.vt_to_ipv6,
    });
  }

  // True if the object is an IPv4 address
  //
  //   ip = IPAddress("192.168.10.100/24")
  //
  //   ip.ipv4?
  //     //-> true
  //
  public is_ipv4(): boolean {
    return this.ip_bits.version == IpVersion.V4;
  }

  // True if the object is an IPv6 address
  //
  //   ip = IPAddress("192.168.10.100/24")
  //
  //   ip.ipv6?
  //     //-> false
  //
  public is_ipv6(): boolean {
    return this.ip_bits.version == IpVersion.V6;
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
  public static is_valid(addr: string): boolean {
    return IPAddress.is_valid_ipv4(addr) || IPAddress.is_valid_ipv6(addr);
  }

  public static parse_dec_str(str: string): number {
    const re_digit = new RegExp("^\\d+$");
    if (!re_digit.test(str)) {
      // console.log("parse_dec_str:-1:", str);
      return null;
    }
    const part = parseInt(str, 10);
    if (isNaN(part)) {
      // console.log("parse_dec_str:-2:", str, part);
      return null;
    }
    // console.log("parse_dec_str:-3:", str, part);
    return part;
  }

  public static parse_hex_str(str: string): number {
    const re_digit = new RegExp("^[0-9a-fA-F]+$");
    if (!re_digit.test(str)) {
      return null;
    }
    const part = parseInt(str, 16);
    if (isNaN(part)) {
      return null;
    }
    return part;
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
  public static parse_ipv4_part(i: string): number {
    const part = IPAddress.parse_dec_str(i);
    // console.log("i=", i, part);
    if (part === null || part >= 256) {
      return null;
    }
    return part;
  }

  public static split_to_u32(addr: string): Crunchy {
    let ip = Crunchy.zero();
    let shift = 24;
    let split_addr = addr.split(".");
    if (split_addr.length > 4) {
      return null;
    }
    const split_addr_len = split_addr.length;
    if (split_addr_len >= 1 && split_addr_len < 4) {
      const part = IPAddress.parse_ipv4_part(split_addr[split_addr_len - 1]);
      if (part === null) {
        return null;
      }
      ip = Crunchy.from_number(part);
      split_addr = split_addr.slice(0, split_addr_len - 1);
    }
    for (const i of split_addr) {
      const part = IPAddress.parse_ipv4_part(i);
      // console.log("u32-", addr, i, part);
      if (part === null) {
        return null;
      }
      // println!("{}-{}", part_num, shift);
      ip = ip.add(Crunchy.from_number(part).shl(shift));
      shift -= 8;
    }
    return ip;
  }

  public static is_valid_ipv4(addr: string): boolean {
    return IPAddress.split_to_u32(addr) !== null;
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
  public static split_on_colon(addr: string): ResultCrunchyParts {
    const parts = addr.trim().split(":");
    let ip = Crunchy.zero();
    if (parts.length == 1 && parts[0].length == 0) {
      return new ResultCrunchyParts(ip, 0);
    }
    const parts_len = parts.length;
    let shift = (parts_len - 1) * 16;
    for (const i of parts) {
      // println!("{}={}", addr, i);
      const part = IPAddress.parse_hex_str(i);
      if (part === null || part >= 65536) {
        return null;
      }
      ip = ip.add(Crunchy.from_number(part).shl(shift));
      shift -= 16;
    }
    return new ResultCrunchyParts(ip, parts_len);
  }

  public static split_to_num(addr: string): ResultCrunchyParts {
    // let ip = 0;
    const pre_post = addr.trim().split("::");
    if (pre_post.length > 2) {
      return null;
    }
    if (pre_post.length == 2) {
      // println!("{}=.={}", pre_post[0], pre_post[1]);
      const pre = IPAddress.split_on_colon(pre_post[0]);
      if (!pre) {
        return pre;
      }
      const post = IPAddress.split_on_colon(pre_post[1]);
      if (!post) {
        return post;
      }
      // println!("pre:{} post:{}", pre_parts, post_parts);
      return new ResultCrunchyParts(
        pre.crunchy.shl(128 - pre.parts * 16).add(post.crunchy),
        128 / 16,
      );
    }
    // println!("split_to_num:no double:{}", addr);
    const ret = IPAddress.split_on_colon(addr);
    if (ret == null || ret.parts != 128 / 16) {
      return null;
    }
    return ret;
  }

  public static is_valid_ipv6(addr: string): boolean {
    return IPAddress.split_to_num(addr) != null;
  }

  // private helper for summarize
  // assumes that networks is output from reduce_networks
  // means it should be sorted lowers first and uniq
  //

  public static pos_to_idx(pos: number, len: number): number {
    const ilen = len;
    // let ret = pos % ilen;
    const rem = ((pos % ilen) + ilen) % ilen;
    // println!("pos_to_idx:{}:{}=>{}:{}", pos, len, ret, rem);
    return rem;
  }

  public static aggregate(networks: IPAddress[]): IPAddress[] {
    if (networks.length == 0) {
      return [];
    }
    if (networks.length == 1) {
      // console.log("aggregate:", networks[0], networks[0].network());
      return [networks[0].network()];
    }
    let stack = networks.map((i) => i.network()).sort((a, b) => a.cmp(b));
    // console.log(IPAddress.to_string_vec(stack));
    // for i in 0..networks.length {
    //     println!("{}==={}", &networks[i].to_string_uncompressed(),
    //         &stack[i].to_string_uncompressed());
    // }
    // eslint-disable-next-line no-constant-condition
    for (let pos = 0; true; ) {
      if (pos < 0) {
        pos = 0;
      }
      const stack_len = stack.length; // borrow checker
      // println!("loop:{}:{}", pos, stack_len);
      // if stack_len == 1 {
      //     println!("exit 1");
      //     break;
      // }
      if (pos >= stack_len) {
        // println!("exit first:{}:{}", stack_len, pos);
        break;
      }
      const first = IPAddress.pos_to_idx(pos, stack_len);
      pos = pos + 1;
      if (pos >= stack_len) {
        // println!("exit second:{}:{}", stack_len, pos);
        break;
      }
      const second = IPAddress.pos_to_idx(pos, stack_len);
      pos = pos + 1;
      // let firstUnwrap = first;
      if (stack[first].includes(stack[second])) {
        pos = pos - 2;
        // println!("remove:1:{}:{}:{}=>{}", first, second, stack_len, pos + 1);
        const pidx = IPAddress.pos_to_idx(pos + 1, stack_len);
        stack = stack.slice(0, pidx).concat(stack.slice(pidx + 1));
      } else {
        stack[first].prefix = stack[first].prefix.sub(1);
        // println!("complex:{}:{}:{}:{}:P1:{}:P2:{}", pos, stack_len,
        // first, second,
        // stack[first].to_string(), stack[second].to_string());
        if (
          stack[first].prefix.num + 1 == stack[second].prefix.num &&
          stack[first].includes(stack[second])
        ) {
          pos = pos - 2;
          const idx = IPAddress.pos_to_idx(pos, stack_len);
          stack[idx] = stack[first].clone(); // kaputt
          const pidx = IPAddress.pos_to_idx(pos + 1, stack_len);
          stack = stack.slice(0, pidx).concat(stack.slice(pidx + 1));
          // println!("remove-2:{}:{}", pos + 1, stack_len);
          pos = pos - 1; // backtrack
        } else {
          stack[first].prefix = stack[first].prefix.add(1); // reset prefix
          // println!("easy:{}:{}=>{}", pos, stack_len, stack[first].to_string());
          pos = pos - 1; // do it with second as first
        }
      }
    }
    // println!("agg={}:{}", pos, stack.length);
    return stack.slice(0, stack.length);
  }

  public parts(): number[] {
    return this.ip_bits.parts(this.host_address);
  }

  public parts_hex_str(): string[] {
    const ret: string[] = [];
    const leading = 1 << this.ip_bits.part_bits;
    for (const i of this.parts()) {
      ret.push((leading + i).toString(16).slice(1));
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
  public dns_rev_domains(): string[] {
    const ret: string[] = [];
    for (const net of this.dns_networks()) {
      // console.log("dns_rev_domains:", this.to_string(), net.to_string());
      ret.push(net.dns_reverse());
    }
    return ret;
  }

  public dns_reverse(): string {
    let ret = "";
    let dot = "";
    const dns_parts = this.dns_parts();
    for (
      let i = ~~(
        (this.prefix.host_prefix() + (this.ip_bits.dns_bits - 1)) /
        this.ip_bits.dns_bits
      );
      i < this.dns_parts().length;
      ++i
    ) {
      // console.log("dns_r", i);
      ret += dot;
      ret += this.ip_bits.dns_part_format(dns_parts[i]);
      dot = ".";
    }
    ret += dot;
    ret += this.ip_bits.rev_domain;
    return ret;
  }

  public dns_parts(): number[] {
    const ret: number[] = [];
    let num = this.host_address.clone();
    const mask = Crunchy.one().shl(this.ip_bits.dns_bits);
    for (let _ = 0; _ < this.ip_bits.bits / this.ip_bits.dns_bits; _++) {
      const part = +num.clone().mod(mask).toString();
      num = num.shr(this.ip_bits.dns_bits);
      ret.push(part);
    }
    return ret;
  }

  public dns_networks(): IPAddress[] {
    // +this.ip_bits.dns_bits-1
    const next_bit_mask =
      this.ip_bits.bits -
      ~~(this.prefix.host_prefix() / this.ip_bits.dns_bits) *
        this.ip_bits.dns_bits;
    // console.log("dns_networks-1", this.to_string(), this.prefix.host_prefix();j
    // this.ip_bits.dns_bits, next_bit_mask);
    if (next_bit_mask <= 0) {
      return [this.network()];
    }
    //  println!("dns_networks:{}:{}", this.to_string(), next_bit_mask);
    // dns_bits
    const step_bit_net = Crunchy.one().shl(this.ip_bits.bits - next_bit_mask);
    if (step_bit_net.eq(Crunchy.zero())) {
      // console.log("dns_networks-2", this.to_string());
      return [this.network()];
    }
    const ret: IPAddress[] = [];
    let step = this.network().host_address;
    const prefix = this.prefix.from(next_bit_mask);
    while (step.lte(this.broadcast().host_address)) {
      // console.log("dns_networks-3", this.to_string(), step.toString(), next_bit_mask, step_bit_net.toString());
      ret.push(this.from(step, prefix));
      step = step.add(step_bit_net);
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
  public static summarize(networks: IPAddress[]): IPAddress[] {
    return IPAddress.aggregate(networks);
  }

  public static summarize_str(netstr: string[]): IPAddress[] {
    const vec = IPAddress.to_ipaddress_vec(netstr);
    // console.log(netstr, vec);
    if (!vec) {
      return vec;
    }
    return IPAddress.aggregate(vec);
  }

  public ip_same_kind(oth: IPAddress): boolean {
    return this.ip_bits.version == oth.ip_bits.version;
  }

  //  Returns true if the address is an unspecified address
  //
  //  See IPAddress.IPv6.Unspecified for more information
  //
  public is_unspecified(): boolean {
    return this.host_address.eq(Crunchy.zero());
  }

  //  Returns true if the address is a loopback address
  //
  //  See IPAddress.IPv6.Loopback for more information
  //
  public is_loopback(): boolean {
    return this.vt_is_loopback(this);
  }

  //  Returns true if the address is a mapped address
  //
  //  See IPAddress.IPv6.Mapped for more information
  //
  public is_mapped(): boolean {
    const ret =
      this.mapped !== null &&
      this.host_address.shr(32).eq(Crunchy.one().shl(16).sub(Crunchy.one()));
    // console.log("+++++++++++", this.mapped, ret);
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
  // public prefix(): Prefix {
  //     return this.prefix;
  // }

  // Checks if the argument is a valid IPv4 netmask
  // expressed in dotted decimal format.
  //
  //   IPAddress.valid_ipv4_netmask? "255.255.0.0"
  //     //=> true
  //
  public static is_valid_netmask(addr: string): boolean {
    return IPAddress.parse_netmask_to_prefix(addr) !== null;
  }

  public static netmask_to_prefix(nm: Crunchy, bits: number): number {
    let prefix = 0;
    let addr = nm.clone();
    let in_host_part = true;
    // let two = Crunchy.two();
    for (let _ = 0; _ < bits; _++) {
      const bit = addr.mds(2);
      // console.log(">>>", bits, bit, addr, nm);
      if (in_host_part && bit == 0) {
        prefix = prefix + 1;
      } else if (in_host_part && bit == 1) {
        in_host_part = false;
      } else if (!in_host_part && bit == 0) {
        return null;
      }
      addr = addr.shr(1);
    }
    return bits - prefix;
  }

  public static parse_netmask_to_prefix(netmask: string): number {
    // console.log("--1", netmask);
    const is_number = IPAddress.parse_dec_str(netmask);
    if (is_number !== null) {
      // console.log("--2", netmask, is_number);
      return is_number;
    }
    const my = IPAddress.parse(netmask);
    // console.log("--3", netmask, my);
    if (!my) {
      // console.log("--4", netmask, my);
      return null;
    }
    // console.log("--5", netmask, my);
    const my_ip = my;
    return IPAddress.netmask_to_prefix(my_ip.host_address, my_ip.ip_bits.bits);
  }

  //  Set a new prefix number for the object
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
  public change_prefix(num: number): IPAddress {
    const prefix = this.prefix.from(num);
    if (!prefix) {
      return null;
    }
    return this.from(this.host_address, prefix);
  }

  public change_netmask(str: string): IPAddress {
    const nm = IPAddress.parse_netmask_to_prefix(str);
    if (!nm) {
      return null;
    }
    return this.change_prefix(nm);
  }

  //  Returns a string with the IP address in canonical
  //  form.
  //
  //    ip = IPAddress("172.16.100.4/22")
  //
  //    ip.to_string
  //      // => "172.16.100.4/22"
  //
  public to_string(): string {
    let ret = "";
    ret += this.to_s();
    ret += "/";
    ret += this.prefix.to_s();
    return ret;
  }

  public to_s(): string {
    return this.ip_bits.as_compressed_string(this.host_address);
  }

  public to_string_uncompressed(): string {
    let ret = "";
    ret += this.to_s_uncompressed();
    ret += "/";
    ret += this.prefix.to_s();
    return ret;
  }

  public to_s_uncompressed(): string {
    return this.ip_bits.as_uncompressed_string(this.host_address);
  }

  public to_s_mapped(): string {
    if (this.is_mapped()) {
      return `::ffff:${this.mapped.to_s()}`;
    }
    return this.to_s();
  }

  public to_string_mapped(): string {
    if (this.is_mapped()) {
      const mapped = this.mapped.clone();
      return `${this.to_s_mapped()}/${mapped.prefix.num}`;
    }
    return this.to_string();
  }

  //  Returns the address portion of an IP in binary format,
  //  as a string containing a sequence of 0 and 1
  //
  //    ip = IPAddress("127.0.0.1")
  //
  //    ip.bits
  //      // => "01111111000000000000000000000001"
  //
  public bits(): string {
    const num = this.host_address.toString(2);
    let ret = "";
    for (let _ = num.length; _ < this.ip_bits.bits; _++) {
      ret += "0";
    }
    ret += num;
    return ret;
  }

  public to_hex(): string {
    return this.host_address.toString(16);
  }

  public netmask(): IPAddress {
    return this.from(this.prefix.netmask(), this.prefix);
  }

  //  Returns the broadcast address for the given IP.
  //
  //    ip = IPAddress("172.16.10.64/24")
  //
  //    ip.broadcast.to_s
  //      // => "172.16.10.255"
  //
  public broadcast(): IPAddress {
    return this.from(
      this.network().host_address.add(this.size().sub(Crunchy.one())),
      this.prefix,
    );
    // IPv4.parse_u32(this.broadcast_u32, this.prefix)
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
  public is_network(): boolean {
    return (
      this.prefix.num != this.ip_bits.bits &&
      this.host_address.eq(this.network().host_address)
    );
  }

  //  Returns a new IPv4 object with the network number
  //  for the given IP.
  //
  //    ip = IPAddress("172.16.10.64/24")
  //
  //    ip.network.to_s
  //      // => "172.16.10.0"
  //
  public network(): IPAddress {
    return this.from(
      IPAddress.to_network(this.host_address, this.prefix.host_prefix()),
      this.prefix,
    );
  }

  public static to_network(adr: Crunchy, host_prefix: number): Crunchy {
    return adr.shr(host_prefix).shl(host_prefix);
  }

  public sub(other: IPAddress): Crunchy {
    if (this.host_address.gt(other.host_address)) {
      return this.host_address.clone().sub(other.host_address);
    }
    return other.host_address.clone().sub(this.host_address);
  }

  public add(other: IPAddress): IPAddress[] {
    return IPAddress.aggregate([this.clone(), other.clone()]);
  }

  public static to_s_vec(vec: IPAddress[]): string[] {
    const ret: string[] = [];
    for (const i of vec) {
      ret.push(i.to_s());
    }
    return ret;
  }

  public static to_string_vec(vec: IPAddress[]): string[] {
    const ret: string[] = [];
    for (const i of vec) {
      ret.push(i.to_string());
    }
    return ret;
  }

  public static to_ipaddress_vec(vec: string[]): IPAddress[] {
    const ret: IPAddress[] = [];
    for (const ipstr of vec) {
      const ipa = IPAddress.parse(ipstr);
      if (!ipa) {
        return null;
      }
      ret.push(ipa);
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
  //  automatically gets the network number from it
  //
  //    ip = IPAddress("192.168.100.50/24")
  //
  //    ip.first.to_s
  //      // => "192.168.100.1"
  //
  public first(): IPAddress {
    return this.from(
      this.network().host_address.add(this.ip_bits.host_ofs),
      this.prefix,
    );
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
  //  automatically gets the network number from it
  //
  //    ip = IPAddress("192.168.100.50/24")
  //
  //    ip.last.to_s
  //      // => "192.168.100.254"
  //
  public last(): IPAddress {
    return this.from(
      this.broadcast().host_address.sub(this.ip_bits.host_ofs),
      this.prefix,
    );
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
  public each_host(func: EachFn) {
    let i = this.first().host_address;
    while (i.lte(this.last().host_address)) {
      func(this.from(i, this.prefix));
      i = i.add(Crunchy.one());
    }
  }

  public inc(): IPAddress {
    const ret = this.clone();
    ret.host_address = ret.host_address.add(Crunchy.one());
    if (ret.lte(this.last())) {
      return ret;
    }
    return null;
  }

  public dec(): IPAddress {
    const ret = this.clone();
    ret.host_address = ret.host_address.sub(Crunchy.one());
    if (ret.gte(this.first())) {
      return ret;
    }
    return null;
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
  public each(func: EachFn) {
    let i = this.network().host_address;
    while (i.lte(this.broadcast().host_address)) {
      func(this.from(i, this.prefix));
      i = i.add(Crunchy.one());
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

  //  Returns the number of IP addresses included
  //  in the network. It also counts the network
  //  address and the broadcast address.
  //
  //    ip = IPAddress("10.0.0.1/29")
  //
  //    ip.size
  //      // => 8
  //
  public size(): Crunchy {
    return Crunchy.one().shl(this.prefix.host_prefix());
  }

  public is_same_kind(oth: IPAddress): boolean {
    return this.is_ipv4() == oth.is_ipv4() && this.is_ipv6() == oth.is_ipv6();
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
  public includes(oth: IPAddress): boolean {
    const ret =
      this.is_same_kind(oth) &&
      this.prefix.num <= oth.prefix.num &&
      this.network().host_address.eq(
        IPAddress.to_network(oth.host_address, this.prefix.host_prefix()),
      );
    // println!("includes:{}=={}=>{}", this.to_string(), oth.to_string(), ret);
    return ret;
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
  public includes_all(oths: IPAddress[]): boolean {
    for (const oth of oths) {
      if (!this.includes(oth)) {
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
  public is_private(): boolean {
    return this.vt_is_private(this);
  }

  //  Splits a network into different subnets
  //
  //  If the IP Address is a network, it can be divided into
  //  multiple networks. If +self+ is not a network, this
  //  method will calculate the network from the IP and then
  //  subnet it.
  //
  //  If +subnets+ is an power of two number, the resulting
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
  //  If +num+ is any other number, the supernet will be
  //  divided into some networks with a even number of hosts and
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
  public sum_first_found(arr: IPAddress[]): IPAddress[] {
    let dup = arr.slice();
    if (dup.length < 2) {
      return dup;
    }
    for (let i = dup.length - 2; i >= 0; --i) {
      // console.log("sum_first_found:", dup[i], dup[i + 1]);
      const a = IPAddress.summarize([dup[i], dup[i + 1]]);
      // println!("dup:{}:{}:{}", dup.length, i, a.length);
      if (a.length == 1) {
        dup[i] = a[0];
        dup = dup.slice(0, i + 1).concat(dup.slice(i + 2));
        break;
      }
    }
    return dup;
  }

  public split(subnets: number): IPAddress[] {
    if (subnets == 0 || 1 << this.prefix.host_prefix() <= subnets) {
      return null;
    }
    const networks = this.subnet(this.newprefix(subnets).num);
    if (!networks) {
      return networks;
    }
    let net = networks;
    while (net.length != subnets) {
      net = this.sum_first_found(net);
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
  public supernet(new_prefix: number): IPAddress {
    if (new_prefix >= this.prefix.num) {
      return null;
    }
    // let new_ip = this.host_address.clone();
    // for _ in new_prefix..this.prefix.num {
    //     new_ip = new_ip << 1;
    // }
    return this.from(this.host_address, this.prefix.from(new_prefix)).network();
  }

  //  This method implements the subnetting function
  //  similar to the one described in RFC3531.
  //
  //  By specifying a new prefix, the method calculates
  //  the network number for the given IPv4 object
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
  //  The resulting number of subnets will of course always be
  //  a power of two.
  //
  public subnet(subprefix: number): IPAddress[] {
    if (subprefix < this.prefix.num || this.ip_bits.bits < subprefix) {
      return null;
    }
    const ret: IPAddress[] = [];
    let net = this.network();
    net.prefix = net.prefix.from(subprefix);
    for (let _ = 0; _ < 1 << (subprefix - this.prefix.num); _++) {
      ret.push(net.clone());
      net = net.from(net.host_address, net.prefix);
      const size = net.size();
      net.host_address = net.host_address.add(size);
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
  public to_ipv6(): IPAddress {
    return this.vt_to_ipv6(this);
  }

  public newprefix(num: number): Prefix {
    for (let i = num; i < this.ip_bits.bits; ++i) {
      const a = ~~Math.log2(i);
      if (a == Math.log2(i)) {
        return this.prefix.add(a);
      }
    }
    return null;
  }
}

export default IPAddress;
