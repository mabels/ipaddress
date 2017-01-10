package ipaddress
// import "ipaddress"
import "math/big"
import "fmt"
import "strconv"

// import "../ipaddress/data"
import "../prefix/prefix128"
// import "./ipv4"

import "../ip_bits"

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
func From_str(str string, radix int, prefix uint8) ResultIPAddress {
    var num big.Int
    var err bool
    _, err = num.SetString(str, radix);
    if err {
      tmp := fmt.Sprintf("unparsable %s", str)
      return &Error{&tmp}
    }
    return From_int(&num, prefix)
}

func enhance_if_mapped(ip *IPAddress) ResultIPAddress {
    // println!("real mapped {:x} {:x}", &ip.host_address, ip.host_address.clone().shr(32));
    if ip.Is_mapped() {
        return &Ok{ip}
    }
    ipv6_top_96bit := big.NewInt(0).Rsh(&ip.Host_address, 32)
    one := big.NewInt(1)
    if ipv6_top_96bit.Cmp(big.NewInt(0xffff))==0 {
        // println!("enhance_if_mapped-1:{}", );
        num := big.NewInt(0).Rem(&ip.Host_address,
                big.NewInt(0).Lsh(one, 32));
        if num.Cmp(big.NewInt(0)) == 0 {
            return &Ok{ip}
        }
        //println!("ip:{},{:x}", ip.to_string(), num);
        ipv4_bits := ip_bits.V4();
        if ipv4_bits.Bits < ip.Prefix.Host_prefix() {
            // println!("enhance_if_mapped-2:{}:{}", ip.to_string(), ip.prefix.host_prefix());
            tmp := fmt.Sprintf("enhance_if_mapped prefix not ipv4 compatible %d", ip.Prefix.Host_prefix())
            return &Error{&tmp}
        }
        mapped := From_u32(uint32(num.Uint64()), ipv4_bits.Bits-ip.Prefix.Host_prefix());
        if mapped.IsErr() {
            // fm!("enhance_if_mapped-3");
            return mapped;
        }
        // println!("real mapped!!!!!={}", mapped.clone().unwrap().to_string());
        ip.Mapped = mapped.Unwrap()
    }
    return &Ok{ip}
}

func From_int(adr *big.Int, _prefix uint8) ResultIPAddress {
    prefix := prefix128.New(_prefix)
    if prefix.IsErr() {
        return &Error{prefix.UnwrapErr()}
    }
    return enhance_if_mapped(&IPAddress {
        ip_bits.V6(),
        *adr,
        *prefix.Unwrap(),
        nil,
        ipv6_is_private,
        ipv6_is_loopback,
        ipv6_to_ipv6,
    });
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
func Ipv6New(str *string) ResultIPAddress {
    ip, o_netmask := Split_at_slash(str);
    if Is_valid_ipv6(&ip) {
        o_num, err := split_to_num(&ip);
        if err != nil {
            return &Error{err}
        }
        netmask := uint8(128);
        if o_netmask != nil {
            network := o_netmask
            num_mask, err := strconv.ParseInt(*network, 8, 10);
            if err != nil {
                tmp := fmt.Sprintf("can not parse:%s", network)
                return &Error{&tmp}
            }
            netmask = uint8(num_mask)
        }
        prefix := prefix128.New(netmask);
        if prefix.IsErr() {
            return &Error{prefix.UnwrapErr()}
        }
        return enhance_if_mapped(&IPAddress {
            ip_bits.V6(),
            *o_num,
            *prefix.Unwrap(),
            nil,
            ipv6_is_private,
            ipv6_is_loopback,
            ipv6_to_ipv6 });
    } else {
        tmp := fmt.Sprintf("Invalid IP %s", str)
        return &Error{&tmp}
    }
}

func ipv6_to_ipv6(ia *IPAddress) IPAddress {
    return ia.Clone();
}

func ipv6_is_loopback(my *IPAddress) bool {
    return my.Host_address.Cmp(big.NewInt(1)) == 0
}

var ipv6_private_str = "fd00::/8"
var ipv6_private *IPAddress
func ipv6_is_private(my *IPAddress) bool {
  if ipv6_private == nil {
    ipv6_private = Parse(&ipv6_private_str).Unwrap()
  }
    return ipv6_private.Includes(my);
}
