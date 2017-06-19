package ipaddress

// import "ipaddress"
import "math/big"
import "fmt"
import "strconv"

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
	num, err := big.NewInt(0).SetString(str, radix)
	if !err {
		// fmt.Printf("From_str:Err:%s:%d\n", str, radix)
		tmp := fmt.Sprintf("unparsable %s", str)
		return &Error{&tmp}
	}
	// fmt.Printf("From_str:Ok:%s:%s\n", str, num.String())
	return Ipv6FromInt(num, prefix)
}

func enhance_if_mapped(ip *IPAddress) ResultIPAddress {
	// fmt.Printf("real mapped {:x} {:x}", &ip.host_address, ip.host_address.clone().shr(32));
	if ip.Is_mapped() {
		// fmt.Printf("eim-1\n")
		return &Ok{ip}
	}
	ipv6_top_96bit := big.NewInt(0).Set(&ip.Host_address)
	// fmt.Printf("eim-A:%s\n", ip.Host_address.String())
	ipv6_top_96bit = ipv6_top_96bit.Rsh(ipv6_top_96bit, 32)
	one := big.NewInt(1)
	// fmt.Printf("eim-0:%s\n", ipv6_top_96bit.String())
	if ipv6_top_96bit.Cmp(big.NewInt(0xffff)) == 0 {
		// fmt.Printf("enhance_if_mapped-1:{}", );
		// fmt.Printf("eim-B")
		num := big.NewInt(0).Set(&ip.Host_address)
		num = num.Rem(num, big.NewInt(0).Lsh(one, 32))
		if num.Cmp(big.NewInt(0)) == 0 {
			// fmt.Printf("eim-2\n")
			return &Ok{ip}
		}
		//fmt.Printf("ip:{},{:x}", ip.to_string(), num);
		ipv4_bits := IpBitsV4()
		if ipv4_bits.Bits < ip.Prefix.Host_prefix() {
			// fmt.Printf("enhance_if_mapped-2:{}:{}", ip.to_string(), ip.prefix.host_prefix());
			tmp := fmt.Sprintf("enhance_if_mapped prefix not ipv4 compatible %d", ip.Prefix.Host_prefix())
			// fmt.Printf("eim-3\n")
			return &Error{&tmp}
		}
		mapped := From_u32(uint32(num.Uint64()), ipv4_bits.Bits-ip.Prefix.Host_prefix())
		if mapped.IsErr() {
			// fm!("enhance_if_mapped-3");
			// fmt.Printf("eim-4\n")
			return mapped
		}
		// fmt.Printf("real mapped!!!!!={}", mapped.clone().Unwrap().to_string());
		ip.Mapped = mapped.Unwrap()
	}
	ret := &Ok{ip}
	// fmt.Printf("eim-5:%d\n", ret.IsOk())
	return ret
}

func Ipv6FromInt(adr *big.Int, _prefix uint8) ResultIPAddress {
	prefix := Prefix128New(_prefix)
	if prefix.IsErr() {
		return &Error{prefix.UnwrapErr()}
	}
	return enhance_if_mapped(&IPAddress{
		IpBitsV6(),
		*adr,
		*prefix.Unwrap(),
		nil,
		ipv6_is_private,
		ipv6_is_loopback,
		ipv6_to_ipv6,
	})
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
func Ipv6New(str string) ResultIPAddress {
	// fmt.Printf("i6-1\n")
	ip, o_netmask := Split_at_slash(str)
	if Is_valid_ipv6(ip) {
		// fmt.Printf("i6-2\n")
		o_num, err := split_to_num(ip)
		if err != nil {
			// fmt.Printf("i6-3 %s\n", err)
			return &Error{err}
		}
		netmask := uint8(128)
		if o_netmask != nil {
			// fmt.Printf("i6-4\n")
			network := o_netmask
			num_mask, err := strconv.ParseInt(*network, 10, 16)
			if err != nil {
				tmp := fmt.Sprintf("can not parse:%s:%s", *network, err)
				// fmt.Printf("i6-5 %s\n", tmp)
				return &Error{&tmp}
			}
			netmask = uint8(num_mask)
		}
		prefix := Prefix128New(netmask)
		if prefix.IsErr() {
			// fmt.Printf("i6-6 %s\n", prefix.UnwrapErr())
			return &Error{prefix.UnwrapErr()}
		}
		// fmt.Printf("i6-7\n")
		return enhance_if_mapped(&IPAddress{
			IpBitsV6(),
			*o_num,
			*prefix.Unwrap(),
			nil,
			ipv6_is_private,
			ipv6_is_loopback,
			ipv6_to_ipv6})
	} else {
		tmp := fmt.Sprintf("Invalid IP %s", str)
		// fmt.Printf("i6-8 %s\n", tmp)
		return &Error{&tmp}
	}
}

func ipv6_to_ipv6(ia *IPAddress) *IPAddress {
	return ia.Clone()
}

func ipv6_is_loopback(my *IPAddress) bool {
	return my.Host_address.Cmp(big.NewInt(1)) == 0
}

var ipv6_private_str = "fd00::/8"
var ipv6_private *IPAddress

func ipv6_is_private(my *IPAddress) bool {
	if ipv6_private == nil {
		ipv6_private = Parse(ipv6_private_str).Unwrap()
	}
	return ipv6_private.Includes(my)
}
