
import BigInt
//
//import Rle //from './rle';
//
//import IpVersion from './ip_version';
//

typealias ToString = (_ source: IpBits, _ num: BigUInt) -> String;


// #[derive(Debug, Clone)]
public class IpBits {
  let version: IpVersion;
  let vt_as_compressed_string: ToString;
  let vt_as_uncompressed_string: ToString;
  public let bits: UInt8;
  let part_bits: UInt8;
  let dns_bits: UInt8;
  let rev_domain: String;
  let part_mod: Int;
  let host_ofs: BigUInt; // ipv4=1, ipv6=0
  
  
  init(version: IpVersion,
       vt_as_compressed_string: @escaping ToString,
       vt_as_uncompressed_string: @escaping ToString,
       bits: UInt8, part_bits: UInt8,
       dns_bits: UInt8, rev_domain: String,
       part_mod: Int, host_ofs: BigUInt) {
    self.version = version
    self.vt_as_compressed_string = vt_as_compressed_string
    self.vt_as_uncompressed_string = vt_as_uncompressed_string
    self.bits = bits
    self.part_bits = part_bits
    self.dns_bits = dns_bits
    self.rev_domain = rev_domain
    self.part_mod = part_mod
    self.host_ofs = host_ofs
  }
  
  func clone() -> IpBits {
    // let my = new IpBits();
    // my.version = self.version;
    // my.vt_as_compressed_string = self.vt_as_compressed_String;
    // my.vt_as_uncompressed_String = self.vt_as_uncompressed_String;
    // my.bits = self.bits;
    // my.part_bits = self.part_bits;
    // my.dns_bits = self.dns_bits;
    // my.rev_domain = self.rev_domain;
    // my.part_mod = self.part_mod;
    // my.host_ofs = self.host_ofs.clone();
    return self;
  }
  
  public func parts(_ bu: BigUInt)-> [UInt] {
    var vec = [UInt]();
    var my = bu;
    let part_mod = BigUInt(1) << Int(self.part_bits);// - BigUInt::one();
    for _ in 1...(self.bits / self.part_bits) {
      // console.log("parts-1:", my, part_mod, my.mod(part_mod), my.mod(part_mod).toString());
      let tmp = String(my % part_mod)
      let itmp = UInt(tmp)
      vec.append(itmp!)
      my = my >> Int(self.part_bits);
    }
    // console.log("parts:", vec);
    return Array(vec.reversed());
  }
  
  public func as_compressed_string(_ bu: BigUInt) -> String {
    return (self.vt_as_compressed_string)(self, bu);
  }
  public func as_uncompressed_string(_ bu: BigUInt) -> String {
    return (self.vt_as_uncompressed_string)(self, bu);
  }
  
  public func dns_part_format(_ i: UInt) -> String {
    switch (self.version) {
    case IpVersion.V4: return "\(i)";
    case IpVersion.V6: return "\(String(i, radix: 16))";
    }
  }
  
  static var _v4 : IpBits?;
  public class func v4() -> IpBits {
    if (IpBits._v4 != nil) {
      return IpBits._v4!;
    }
    IpBits._v4 = IpBits(
      version: IpVersion.V4,
      vt_as_compressed_string: IpBits.ipv4_as_compressed,
      vt_as_uncompressed_string: IpBits.ipv4_as_compressed,
      bits: 32,
      part_bits: 8,
      dns_bits: 8,
      rev_domain: "in-addr.arpa",
      part_mod: 1 << 8,
      host_ofs: BigUInt(1)
    );
    return IpBits._v4!;
  }
  
  static var _v6 : IpBits?;
  public class func v6() -> IpBits {
    if (IpBits._v6 != nil) {
      return IpBits._v6!;
    }
    IpBits._v6 = IpBits(
      version: IpVersion.V6,
      vt_as_compressed_string: IpBits.ipv6_as_compressed,
      vt_as_uncompressed_string: IpBits.ipv6_as_uncompressed,
      bits: 128,
      part_bits: 16,
      dns_bits: 4,
      rev_domain: "ip6.arpa",
      part_mod: 1 << 16,
      host_ofs: BigUInt(0)
    );
    return IpBits._v6!;
  }
  
  class func ipv4_as_compressed(_ ip_bits: IpBits, _ host_address: BigUInt) -> String {
    var ret = "";
    var sep = "";
    for part in ip_bits.parts(host_address) {
      ret += sep;
      ret += "\(part)";
      sep = ".";
    }
    return ret;
  }
  
  class func ipv6_as_compressed(_ ip_bits: IpBits, _ host_address: BigUInt) -> String {
    //println!("ipv6_as_compressed:{}", host_address);
    var ret = "";
    var colon = "";
    var done = false;
    for rle in Rle<Int>.code(ip_bits.parts(host_address)) {
      for _ in 1...rle.cnt {
        if (done || !(rle.part == 0 && rle.max)) {
          ret += "\(colon)\(String(rle.part, radix: 16))";
          colon = ":";
        } else if (rle.part == 0 && rle.max) {
          ret += "::";
          colon = "";
          done = true;
          break;
        }
      }
    }
    return ret;
  }
  class func ipv6_as_uncompressed(_ ip_bits: IpBits, _ host_address: BigUInt) -> String {
    var ret = "";
    var sep = "";
    for part in ip_bits.parts(host_address) {
      ret += sep;
      let tmp = String((0x10000 + part), radix: 16);
      ret += String(tmp.characters.dropFirst(1))
      sep = ":";
    }
    return ret;
  }
  
}

