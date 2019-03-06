import 'IPAddress.dart';
import 'IpBits.dart';
import 'IpV4.dart';
import 'Prefix128.dart';
import 'Result.dart';

class IpV6 {
  ///  =Name

  ///
  ///  IPAddress::IPv6 - IP version 6 address manipulation library

  ///

  ///  =Synopsis

  ///

  ///     require 'ipaddress'
  ///

  ///  =Description

  ///

  ///  Class IPAddress::IPv6 is used to handle IPv6 type addresses.

  ///
  ///  == IPv6 addresses

  ///

  ///  IPv6 addresses are 128 bits long, in contrast with IPv4 addresses

  ///  which are only 32 bits long. An IPv6 address is generally written as

  ///  eight groups of four hexadecimal digits, each group representing 16
  ///  bits or two octect. For example, the following is a valid IPv6

  ///  address:

  ///

  ///    2001:0db8:0000:0000:0008:0800:200c:417a

  ///
  ///  Letters in an IPv6 address are usually written downcase, as per

  ///  RFC. You can create a IPv6 object using uppercase letters, but

  ///  they will be converted.

  ///

  ///  == Compression
  ///

  ///  Since IPv6 addresses are very long to write, there are some

  ///  semplifications and compressions that you can use to shorten them.

  ///

  ///  * Leading zeroes: all the leading zeroes within a group can be
  ///    omitted: "0008" would become "8"

  ///

  ///  * A string of consecutive zeroes can be replaced by the string

  ///    "::". This can be only applied once.

  ///
  ///  Using compression, the IPv6 address written above can be shorten into

  ///  the following, equivalent, address

  ///

  ///    2001:db8::8:800:200c:417a

  ///
  ///  This short version is often used in human representation.

  ///

  ///  == Network Mask

  ///

  ///  As we used to do with IPv4 addresses, an IPv6 address can be written
  ///  using the prefix notation to specify the subnet mask:

  ///

  ///    2001:db8::8:800:200c:417a/64

  ///

  ///  The /64 part means that the first 64 bits of the address are
  ///  representing the network portion, and the last 64 bits are the host

  ///  portion.

  ///

  ///

  static final VtIPAddress ipv6_to_ipv6 = (IPAddress my) => my.clone();
  static final VtBool ipv6_is_loopback =
      (IPAddress my) => my.host_address == BigInt.from(0);
  static final VtBool ipv6_is_private =
      (IPAddress my) => IPAddress.parse("fd00::/8").unwrap().includes(my);

  static Result<IPAddress> from_str(String str, int radix, int prefix) {
    try {
      final num = BigInt.parse(str, radix: radix);
      return from_int(num, prefix);
    } catch (e) {
      return Result.Err("unparsable ${str}");
    }
  }

  static Result<IPAddress> enhance_if_mapped(IPAddress ip) {
    // println!("real mapped {:x} {:x}", &ip.host_address, ip.host_address.clone().shr(32));
    if (ip.is_mapped()) {
      return Result.Ok(ip);
    }
    final ipv6_top_96bit = ip.host_address >> 32;
    if (ipv6_top_96bit == BigInt.from(0xffff)) {
      // println!("enhance_if_mapped-1:{}", );
      final num = ip.host_address % (BigInt.from(1) << 32);
      if (num == BigInt.from(0)) {
        return Result.Ok(ip);
      }
      //println!("ip:{},{:x}", ip.to_string(), num);
      final ipv4_bits = IpBits.V4;
      if (ipv4_bits.bits < ip.prefix.host_prefix()) {
        //println!("enhance_if_mapped-2:{}:{}", ip.to_string(), ip.prefix.host_prefix());
        return Result.Err(
            '''enhance_if_mapped prefix not ipv4 compatible <<ip.prefix.host_prefix()>>''');
      }
      final mapped =
          IpV4.from_u32(num.toInt(), ipv4_bits.bits - ip.prefix.host_prefix());
      if (mapped.isErr()) {
        //println!("enhance_if_mapped-3");
        return mapped;
      }
      // println!("real mapped!!!!!={}", mapped.clone().unwrap().to_string());
      return Result.Ok(ip.setMappedIpaddress(mapped.unwrap()));
    }
    return Result.Ok(ip);
  }

  static Result<IPAddress> from_int(BigInt bi, int prefixNum) {
    final prefix = Prefix128.create(prefixNum);
    if (prefix.isErr()) {
      return Result.Err(prefix.unwrapErr());
    }
    return enhance_if_mapped(IPAddress(IpBits.V6, bi, prefix.unwrap(), null,
        ipv6_is_private, ipv6_is_loopback, ipv6_to_ipv6));
  }

  ///  Creates a IPv6 address object.
  ///

  ///  An IPv6 address can be expressed in any of the following forms:

  ///
  ///  * "2001:0db8:0000:0000:0008:0800:200C:417A": IPv6 address with no compression

  ///  * "2001:db8:0:0:8:800:200C:417A": IPv6 address with leading zeros compression

  ///  * "2001:db8::8:800:200C:417A": IPv6 address with full compression

  ///

  ///  In all these 3 cases, a IPv6 address object will be created, using the default
  ///  subnet mask /128

  ///

  ///  You can also specify the subnet mask as with IPv4 addresses:

  ///

  ///    ip6 = IPAddress "2001:db8::8:800:200c:417a/64"
  ///
  static Result<IPAddress> create(String str) {
    final splitted = IPAddress.split_at_slash(str);
    if (IPAddress.is_valid_ipv6(splitted.addr)) {
      final o_num = IPAddress.split_to_num(splitted.addr);
      if (o_num.isErr()) {
        return Result.Err(o_num.unwrapErr());
      }
      var netmask = 128;
      if (splitted.netmask != null) {
        final network = splitted.netmask;
        final num_mask = IPAddress.parseInt(network, 10);
        if (num_mask == null) {
          return Result.Err('''Invalid Netmask <<str>>''');
        }
        netmask = num_mask.toInt();
      }
      final prefix = Prefix128.create(netmask);
      if (prefix.isErr()) {
        return Result.Err(prefix.unwrapErr());
      }
      return enhance_if_mapped(IPAddress(
          IpBits.V6,
          o_num.unwrap(),
          prefix.unwrap(),
          null,
          ipv6_is_private,
          ipv6_is_loopback,
          ipv6_to_ipv6));
    } else {
      return Result.Err('''Invalid IP <<str>>''');
    }
  }
}
