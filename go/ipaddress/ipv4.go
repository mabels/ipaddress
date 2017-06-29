package ipaddress

import "math/big"

import "fmt"
import "strconv"

// struct IPv4 {
//     address: String,
//     prefix: Prefix32,
//     ip32: u32
// }
//   // class IPv4
//
//   include IPAddress
//   include Enumerable
//   include Comparable
//
//   //
//   //  This Hash contains the prefix values for Classful networks
//   //
//   //  Note that classes C, D and E will all have a default
//   //  prefix of /24 or 255.255.255.0
//   //
//   CLASSFUL = {
//     /^0../ => 8,  //  Class A, from 0.0.0.0 to 127.255.255.255
//     /^10./ => 16, //  Class B, from 128.0.0.0 to 191.255.255.255
//     /^110/ => 24  //  Class C, D and E, from 192.0.0.0 to 255.255.255.254
//   }

//  Regular expression to match an IPv4 address
//

//  Creates a new IPv4 address object.
//
//  An IPv4 address can be expressed in any of the following forms:
//
//  * "10.1.1.1/24": ip +address+ and +prefix+. This is the common and
//  suggested way to create an object                  .
//  * "10.1.1.1/255.255.255.0": ip +address+ and +netmask+. Although
//  convenient sometimes, this format is less clear than the previous
//  one.
//  * "10.1.1.1": if the address alone is specified, the prefix will be
//  set as default 32, also known as the host prefix
//
//  Examples:
//
//    //  These two are the same
//    ip = IPAddress::IPv4.new("10.0.0.1/24")
//    ip = IPAddress("10.0.0.1/24")
//
//    //  These two are the same
//    IPAddress::IPv4.new "10.0.0.1/8"
//    IPAddress::IPv4.new "10.0.0.1/255.0.0.0"
//
// mod IPv4 {

func From_u32(addr uint32, _prefix uint8) ResultIPAddress {
	prefix := Prefix32New(_prefix)
	if prefix.IsErr() {
		return &Error{prefix.UnwrapErr()}
	}
	big_addr := big.NewInt(int64(addr))
	return &Ok{&IPAddress{
		IpBitsV4(),
		*big_addr,
		*prefix.Unwrap(),
		nil,
		ipv4_is_private,
		ipv4_is_loopback,
		ipv4_to_ipv6}}
}

func Ipv4New(str string) ResultIPAddress {
	// fmt.Printf("---1\n")
	ip, netmask := Split_at_slash(str)
	if !Is_valid_ipv4(ip) {
		// fmt.Printf("---2:%s:%s:%s\n", str, ip, *netmask)
		tmp := fmt.Sprintf("Invalid IP %s", str)
		return &Error{&tmp}
	}
	ip_prefix_num := uint8(32)
	if netmask != nil {
		//  netmask is defined
		ipn, err := Parse_netmask_to_prefix(*netmask)
		if err != nil {
			// fmt.Printf("---3\n")
			return &Error{err}
		}
		ip_prefix_num = *ipn
		//if ip_prefix.ip_bits.version
	}
	ip_prefix := Prefix32New(ip_prefix_num)
	if ip_prefix == nil {
		// fmt.Printf("---4\n")
		return &Error{ip_prefix.UnwrapErr()}
	}
	split_u32, err := split_to_u32(ip)
	if err != nil {
		// fmt.Printf("---5 [%s]\n", err)
		return &Error{err}
	}
	// fmt.Printf("Ipv4New:%x:%s\n", int64(*split_u32), str)
	return &Ok{&IPAddress{
		IpBitsV4(),
		*big.NewInt(int64(*split_u32)),
		*ip_prefix.Unwrap(),
		nil,
		ipv4_is_private,
		ipv4_is_loopback,
		ipv4_to_ipv6}}
}

var ipv4_private_networks_val []*IPAddress;

func ipv4_private_networks() *[]*IPAddress {
	if ipv4_private_networks_val == nil {
		ipv4_private_networks_val = []*IPAddress{
			Parse("10.0.0.0/8").Unwrap(),
			Parse("169.254.0.0/16").Unwrap(),
			Parse("172.16.0.0/12").Unwrap(),
			Parse("192.168.0.0/16").Unwrap()}
	}
	return &ipv4_private_networks_val
}

func ipv4_is_private(my *IPAddress) bool {
	for _, ip := range *ipv4_private_networks() {
		if ip.Includes(my) {
			return true
		}
	}
	return false
}

var ipv4_loopback *IPAddress

func ipv4_is_loopback(my *IPAddress) bool {
	if ipv4_loopback == nil {
		ipv4_loopback = Parse("127.0.0.0/8").Unwrap()
	}
	return ipv4_loopback.Includes(my)
}

func ipv4_to_ipv6(ia *IPAddress) *IPAddress {
	ret := new(IPAddress)
	ret.Ip_bits = IpBitsV6()
	ret.Host_address = ia.Host_address
	ret.Prefix = *Prefix128New(ia.Prefix.Num).Unwrap()
	ret.Mapped = nil
	ret.Vt_is_private = ipv6_is_private
	ret.Vt_is_loopback = ipv6_is_loopback
	ret.Vt_to_ipv6 = ipv6_to_ipv6
	return ret
}

//  Checks whether the ip address belongs to a
//  RFC 791 CLASS A network, no matter
//  what the subnet mask is.
//
//  Example:
//
//    ip = IPAddress("10.0.0.1/24")
//
//    ip.a?
//      // => true
//
func Is_class_a(my *IPAddress) bool {
	return my.Is_ipv4() && my.Host_address.Cmp(big.NewInt(0x80000000)) < 0
}

//  Checks whether the ip address belongs to a
//  RFC 791 CLASS B network, no matter
//  what the subnet mask is.
//
//  Example:
//
//    ip = IPAddress("172.16.10.1/24")
//
//    ip.b?
//      // => true
//
func Is_class_b(my *IPAddress) bool {
	return my.Is_ipv4() &&
		big.NewInt(0x80000000).Cmp(&my.Host_address) <= 0 &&
		my.Host_address.Cmp(big.NewInt(0xc0000000)) < 0
}

//  Checks whether the ip address belongs to a
//  RFC 791 CLASS C network, no matter
//  what the subnet mask is.
//
//  Example:
//
//    ip = IPAddress("192.168.1.1/30")
//
//    ip.c?
//      // => true
//
func Is_class_c(my *IPAddress) bool {
	return my.Is_ipv4() &&
		big.NewInt(0xc0000000).Cmp(&my.Host_address) <= 0 &&
		my.Host_address.Cmp(big.NewInt(0xe0000000)) < 0
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
// func to_ipv6(my: &IPAddress) {
//     let part_mod = BigUint::one() << 16;
//     return format!("{:04x}:{:04x}",
//                    (my.host_address >> 16).mod_floor(&part_mod).to_u16().Unwrap(),
//                    my.host_address.mod_floor(&part_mod).to_u16().Unwrap());
// }

//  Creates a new IPv4 object from an
//  unsigned 32bits integer.
//
//    ip = IPAddress::IPv4::parse_u32(167772160)
//
//    ip.prefix = 8
//    ip.to_string
//      // => "10.0.0.0/8"
//
//  The +prefix+ parameter is optional:
//
//    ip = IPAddress::IPv4::parse_u32(167772160, 8)
//
//    ip.to_string
//      // => "10.0.0.0/8"
//
// func parse_u32(ip32: u32, prefix: u8) {
//   IPv4::new(format!("{}/{}", IPv4::to_ipv4_str(ip32), prefix))
// }

//  Creates a new IPv4 object from binary data,
//  like the one you get from a network stream.
//
//  For example, on a network stream the IP 172.16.0.1
//  is represented with the binary "\254\020\n\001".
//
//    ip = IPAddress::IPv4::parse_data "\254\020\n\001"
//    ip.prefix = 24
//
//    ip.to_string
//      // => "172.16.10.1/24"
//
// func self.parse_data(str, prefix=32)
//   self.new(str.unpack("C4").join(".")+"/// {prefix}")
// end

//  Extract an IPv4 address from a string and
//  returns a new object
//
//  Example:
//
//    str = "foobar172.16.10.1barbaz"
//    ip = IPAddress::IPv4::extract str
//
//    ip.to_s
//      // => "172.16.10.1"
//
// func self.extract(str) {
//   let re = Regexp::new(r"((25[0-5]|2[0-4]\d|1\d\d|[1-9]\d|\d)\.){3}(25[0-5]|2[0-4]\d|1
// \d\d|[1-9]\d|\d)")
//   IPv4::new(.match(str).to_s
// }

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
//    ip1 = IPAddress("172.16.10.0/24")
//    ip2 = IPAddress("172.16.11.0/24")
//
//  These two networks can be expressed using only one IP address
//  network if we change the prefix. Let Ruby do the work:
//
//    IPAddress::IPv4::summarize(ip1,ip2).to_s
//      // => "172.16.10.0/23"
//
//  We note how the network "172.16.10.0/23" includes all the addresses
//  specified in the above networks, and (more important) includes
//  ONLY those addresses.
//
//  If we summarized +ip1+ and +ip2+ with the following network:
//
//    "172.16.0.0/16"
//
//  we would have satisfied rule // 1 above, but not rule // 2. So "172.16.0.0/16"
//  is not an aggregate network for +ip1+ and +ip2+.
//
//  If it's not possible to compute a single aggregated network for all the
//  original networks, the method returns an array with all the aggregate
//  networks found. For example, the following four networks can be
//  aggregated in a single /22:
//
//    ip1 = IPAddress("10.0.0.1/24")
//    ip2 = IPAddress("10.0.1.1/24")
//    ip3 = IPAddress("10.0.2.1/24")
//    ip4 = IPAddress("10.0.3.1/24")
//
//    IPAddress::IPv4::summarize(ip1,ip2,ip3,ip4).to_string
//      // => "10.0.0.0/22",
//
//  But the following networks can't be summarized in a single network:
//
//    ip1 = IPAddress("10.0.1.1/24")
//    ip2 = IPAddress("10.0.2.1/24")
//    ip3 = IPAddress("10.0.3.1/24")
//    ip4 = IPAddress("10.0.4.1/24")
//
//    IPAddress::IPv4::summarize(ip1,ip2,ip3,ip4).map{|i| i.to_string}
//      // => ["10.0.1.0/24","10.0.2.0/23","10.0.4.0/24"]
//
// func self.summarize(args)
//   IPAddress.summarize(args)
// end

//  Creates a new IPv4 address object by parsing the
//  address in a classful way.
//
//  Classful addresses have a fixed netmask based on the
//  class they belong to:
//
//  * Class A, from 0.0.0.0 to 127.255.255.255
//  * Class B, from 128.0.0.0 to 191.255.255.255
//  * Class C, D and E, from 192.0.0.0 to 255.255.255.254
//
//  Example:
//
//    ip = IPAddress::IPv4.parse_classful "10.0.0.1"
//
//    ip.netmask
//      // => "255.0.0.0"
//    ip.a?
//      // => true
//
//  Note that classes C, D and E will all have a default
//  prefix of /24 or 255.255.255.0
//
func Parse_classful(ip_si string) ResultIPAddress {
	if !Is_valid_ipv4(ip_si) {
		tmp := fmt.Sprintf("Invalid IP %s", ip_si)
		return &Error{&tmp}
	}
	o_ip := Parse(ip_si)
	if o_ip.IsErr() {
		return o_ip
	}
	ip := o_ip.Unwrap()
	if Is_class_a(ip) {
		ip.Prefix = *Prefix32New(8).Unwrap()
	} else if Is_class_b(ip) {
		ip.Prefix = *Prefix32New(16).Unwrap()
	} else if Is_class_c(ip) {
		ip.Prefix = *Prefix32New(24).Unwrap()
	}
	return &Ok{ip}
}

//  private methods
//
// fn newprefix(&self, num: u8) {
//   for (i = num; i < 32; ++i) {
//     let a = numeric::math::log(i, 2);
//     if (a == numeric::math::log(i, 2)) {
//       return self.prefix + a;
//     }
//   }
// }

//  fn sum_first_found(&self, arr: &[u32]) {
//    let mut dup = arr.reverse();
//    dup.each_with_index { |obj,i|
//      a = [self.class.summarize(obj,dup[i+1])].flatten
//      if (a.size == 1) {
//        dup[i..i+1] = a
//        return dup.reverse()
//      }
//    }
//    return dup.reverse()
// }

func netmask_to_prefix(nm *big.Int, bits uint8) (*uint8, *string) {
	prefix := uint8(0)
	addr := nm
	in_host_part := true
	two := big.NewInt(2)
	for i := uint8(0); i < bits; i++ {
		bit := big.NewInt(0).Rem(addr, two).Uint64()
		if in_host_part && bit == 0 {
			prefix = prefix + 1
		} else if in_host_part && bit == 1 {
			in_host_part = false
		} else if !in_host_part && bit == 0 {
			err := fmt.Sprintf("this is not a net mask %s", nm)
			return nil, &err
		}
		addr.Rsh(addr, 1)
	}
	prefix = bits - prefix
	return &prefix, nil
}

func Parse_netmask_to_prefix(netmask string) (*uint8, *string) {
	is_number, err := strconv.ParseUint(netmask, 10, 64)
	if err == nil {
		ret := uint8(is_number)
		return &ret, nil
	}
	my_ip := Parse(netmask)
	if my_ip.IsErr() {
		tmp := fmt.Sprintf("illegal netmask %s", netmask)
		return nil, &tmp
	}
	return netmask_to_prefix(&my_ip.Unwrap().Host_address, my_ip.Unwrap().Ip_bits.Bits)
}
