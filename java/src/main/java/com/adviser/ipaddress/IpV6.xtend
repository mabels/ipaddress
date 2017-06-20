package com.adviser.ipaddress

import java.math.BigInteger

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

    ///  RFC. You can create a new IPv6 object using uppercase letters, but

    ///  they will be converted.

    ///

    ///  === Compression
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

    ///  === Network Mask

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

    public final static IPAddress.VtIPAddress ipv6_to_ipv6 = [ IPAddress my | return ia.clone() ];
    public final static IPAddress.VtBool ipv6_is_loopback = [ IPAddress my | return my.host_address.eq(BigInteger.ONE) ];
    public final static IPAddress.VtBool ipv6_is_private = [ IPAddress my | return IPAddress.parse("fd00::/8").unwrap().includes(my) ];

    public def Result<IPAddress> from_str(String str, int radix, int prefix) {
        try {
            val num = BigInteger(str, radix)
            return from_int(num.unwrap(), prefix);
        } catch(Throwable e) {
            return Result.Err("unparsable <<str>>")
        }
    }

    public static def Result<IPAddress>  enhance_if_mapped(IPAddress ip) {
        // println!("real mapped {:x} {:x}", &ip.host_address, ip.host_address.clone().shr(32));
        if(ip.is_mapped()) {
            return Result.Ok(ip);
        }
        val ipv6_top_96bit = ip.host_address.clone().shr(32);
        if(ipv6_top_96bit.Equal(BigInteger.from_u32(0xffff))) {
            // println!("enhance_if_mapped-1:{}", );
            val num = ip.host_address.clone().rem(BigUint::one().shl(32));
            if(num.Equal(BigUint::zero())) {
                return Ok(ip);
            }
            //println!("ip:{},{:x}", ip.to_string(), num);
            val ipv4_bits = Ip_bits.V4;
            if(ipv4_bits.bits < ip.prefix.host_prefix()) {
                //println!("enhance_if_mapped-2:{}:{}", ip.to_string(), ip.prefix.host_prefix());
                return Err('''enhance_if_mapped prefix not ipv4 compatible <<ip.prefix.host_prefix()>>''');
            }
            val mapped = IpV4.from_u32(num.to_u32().unwrap(), ipv4_bits.bits-ip.prefix.host_prefix());
            if(mapped.is_err()) {
                //println!("enhance_if_mapped-3");
                return mapped;
            }
            // println!("real mapped!!!!!={}", mapped.clone().unwrap().to_string());
            ip.mapped = mapped.unwrap();
        }
        return Ok(ip);
    }


    public static def Result<IPAddress> from_int(BigInteger bi, int prefix) {
        val prefix = prefix128.create(prefix);
        if(prefix.is_err()) {
            return Err(prefix.unwrap_err());
        }
        return enhance_if_mapped(new IPAddress(
                Ip_bits.V6,
                BigInteger.ZERO.add(bi),
                prefix.unwrap(),
                null,
                ipv6_is_private, ipv6_is_loopback, to_ipv6));
    }
    ///  Creates a new IPv6 address object.
    ///

    ///  An IPv6 address can be expressed in any of the following forms:

    ///
    ///  * "2001:0db8:0000:0000:0008:0800:200C:417A": IPv6 address with no compression

    ///  * "2001:db8:0:0:8:800:200C:417A": IPv6 address with leading zeros compression

    ///  * "2001:db8::8:800:200C:417A": IPv6 address with full compression

    ///

    ///  In all these 3 cases, a new IPv6 address object will be created, using the default
    ///  subnet mask /128

    ///

    ///  You can also specify the subnet mask as with IPv4 addresses:

    ///

    ///    ip6 = IPAddress "2001:db8::8:800:200c:417a/64"
    ///
    public static def Result<IPAddress> create(String str)  {
        val splitted = IPAddress.split_at_slash(str);
        if (IPAddress.is_valid_ipv6(ip)) {
            val o_num = IPAddress.split_to_num(ip);
            if (o_num.is_err()) {
                return Err(o_num.unwrap_err());
            }
            var netmask = 128;
            if (o_netmask.is_some()) {
                val network = o_netmask.unwrap();
                val num_mask = parse(network);
                if(num_mask.is_err()) {
                    return Result.Err('''Invalid Netmask <<str>>''');
                }
                netmask = network.parse::<usize>().unwrap();
            }
            val prefix = Prefix128.create(netmask);
            if (prefix.is_err()) {
                return Result.Err(prefix.unwrap_err());
            }
            return enhance_if_mapped(new IPAddress(
                    ip_bits.V6,
                    o_num.unwrap(),
                    prefix.unwrap(),
                    null,
                    ipv6_is_private, ipv6_is_loopback, to_ipv6));
        } else {
            return Result.Err('''Invalid IP <<str>>''');
        }
    }


}
