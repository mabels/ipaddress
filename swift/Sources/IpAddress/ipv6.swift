//
//import Prefix from './prefix';
//import IpBits from './ip_bits';
//import IPAddress from './ipaddress';
//import Ipv4 from './ipv4';
//import Prefix128 from './prefix128';
import BigInt

public class Ipv6 {
  //  =Name
  //
  //  IPAddress::IPv6 - IP version 6 address manipulation library
  //
  //  =Synopsis
  //
  //     require 'ipaddress'
  //
  //  =Description
  //
  //  Class IPAddress::IPv6 is used to handle IPv6 type addresses.
  //
  //  == IPv6 addresses
  //
  //  IPv6 addresses are 128 bits long, in contrast with IPv4 addresses
  //  which are only 32 bits long. An IPv6 address is generally written as
  //  eight groups of four hexadecimal digits, each group representing 16
  //  bits or two octect. For example, the following is a valid IPv6
  //  address:
  //
  //    2001:0db8:0000:0000:0008:0800:200c:417a
  //
  //  Letters in an IPv6 address are usually written downcase, as per
  //  RFC. You can create a new IPv6 object using uppercase letters, but
  //  they will be converted.
  //
  //  === Compression
  //
  //  Since IPv6 addresses are very long to write, there are some
  //  semplifications and compressions that you can use to shorten them.
  //
  //  * Leading zeroes: all the leading zeroes within a group can be
  //    omitted: "0008" would become "8"
  //
  //  * A string of consecutive zeroes can be replaced by the string
  //    "::". This can be only applied once.
  //
  //  Using compression, the IPv6 address written above can be shorten into
  //  the following, equivalent, address
  //
  //    2001:db8::8:800:200c:417a
  //
  //  This short version is often used in human representation.
  //
  //  === Network Mask
  //
  //  As we used to do with IPv4 addresses, an IPv6 address can be written
  //  using the prefix notation to specify the subnet mask:
  //
  //    2001:db8::8:800:200c:417a/64
  //
  //  The /64 part means that the first 64 bits of the address are
  //  representing the network portion, and the last 64 bits are the host
  //  portion.
  //
  //
  
  public class func from_str(_ str: String, _ radix: Int, _ prefix: UInt8) -> IPAddress? {
    let num = BigUInt(str, radix: radix);
    if (num == nil) {
      return nil;
    }
    return Ipv6.from_int(num!, prefix);
  }
  
  public class func enhance_if_mapped(_ ip: IPAddress) -> IPAddress? {
    // console.log("------A");
    // println!("real mapped {:x} {:x}", &ip.host_address, ip.host_address.clone().shr(32));
    if (ip.is_mapped()) {
      // console.log("------B");
      return ip;
    }
    // console.log("------C", ip);
    let ipv6_top_96bit = ip.host_address >> 32
    // console.log("------D", ip);
    if (ipv6_top_96bit == BigUInt(0xffff)) {
      // console.log("------E");
      let num = ip.host_address % (BigUInt(1) << 32);
      // console.log("------F");
      if (num == BigUInt(0)) {
        return ip;
      }
      //println!("ip:{},{:x}", ip.to_string(), num);
      let ipv4_bits = IpBits.v4();
      if (ipv4_bits.bits < ip.prefix.host_prefix()) {
        //println!("enhance_if_mapped-2:{}:{}", ip.to_string(), ip.prefix.host_prefix());
        return nil;
      }
      // console.log("------G");
      let mapped = Ipv4.from_int(num, ipv4_bits.bits - ip.prefix.host_prefix());
      // console.log("------H");
      if (mapped == nil) {
        // println!("enhance_if_mapped-3");
        return mapped;
      }
      // println!("real mapped!!!!!={}", mapped.clone().to_string());
      ip.mapped = mapped;
    }
    return ip;
  }
  
  public class func from_int(_ adr: BigUInt, _ prefix_num: UInt8) -> IPAddress? {
    let prefix = Prefix128.create(prefix_num);
    if (prefix == nil) {
      return nil;
    }
    let ret = Ipv6.enhance_if_mapped(IPAddress(
      ip_bits: IpBits.v6(),
      host_address: adr,
      prefix: prefix!,
      mapped: nil,
      vt_is_private: Ipv6.ipv6_is_private,
      vt_is_loopback: Ipv6.ipv6_is_loopback,
      vt_to_ipv6: Ipv6.to_ipv6
    ));
    //console.log("from_int:", adr, prefix, ret);
    return ret;
  }
  
  
  //  Creates a new IPv6 address object.
  //
  //  An IPv6 address can be expressed in any of the following forms:
  //
  //  * "2001:0db8:0000:0000:0008:0800:200C:417A": IPv6 address with no compression
  //  * "2001:db8:0:0:8:800:200C:417A": IPv6 address with leading zeros compression
  //  * "2001:db8::8:800:200C:417A": IPv6 address with full compression
  //
  //  In all these 3 cases, a new IPv6 address object will be created, using the default
  //  subnet mask /128
  //
  //  You can also specify the subnet mask as with IPv4 addresses:
  //
  //    ip6 = IPAddress "2001:db8::8:800:200c:417a/64"
  //
  public class func create(_ str: String) -> IPAddress? {
    // console.log("1>>>>>>>>>", str);
    let (ip, o_netmask) = IPAddress.split_at_slash(str);
    // console.log("2>>>>>>>>>", str);
    if (IPAddress.is_valid_ipv6(ip)) {
      // console.log("3>>>>>>>>>", str);
      let o_num = IPAddress.split_to_num(ip);
      if (o_num == nil) {
        // console.log("ipv6_create-1", str);
        return nil;
      }
      // console.log("4>>>>>>>>>", str);
      var netmask : UInt8 = 128;
      if (o_netmask != nil) {
        let tmp = IPAddress.parse_dec_str(o_netmask!);
        if (tmp == nil) {
          // console.log("ipv6_create-2", str);
          return nil;
        }
        netmask = UInt8(tmp!)
      }
      // console.log("5>>>>>>>>>", str);
      let prefix = Prefix128.create(netmask);
      if (prefix == nil) {
        // console.log("ipv6_create-3", str);
        return nil;
      }
      //console.log("6>>>>>>>>>", str, prefix.num, o_netmask, netmask);
      return Ipv6.enhance_if_mapped(IPAddress(
        ip_bits: IpBits.v6(),
        host_address: o_num!.crunchy,
        prefix: prefix!,
        mapped: nil,
        vt_is_private: Ipv6.ipv6_is_private,
        vt_is_loopback: Ipv6.ipv6_is_loopback,
        vt_to_ipv6: Ipv6.to_ipv6
      ));
    } else {
      // console.log("ipv6_create-4", str);
      return nil;
    }
  } //  pub fn initialize
  
  public class func to_ipv6(_ ia: IPAddress) -> IPAddress {
    return ia.clone();
  }
  
  public class func ipv6_is_loopback(_ my: IPAddress) -> Bool {
    // console.log("*************", my.host_address, BigUInt.one());
    return my.host_address == BigUInt(1);
  }
  
  public class func ipv6_is_private(_ my: IPAddress) -> Bool {
    return IPAddress.parse("fd00::/8")!.includes(my);
  }
  
}

