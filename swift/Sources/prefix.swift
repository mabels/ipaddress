
//import IpBits from './ip_bits';
import BigInt

typealias From = (_ source: Prefix,_ num: UInt8) -> Prefix?;

public class Prefix {
  public let num: UInt8;
  public let ip_bits: IpBits;
  let net_mask: BigUInt;
  let vt_from: From;
  
  init(num: UInt8, ip_bits: IpBits, net_mask: BigUInt, vt_from: @escaping From) {
    self.num = num;
    self.ip_bits = ip_bits;
    self.net_mask = net_mask;
    self.vt_from = vt_from;
  }
  
  public func clone() ->  Prefix {
    return Prefix(
      num: self.num,
      ip_bits: self.ip_bits,
      net_mask: self.net_mask,
      vt_from: self.vt_from
    );
  }
  
  public func eq(_ other: Prefix)-> Bool {
    return self.ip_bits.version == other.ip_bits.version &&
      self.num == other.num;
  }
  public func ne(_ other: Prefix)-> Bool {
    return !self.eq(other);
  }
  public func cmp(_ oth: Prefix)-> Int {
    if (self.ip_bits.version != oth.ip_bits.version &&
      self.ip_bits.version == IpVersion.V4) {
      return -1;
    } else if (self.ip_bits.version != oth.ip_bits.version &&
      self.ip_bits.version == IpVersion.V6) {
      return 1;
    } else {
      if (self.num < oth.num) {
        return -1;
      } else if (self.num > oth.num) {
        return 1;
      } else {
        return 0;
      }
    }
  }
  
  public func from(_ num: UInt8)-> Prefix? {
    return (self.vt_from)(self, num);
  }
  
  public func to_ip_str() -> String {
    return self.ip_bits.vt_as_compressed_string(self.ip_bits, self.net_mask);
  }
  
  public func size() -> BigUInt {
    return BigUInt(1) << Int(self.ip_bits.bits - self.num);
  }
  
  public class func new_netmask(_ prefix: UInt8, _ bits: UInt8) -> BigUInt {
    var mask = BigUInt(0);
    let host_prefix = bits - prefix;
    for i in stride(from:UInt8(0), to: prefix, by: 1) {
      // console.log(">>>", i, host_prefix, mask);
      mask = mask + (BigUInt(1) << Int(host_prefix + i));
    }
    return mask
  }
  
  public func netmask() -> BigUInt {
    return self.net_mask;
  }
  
  public func get_prefix() -> UInt8 {
    return self.num;
  }
  
  //  The hostmask is the contrary of the subnet mask,
  //  as it shows the bits that can change within the
  //  hosts
  //
  //    prefix = IPAddress::Prefix32.new 24
  //
  //    prefix.hostmask
  //      // => "0.0.0.255"
  //
  public func host_mask() -> BigUInt {
    var ret = BigUInt(0);
    for _ in 1...(self.ip_bits.bits - self.num) {
      ret = (ret << 1) + BigUInt(1);
    }
    return ret;
  }
  
  
  //
  //  Returns the length of the host portion
  //  of a netmask.
  //
  //    prefix = Prefix128.new 96
  //
  //    prefix.host_prefix
  //      // => 128
  //
  public func host_prefix() -> UInt8 {
    return self.ip_bits.bits - self.num;
  }
  
  //
  //  Transforms the prefix into a string of bits
  //  representing the netmask
  //
  //    prefix = IPAddress::Prefix128.new 64
  //
  //    prefix.bits
  //      // => "1111111111111111111111111111111111111111111111111111111111111111"
  //          "0000000000000000000000000000000000000000000000000000000000000000"
  //
  public func bits() -> String {
    return String(self.netmask(), radix: 2);
  }
  // #[allow(dead_code)]
  // public net_mask(&self) -> BigUint {
  //     return (self.in_mask.clone() >> (self.host_prefix() as usize)) << (self.host_prefix() as usize);
  // }
  
  public func to_s()-> String {
    return String(self.get_prefix());
  }
  //#[allow(dead_code)]
  // public inspect(&self) -> String {
  //     return self.to_s();
  // }
  public func to_i() -> UInt8 {
    return self.get_prefix();
  }
  
  public func add_prefix(_ other: Prefix) -> Prefix? {
    return self.from(self.get_prefix() + other.get_prefix());
  }
  
  public func add(_ other: UInt8) -> Prefix? {
    return self.from(self.get_prefix() + other)
  }
  
  public func sub_prefix(_ other: Prefix) -> Prefix? {
    return self.sub(other.get_prefix());
  }
  
  public func sub(_ other: UInt8) -> Prefix? {
    if (other > self.get_prefix()) {
      return self.from(other - self.get_prefix());
    }
    return self.from(self.get_prefix() - other);
  }
  
}


