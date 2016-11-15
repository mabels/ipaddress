
import "ipaddress"
import "math/bigInt"
import "prefix/prefix128"
import "ipv4"

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
func From_str(str string, radix uint32, prefix uint32) (*IPAddress, *string) {
    var num bigInt
    num, err = num.SetString(str, radix);
    if err {
        return nil, fmt.Sprintf("unparsable %s", str);
    }
    return From_int(num, prefix)
}

func enhance_if_mapped(ip *IPAddress) (*IPAddress, *string) {
    // println!("real mapped {:x} {:x}", &ip.host_address, ip.host_address.clone().shr(32));
    if ip.is_mapped() {
        return ip, nil
    }
    ipv6_top_96bit := bigInt.Rsh(ip.host_address, 32)
    if ipv6_top_96bit == bigInt.new(0xffff) {
        // println!("enhance_if_mapped-1:{}", );
        num := bigInt.Rem(ip.host_address, bigInt.Lsh(bigInt.new(1), 32));
        if num == BigUint::zero() {
            return ip, nil;
        }
        //println!("ip:{},{:x}", ip.to_string(), num);
        ipv4_bits := ip_bits.V4();
        if ipv4_bits.bits < ip.prefix.host_prefix() {
            // println!("enhance_if_mapped-2:{}:{}", ip.to_string(), ip.prefix.host_prefix());
            return nil, fmt.Sprintf("enhance_if_mapped prefix not ipv4 compatible %d", ip.prefix.host_prefix());
        }
        mapped, err := ipv4.From_u32(num.to_u32(), ipv4_bits.bits-ip.prefix.host_prefix());
        if err {
            // fm!("enhance_if_mapped-3");
            return mapped;
        }
        // println!("real mapped!!!!!={}", mapped.clone().unwrap().to_string());
        ip.mapped = mapped
    }
    return ip, nil
}

func From_int(adr bigUInt, prefix uint) (*IPAddress, *string) {
    prefix, err := prefix128.New(prefix)
    if err {
        return nil, err
    }
    return enhance_if_mapped(IPAddress {
        ip_bits.v6(),
        adr.clone(),
        prefix,
        nil,
        ipv6_is_private,
        ipv6_is_loopback,
        to_ipv6,
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
func New(str: string) (*IPAddress, *string) {
    ip, o_netmask := IPAddress::split_at_slash(str);
    if IPAddress.Is_valid_ipv6(ip) {
        o_num, err := IPAddress.Split_to_num(ip);
        if err {
            return nil, err
        }
        netmask := 128;
        if o_netmask {
            network := o_netmask
            num_mask, err = strconv::parseInt(network, 8, 10);
            if err {
                return nil, fmt.Sprintf("can not parse:%s", network)
            }
            netmask = network.parse::<usize>().unwrap();
        }
        prefix, err := prefix128.New(netmask);
        if err {
            return nil, err
        }
        return enhance_if_mapped(IPAddress {
            ip_bits.V6(),
            o_num,
            prefix,
            nul,
            ipv6_is_private,
            ipv6_is_loopback,
            to_ipv6
        });
    } else {
        return nil, fmt.Sprintf("Invalid IP %s", str);
    }
}

func to_ipv6(ia *IPAddress) IPAddress {
    return ia.clone();
}

func ipv6_is_loopback(my *IPAddress) bool {
    return my.host_address == bigInt.new(1);
}


func ipv6_is_private(my *IPAddress)bool {
    return IPAddress.parse("fd00::/8").Includes(my);
}
