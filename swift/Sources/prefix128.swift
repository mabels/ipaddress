//import Prefix from './prefix';
//import IpBits from './ip_bits';

public class Prefix128 {
  // #[derive(Ord,PartialOrd,Eq,PartialEq,Debug,Copy,Clone)]
  // pub struct Prefix128 {
  // }
  //
  // impl Prefix128 {
  //
  //  Creates a new prefix object for 128 bits IPv6 addresses
  //
  //    prefix = IPAddressPrefix128.new 64
  //      // => 64
  //
  //#[allow(unused_comparisons)]
  public class func create(_ num: UInt8) -> Prefix? {
    if (num <= 128) {
      let ip_bits = IpBits.v6();
      let bits = ip_bits.bits;
      return  Prefix(
        num: num,
        ip_bits: ip_bits,
        net_mask: Prefix.new_netmask(num, bits),
        vt_from: Prefix128.from // vt_to_ip_str: _TO_IP_STR
      );
    }
    return nil;
  }
  
  public class func from(_ my: Prefix, _ num: UInt8) -> Prefix? {
    return Prefix128.create(num);
  }
}


