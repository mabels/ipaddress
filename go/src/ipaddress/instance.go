package ipaddress

import "strings"

// import "strconv"
import "math/big"
import "math"
import "sort"

// import "regexp"
import "fmt"

// import "../ip_bits"
import "../ip_version"
import "../prefix"

// import "./data"
import "bytes"

// import "../ip_version"
// import "../ipaddress"
// import "../ipv4"
// import "../ipv6"

type Error struct {
	err *string
}

func (self *Error) IsOk() bool         { return false }
func (self *Error) IsErr() bool        { return true }
func (self *Error) Unwrap() *IPAddress { return nil }
func (self *Error) UnwrapErr() *string { return self.err }

// func Error(err *string) *ErrorIsh {
//     return &ErrorIsh{err}
// }

type Ok struct {
	ipaddress *IPAddress
}

func (self *Ok) IsOk() bool         { return true }
func (self *Ok) IsErr() bool        { return false }
func (self *Ok) Unwrap() *IPAddress { return self.ipaddress }
func (self *Ok) UnwrapErr() *string { return nil }

type Errors struct {
	err *string
}

func (self *Errors) IsOk() bool           { return false }
func (self *Errors) IsErr() bool          { return true }
func (self *Errors) Unwrap() *[]*IPAddress { return nil }
func (self *Errors) UnwrapErr() *string   { return self.err }

// func Error(err *string) *ErrorIsh {
//     return &ErrorIsh{err}
// }

type Oks struct {
	ipaddresses *[]*IPAddress
}

func (self *Oks) IsOk() bool           { return true }
func (self *Oks) IsErr() bool          { return false }
func (self *Oks) Unwrap() *[]*IPAddress { return self.ipaddresses }
func (self *Oks) UnwrapErr() *string   { return nil }

func (self *IPAddress) Clone() *IPAddress {
	mapped := self.Mapped
	if self.Mapped != nil {
		tmp := *self.Mapped
		tmp2 := tmp.Clone()
		mapped = tmp2
	}
	ret := new(IPAddress)
	ret.Ip_bits =	self.Ip_bits
	ret.Host_address = self.Host_address
	ret.Prefix = self.Prefix.Clone()
	ret.Mapped = mapped
	ret.Vt_is_private =	self.Vt_is_private
	ret.Vt_is_loopback = self.Vt_is_loopback
	ret.Vt_to_ipv6 = self.Vt_to_ipv6
	return ret;
}

func (self *IPAddress) String() string {
	return fmt.Sprintf("IPAddress: %s", self.To_string())
}

func (self *IPAddress) Eq(oth *IPAddress) bool {
	return self.Cmp(oth) == 0
}

func (self *IPAddress) Lt(oth *IPAddress) bool {
	return self.Cmp(oth) < 0
}

func (self *IPAddress) Gt(oth *IPAddress) bool {
	return self.Cmp(oth) > 0
}

func (self *IPAddress) Cmp(oth *IPAddress) int {
	if self.Ip_bits.Version != oth.Ip_bits.Version {
		if self.Ip_bits.Version == ip_version.V6 {
			return 1
		}
		return -1
	}
	//let adr_diff = self.host_address - oth.host_address;
	if self.Host_address.Cmp(&oth.Host_address) < 0 {
		return -1
	} else if self.Host_address.Cmp(&oth.Host_address) > 0 {
		return 1
	}
	return self.Prefix.Cmp(&oth.Prefix)
}

func (self *IPAddress) Equal(other IPAddress) bool {
	return self.Ip_bits.Version == other.Ip_bits.Version &&
		self.Prefix.Cmp(&other.Prefix) == 0 &&
		self.Host_address.Cmp(&other.Host_address) == 0 &&
		((self.Mapped == nil && self.Mapped == other.Mapped) ||
			self.Mapped.Equal(*other.Mapped))
}

/// Parse the argument string to create a new
/// IPv4, IPv6 or Mapped IP object
///
///   ip  = IPAddress.parse "172.16.10.1/24"
///  ip6 = IPAddress.parse "2001:db8::8:800:200c:417a/64"
///  ip_mapped = IPAddress.parse "::ffff:172.16.10.1/128"
///
/// All the object created will be instances of the
/// correct class:
///
///  ip.class
///   //=> IPAddress::IPv4
/// ip6.class
///   //=> IPAddress::IPv6
/// ip_mapped.class
///   //=> IPAddress::IPv6::Mapped
///

func Split_at_slash(str string) (string, *string) {
	trimmed := strings.TrimSpace(str)
	slash := strings.Split(trimmed, "/")
	addr := ""
	if len(slash) >= 1 {
		addr = strings.TrimSpace(slash[0])
	}
	if len(slash) >= 2 {
		tslash := strings.TrimSpace(slash[1])
		return addr, &tslash
	}
	return addr, nil
}

func (self *IPAddress) From(addr *big.Int, prefix *prefix.Prefix) *IPAddress {
	padr := new(IPAddress)
	*padr = IPAddress{
		self.Ip_bits,
		*addr,
		prefix.Clone(),
		self.Mapped,
		self.Vt_is_private,
		self.Vt_is_loopback,
		self.Vt_to_ipv6}
	return padr
}

/// True if the object is an IPv4 address
///
///   ip = IPAddress("192.168.10.100/24")
///
///   ip.ipv4?
///     //-> true
///
func (self *IPAddress) Is_ipv4() bool {
	return self.Ip_bits.Version == ip_version.V4
}

/// True if the object is an IPv6 address
///
///   ip = IPAddress("192.168.10.100/24")
///
///   ip.ipv6?
///     //-> false
///
func (self *IPAddress) Is_ipv6() bool {
	return self.Ip_bits.Version == ip_version.V6
}

func (self *IPAddress) Parts() []uint16 {
	return self.Ip_bits.Parts(&self.Host_address)
}

func (self *IPAddress) Parts_hex_str() []string {
	var ret []string
	for i := range self.Parts() {
		ret = append(ret, fmt.Sprintf("{:04x}", i))
	}
	return ret
}

///  Returns the IP address in in-addr.arpa format
///  for DNS Domain definition entries like SOA Records
///
///    ip = IPAddress("172.17.100.50/15")
///
///    ip.dns_rev_domains
///      // => ["16.172.in-addr.arpa","17.172.in-addr.arpa"]
///
func (self *IPAddress) Dns_rev_domains() []string {
	var ret []string
	for _, net := range self.Dns_networks() {
		// fmt.Printf("dns_rev_domains:{}:{}", self.to_string(), net.to_string());
		ret = append(ret, net.Dns_reverse())
	}
	return ret
}

func (self *IPAddress) Dns_reverse() string {
	var ret bytes.Buffer
	dot := ""
	dns_parts := self.dns_parts()
	for i := ((self.Prefix.Host_prefix() + (self.Ip_bits.Dns_bits - 1)) / self.Ip_bits.Dns_bits); i <= uint8(len(dns_parts)); i++ {
		ret.WriteString(dot)
		ret.WriteString(self.Ip_bits.Dns_part_format(dns_parts[i]))
		dot = "."
	}
	ret.WriteString(dot)
	ret.WriteString(self.Ip_bits.Rev_domain)
	return ret.String()
}

func (self *IPAddress) dns_parts() []uint8 {
	var ret []uint8
	num := self.Host_address
	mask := big.NewInt(0).Lsh(big.NewInt(1), uint(self.Ip_bits.Dns_bits))
	for i := 0; i < int(self.Ip_bits.Bits/self.Ip_bits.Dns_bits); i++ {
		var rem big.Int
		part := uint8(rem.Rem(&num, mask).Uint64())
		num.Rsh(&num, uint(self.Ip_bits.Dns_bits))
		ret = append(ret, part)
	}
	return ret
}

func (self *IPAddress) Dns_networks() []*IPAddress {
	// +self.ip_bits.dns_bits-1
	next_bit_mask := self.Ip_bits.Bits -
		(((self.Prefix.Host_prefix()) / self.Ip_bits.Dns_bits) * self.Ip_bits.Dns_bits)
	if next_bit_mask <= 0 {
		return []*IPAddress{self.Network()}
	}
	//  fmt.Printf("dns_networks:{}:{}", self.to_string(), next_bit_mask);
	// dns_bits
	step_bit_net := big.NewInt(0).Lsh(big.NewInt(1), uint(self.Ip_bits.Bits-next_bit_mask))
	if step_bit_net.Cmp(big.NewInt(0)) == 0 {
		return []*IPAddress{self.Network()}
	}
	var ret []*IPAddress
	step := self.Network().Host_address
	resPrefix := self.Prefix.From(next_bit_mask)
	baddr := self.Broadcast().Host_address
	for baddr.Cmp(&step) > 0 {
		ret = append(ret, self.From(&step, resPrefix.Unwrap()))
		step.Add(&step, step_bit_net)
	}
	return ret
}

func (self *IPAddress) Ip_same_kind(oth *IPAddress) bool {
	return self.Ip_bits.Version == oth.Ip_bits.Version
}

///  Returns true if the address is an unspecified address
///
///  See IPAddress::IPv6::Unspecified for more information
///

func (self *IPAddress) Is_unspecified() bool {
	return self.Host_address.Cmp(big.NewInt(0)) == 0
}

///  Returns true if the address is a loopback address
///
///  See IPAddress::IPv6::Loopback for more information
///

func (self *IPAddress) Is_loopback() bool {
	return (self.Vt_is_loopback)(self)
}

///  Returns true if the address is a mapped address
///
///  See IPAddress::IPv6::Mapped for more information
///

func (self *IPAddress) Is_mapped() bool {
	var num big.Int
	mask := big.NewInt(0).Lsh(big.NewInt(1), 16)
	var rest big.Int
	fmt.Printf("Is_mapped:%s\n", self.Mapped)
	return self.Mapped != nil &&
		num.Rsh(&self.Host_address, 32).Cmp(rest.Sub(mask, big.NewInt(1))) == 0
}

///  Returns the prefix portion of the IPv4 object
///  as a IPAddress::Prefix32 object
///
///    ip = IPAddress("172.16.100.4/22")
///
///    ip.Prefix
///      ///  22
///
///    ip.Prefix.class
///      ///  IPAddress::Prefix32
///

// func (self *IPAddress) Prefix() prefix.Prefix {
// 	return self.Prefix
// }

/// Checks if the argument is a valid IPv4 netmask
/// expressed in dotted decimal format.
///
///   IPAddress.valid_ipv4_netmask? "255.255.0.0"
///     ///  true
///

///  Set a new prefix number for the object
///
///  This is useful if you want to change the prefix
///  to an object created with IPv4::parse_u32 or
///  if the object was created using the classful
///  mask.
///
///    ip = IPAddress("172.16.100.4")
///
///    puts ip
///      ///  172.16.100.4/16
///
///    ip.Prefix = 22
///
///    puts ip
///      ///  172.16.100.4/22
///
func (self *IPAddress) Change_prefix(num uint8) ResultIPAddress {
	prefix := self.Prefix.From(num)
	if prefix.IsErr() {
		return &Error{prefix.UnwrapErr()}
	}
	from := self.From(&self.Host_address, prefix.Unwrap())
	return &Ok{from}
}

func (self *IPAddress) Change_netmask(my_str string) ResultIPAddress {
	nm, err := Parse_netmask_to_prefix(my_str)
	if err != nil {
		return &Error{err}
	}
	return self.Change_prefix(*nm)
}

///  Returns a string with the IP address in canonical
///  form.
///
///    ip = IPAddress("172.16.100.4/22")
///
///    ip.to_string
///      ///  "172.16.100.4/22"
///

func (self *IPAddress) To_string() string {
	var ret bytes.Buffer
	ret.WriteString(self.To_s())
	ret.WriteString("/")
	ret.WriteString(self.Prefix.To_s())
	return ret.String()
}

func (self *IPAddress) To_s() string {
	return self.Ip_bits.As_compressed_string(&self.Host_address)
}

func (self *IPAddress) To_string_uncompressed() string {
	var ret bytes.Buffer
	ret.WriteString(self.To_s_uncompressed())
	ret.WriteString("/")
	ret.WriteString(self.Prefix.To_s())
	return ret.String()
}

func (self *IPAddress) To_s_uncompressed() string {
	return self.Ip_bits.As_uncompressed_string(&self.Host_address)
}

func (self *IPAddress) To_s_mapped() string {
	if self.Is_mapped() {
		return fmt.Sprintf("::ffff:%s", self.Mapped.To_s())
	}
	return self.To_s()
}

func (self *IPAddress) To_string_mapped() string {
	if self.Is_mapped() {
		mapped := self.Mapped
		return fmt.Sprintf("%s/%d",
			self.To_s_mapped(),
			mapped.Prefix.Num)
	}
	return self.To_string()
}

///  Returns the address portion of an IP in binary format,
///  as a string containing a sequence of 0 and 1
///
///    ip = IPAddress("127.0.0.1")
///
///    ip.bits
///      ///  "01111111000000000000000000000001"
///

func (self *IPAddress) Bits() string {
	num := self.Host_address.Text(2)
	var ret bytes.Buffer
	for i := uint8(len(num)); i < self.Ip_bits.Bits; i++ {
		ret.WriteString("0")
	}
	ret.WriteString(num)
	return ret.String()
}

func (self *IPAddress) To_hex() string {
	return self.Host_address.Text(16)
}

func (self *IPAddress) Netmask() *IPAddress {
	nm := self.Prefix.Netmask()
	return self.From(nm, &self.Prefix)
}

///  Returns the broadcast address for the given IP.
///
///    ip = IPAddress("172.16.10.64/24")
///
///    ip.broadcast.to_s
///      ///  "172.16.10.255"
///

func (self *IPAddress) Broadcast() *IPAddress {
	size := self.Size()
	h_a := self.Network().Host_address
	return self.From(big.NewInt(0).Add(&h_a,
		big.NewInt(0).Sub(&size, big.NewInt(1))), &self.Prefix)
	// IPv4::parse_u32(self.broadcast_u32, self.Prefix)
}

///  Checks if the IP address is actually a network
///
///    ip = IPAddress("172.16.10.64/24")
///
///    ip.network?
///      ///  false
///
///    ip = IPAddress("172.16.10.64/26")
///
///    ip.network?
///      ///  true
///

func (self *IPAddress) Is_network() bool {
	net := self.Network().Host_address
	return self.Prefix.Num != self.Ip_bits.Bits &&
		self.Host_address.Cmp(&net) == 0
}

///  Returns a new IPv4 object with the network number
///  for the given IP.
///
///    ip = IPAddress("172.16.10.64/24")
///
///    ip.network.to_s
///      ///  "172.16.10.0"
///

func (self *IPAddress) Network() *IPAddress {
	to_n := To_network(&self.Host_address, self.Prefix.Host_prefix())
	// fmt.Printf("Network:0:%s\n", self.Host_address)
	// fmt.Printf("Network:1:%s\n", self.Host_address.String())
	// fmt.Printf("Network:2:%s\n", to_n.String())
	return self.From(&to_n, &self.Prefix)
}

func To_network(adr *big.Int, host_prefix uint8) big.Int {
	num := big.NewInt(0).Set(adr)
	num.Rsh(num, uint(host_prefix)).Lsh(num, uint(host_prefix))
	return *num
}

func (self *IPAddress) Sub(other *IPAddress) big.Int {
	ret := big.NewInt(0)
	if self.Host_address.Cmp(&other.Host_address) > 0 {
		return *ret.Sub(&self.Host_address, &other.Host_address)
	}
	return *ret.Sub(&other.Host_address, &self.Host_address)
}

func (self *IPAddress) Add(other *IPAddress) *[]*IPAddress {
	return Aggregate(&[]*IPAddress{self, other})
}

///  Returns a new IPv4 object with the
///  first host IP address in the range.
///
///  Example: given the 192.168.100.0/24 network, the first
///  host IP address is 192.168.100.1.
///
///    ip = IPAddress("192.168.100.0/24")
///
///    ip.first.to_s
///      ///  "192.168.100.1"
///
///  The object IP doesn't need to be a network: the method
///  automatically gets the network number from it
///
///    ip = IPAddress("192.168.100.50/24")
///
///    ip.first.to_s
///      ///  "192.168.100.1"
///
func (self *IPAddress) First() *IPAddress {
	ha := self.Network().Host_address
	return self.From(big.NewInt(0).Add(&ha, &self.Ip_bits.Host_ofs), &self.Prefix)
}

///  Like its sibling method IPv4/// first, this method
///  returns a new IPv4 object with the
///  last host IP address in the range.
///
///  Example: given the 192.168.100.0/24 network, the last
///  host IP address is 192.168.100.254
///
///    ip = IPAddress("192.168.100.0/24")
///
///    ip.last.to_s
///      ///  "192.168.100.254"
///
///  The object IP doesn't need to be a network: the method
///  automatically gets the network number from it
///
///    ip = IPAddress("192.168.100.50/24")
///
///    ip.last.to_s
///      ///  "192.168.100.254"
///

func (self *IPAddress) Last() *IPAddress {
	ha := self.Broadcast().Host_address
	return self.From(big.NewInt(0).Sub(&ha, &self.Ip_bits.Host_ofs), &self.Prefix)
}

///  Iterates over all the hosts IP addresses for the given
///  network (or IP address).
///
///    ip = IPAddress("10.0.0.1/29")
///
///    ip.each_host do |i|
///      p i.to_s
///    end
///      ///  "10.0.0.1"
///      ///  "10.0.0.2"
///      ///  "10.0.0.3"
///      ///  "10.0.0.4"
///      ///  "10.0.0.5"
///      ///  "10.0.0.6"
///

func (self *IPAddress) Each_host(fn func(*IPAddress)) {
	i := self.First().Host_address
	last := self.Last().Host_address
	for i.Cmp(&last) < 0 {
		ip := self.From(&i, &self.Prefix)
		fn(ip)
		i.Add(&i, big.NewInt(1))
	}
}

///  Iterates over all the IP addresses for the given
///  network (or IP address).
///
///  The object yielded is a new IPv4 object created
///  from the iteration.
///
///    ip = IPAddress("10.0.0.1/29")
///
///    ip.each do |i|
///      p i.address
///    end
///      ///  "10.0.0.0"
///      ///  "10.0.0.1"
///      ///  "10.0.0.2"
///      ///  "10.0.0.3"
///      ///  "10.0.0.4"
///      ///  "10.0.0.5"
///      ///  "10.0.0.6"
///      ///  "10.0.0.7"
///

func (self *IPAddress) Each(fn func(*IPAddress)) {
	i := self.Network().Host_address
	broad := self.Broadcast().Host_address
	for broad.Cmp(&i) > 0 {
		ip := self.From(&i, &self.Prefix)
		fn(ip)
		i.Add(&i, big.NewInt(1))
	}
}

///  Spaceship operator to compare IPv4 objects
///
///  Comparing IPv4 addresses is useful to ordinate
///  them into lists that match our intuitive
///  perception of ordered IP addresses.
///
///  The first comparison criteria is the u32 value.
///  For example, 10.100.100.1 will be considered
///  to be less than 172.16.0.1, because, in a ordered list,
///  we expect 10.100.100.1 to come before 172.16.0.1.
///
///  The second criteria, in case two IPv4 objects
///  have identical addresses, is the prefix. An higher
///  prefix will be considered greater than a lower
///  prefix. This is because we expect to see
///  10.100.100.0/24 come before 10.100.100.0/25.
///
///  Example:
///
///    ip1 = IPAddress "10.100.100.1/8"
///    ip2 = IPAddress "172.16.0.1/16"
///    ip3 = IPAddress "10.100.100.1/16"
///
///    ip1 < ip2
///      ///  true
///    ip1 > ip3
///      ///  false
///
///    [ip1,ip2,ip3].sort.map{|i| i.to_string}
///      ///  ["10.100.100.1/8","10.100.100.1/16","172.16.0.1/16"]
///
///  Returns the number of IP addresses included
///  in the network. It also counts the network
///  address and the broadcast address.
///
///    ip = IPAddress("10.0.0.1/29")
///
///    ip.size
///      ///  8
///

func (self *IPAddress) Size() big.Int {
	ret := big.NewInt(1)
	ret.Lsh(ret, uint(self.Prefix.Host_prefix()))
	return *ret
}

func (self *IPAddress) Is_same_kind(oth *IPAddress) bool {
	return self.Is_ipv4() == oth.Is_ipv4() &&
		self.Is_ipv6() == oth.Is_ipv6()
}

///  Checks whether a subnet includes the given IP address.
///
///  Accepts an IPAddress::IPv4 object.
///
///    ip = IPAddress("192.168.10.100/24")
///
///    addr = IPAddress("192.168.10.102/24")
///
///    ip.include? addr
///      ///  true
///
///    ip.include? IPAddress("172.16.0.48/16")
///      ///  false
///

func (self *IPAddress) Includes(oth *IPAddress) bool {
	to_n := To_network(&oth.Host_address, self.Prefix.Host_prefix())
	h_a := self.Network().Host_address
	ret := self.Is_same_kind(oth) &&
		self.Prefix.Num <= oth.Prefix.Num &&
		h_a.Cmp(&to_n) == 0
	// fmt.Printf("includes:{}=={}=>{}", self.to_string(), oth.to_string(), ret);
	return ret
}

///  Checks whether a subnet includes all the
///  given IPv4 objects.
///
///    ip = IPAddress("192.168.10.100/24")
///
///    addr1 = IPAddress("192.168.10.102/24")
///    addr2 = IPAddress("192.168.10.103/24")
///
///    ip.include_all?(addr1,addr2)
///      ///  true
///

func (self *IPAddress) Includes_all(oths *[]*IPAddress) bool {
	for _, oth := range *oths {
		if !self.Includes(oth) {
			return false
		}
	}
	return true
}

///  Checks if an IPv4 address objects belongs
///  to a private network RFC1918
///
///  Example:
///
///    ip = IPAddress "10.1.1.1/24"
///    ip.private?
///      ///  true
///

func (self *IPAddress) Is_private() bool {
	return (self.Vt_is_private)(self)
}

///  Splits a network into different subnets
///
///  If the IP Address is a network, it can be divided into
///  multiple networks. If +self+ is not a network, this
///  method will calculate the network from the IP and then
///  subnet it.
///
///  If +subnets+ is an power of two number, the resulting
///  networks will be divided evenly from the supernet.
///
///    network = IPAddress("172.16.10.0/24")
///
///    network / 4   ///  implies map{|i| i.to_string}
///      ///  ["172.16.10.0/26",
///           "172.16.10.64/26",
///           "172.16.10.128/26",
///           "172.16.10.192/26"]
///
///  If +num+ is any other number, the supernet will be
///  divided into some networks with a even number of hosts and
///  other networks with the remaining addresses.
///
///    network = IPAddress("172.16.10.0/24")
///
///    network / 3   ///  implies map{|i| i.to_string}
///      ///  ["172.16.10.0/26",
///           "172.16.10.64/26",
///           "172.16.10.128/25"]
///
///  Returns an array of IPv4 objects
///

func (self *IPAddress) Split(subnets uint) ResultIPAddresses {
	if subnets == 0 || (1<<self.Prefix.Host_prefix()) <= subnets {
		out := fmt.Sprintf("Value %s out of range", subnets)
		return &Errors{&out}
	}
	prefix, _ := self.Newprefix(subnets)
	networks := self.Subnet(prefix.Num)
	if networks.IsErr() {
		return networks
	}
	for uint(len(*networks.Unwrap())) != subnets {
		tmp := Sum_first_found(networks.Unwrap())
		networks = &Oks{tmp}
	}
	return networks
}

///  Returns a new IPv4 object from the supernetting
///  of the instance network.
///
///  Supernetting is similar to subnetting, except
///  that you getting as a result a network with a
///  smaller prefix (bigger host space). For example,
///  given the network
///
///    ip = IPAddress("172.16.10.0/24")
///
///  you can supernet it with a new /23 prefix
///
///    ip.supernet(23).to_string
///      ///  "172.16.10.0/23"
///
///  However if you supernet it with a /22 prefix, the
///  network address will change:
///
///    ip.supernet(22).to_string
///      ///  "172.16.8.0/22"
///
///  If +new_prefix+ is less than 1, returns 0.0.0.0/0
///

func (self *IPAddress) Supernet(new_prefix uint8) ResultIPAddress {
	if new_prefix >= self.Prefix.Num {
		ret := fmt.Sprintf("New prefix must be smaller than existing prefix: %d >= %d",
			new_prefix, self.Prefix.Num)
		return &Error{&ret}
	}
	// let mut new_ip = self.host_address.clone();
	// for _ in new_prefix..self.Prefix.num {
	//     new_ip = new_ip << 1;
	// }
	tmp := self.Host_address
	tmp3 := self.Prefix.From(new_prefix).Unwrap()
	tmp2 := self.From(&tmp, tmp3)
	tmp4 := tmp2.Network()
	return &Ok{tmp4}
}

///  This method implements the subnetting function
///  similar to the one described in RFC3531.
///
///  By specifying a new prefix, the method calculates
///  the network number for the given IPv4 object
///  and calculates the subnets associated to the new
///  prefix.
///
///  For example, given the following network:
///
///    ip = IPAddress "172.16.10.0/24"
///
///  we can calculate the subnets with a /26 prefix
///
///    ip.subnets(26).map(&:to_string)
///      ///  ["172.16.10.0/26", "172.16.10.64/26",
///           "172.16.10.128/26", "172.16.10.192/26"]
///
///  The resulting number of subnets will of course always be
///  a power of two.
///

func (self *IPAddress) Subnet(subprefix uint8) ResultIPAddresses {
	if subprefix < self.Prefix.Num || self.Ip_bits.Bits < subprefix {
		tmp := fmt.Sprintf("New prefix must be between prefix%d %d and %d",
			self.Prefix.Num,
			subprefix,
			self.Ip_bits.Bits)
		return &Errors{&tmp}
	}
	var ret []*IPAddress
	net := self.Network()
	net.Prefix = *net.Prefix.From(subprefix).Unwrap()
	for i := 0; i < (1 << (subprefix - self.Prefix.Num)); i++ {
		ret = append(ret, net.Clone())
		pre := net.Prefix
		net = net.From(&net.Host_address, &pre)
		size := net.Size()
		net.Host_address.Add(&net.Host_address, &size)
	}
	return &Oks{&ret}
}

///  Return the ip address in a format compatible
///  with the IPv6 Mapped IPv4 addresses
///
///  Example:
///
///    ip = IPAddress("172.16.10.1/24")
///
///    ip.to_ipv6
///      ///  "ac10:0a01"
///

func (self *IPAddress) To_ipv6() *IPAddress {
	return (self.Vt_to_ipv6)(self)
}

//  private methods
//

func (self *IPAddress) Newprefix(num uint) (*prefix.Prefix, *string) {
	for i := uint8(num); i < self.Ip_bits.Bits; i++ {
		a := float64(uint(math.Log2(float64(i))))
		if a == math.Log2(float64(i)) {
			return self.Prefix.Add(uint8(a)).Unwrap(), nil
		}
	}
	ret := fmt.Sprintf("newprefix not found %d:%d", num, self.Ip_bits.Bits)
	return nil, &ret
}

type ipaddressSorter struct {
	ipaddress []*IPAddress
	by        func(ip1, ip2 *IPAddress) bool // Closure used in the Less method.
}

func (s *ipaddressSorter) Len() int {
	return len(s.ipaddress)
}

// Swap is part of sort.Interface.
func (s *ipaddressSorter) Swap(i, j int) {
	s.ipaddress[i], s.ipaddress[j] = s.ipaddress[j], s.ipaddress[i]
}

// Less is part of sort.Interface. It is implemented by calling the "by" closure in the sorter.
func (s *ipaddressSorter) Less(i, j int) bool {
	return s.ipaddress[i].Cmp(s.ipaddress[j]) < 0
}

func Sorting(ips []*IPAddress) {
	s := &ipaddressSorter{
		ipaddress: ips,
		by: func(ip1, ip2 *IPAddress) bool {
			return ip1.Cmp(ip2) < 0
		}}
	sort.Sort(s)
}

func remove_ipaddress(stack []*IPAddress, idx int) []*IPAddress {
	var p []*IPAddress
	for i, v := range stack {
		if i != idx {
			p = append(p, v)
		}
	}
	return p
}

/// private helper for summarize
/// assumes that networks is output from reduce_networks
/// means it should be sorted lowers first and uniq
///

func pos_to_idx(pos int, len int) int {
	ilen := len
	// let ret = pos % ilen;
	rem := ((pos % ilen) + ilen) % ilen
	// fmt.Printf("pos_to_idx:{}:{}=>{}:{}", pos, len, ret, rem);
	return rem
}

func Aggregate(networks *[]*IPAddress) *[]*IPAddress {
	if len(*networks) == 0 {
		fmt.Printf("Aggregate:0\n")
		return &[]*IPAddress{}
	}
	if len(*networks) == 1 {
		fmt.Printf("Aggregate:1a:%s\n", (*networks)[0])
		net := (*networks)[0].Network()
		fmt.Printf("Aggregate:1:%s:%s\n", net.To_string(), (*networks)[0].To_string())
		return &[]*IPAddress{net}
	}
	stack := make([]*IPAddress, len(*networks))
	for idx, i := range *networks {
		stack[idx] = i.Network()
	}
	Sorting(stack)
	// for i in 0..networks.len() {
	//     fmt.Printf("{}==={}", &networks[i].to_string_uncompressed(),
	//         &stack[i].to_string_uncompressed());
	// }
	pos := 0
	for true {
		if pos < 0 {
			pos = 0
		}
		stack_len := len(stack) // borrow checker
		// fmt.Printf("loop:{}:{}", pos, stack_len);
		// if stack_len == 1 {
		//     fmt.Printf("exit 1");
		//     break;
		// }
		if pos >= stack_len {
			// fmt.Printf("exit first:{}:{}", stack_len, pos);
			break
		}
		first := pos_to_idx(pos, stack_len)
		pos = pos + 1
		if pos >= stack_len {
			// fmt.Printf("exit second:{}:{}", stack_len, pos);
			break
		}
		second := pos_to_idx(pos, stack_len)
		pos = pos + 1
		//let mut firstUnwrap = first.Unwrap();
		if stack[first].Includes(stack[second]) {
			pos = pos - 2
			// fmt.Printf("remove:1:{}:{}:{}=>{}", first, second, stack_len, pos + 1);
			stack = remove_ipaddress(stack, pos_to_idx(pos+1, stack_len))
		} else {
			tmp := stack[first].Prefix.Sub(1)
			stack[first].Prefix = *tmp.Unwrap()
			// fmt.Printf("complex:{}:{}:{}:{}:P1:{}:P2:{}", pos, stack_len,
			// first, second,
			// stack[first].to_string(), stack[second].to_string());
			if (stack[first].Prefix.Num+1) == stack[second].Prefix.Num &&
				stack[first].Includes(stack[second]) {
				pos = pos - 2
				idx := pos_to_idx(pos, stack_len)
				stack[idx] = stack[first].Clone() // kaputt
				stack = remove_ipaddress(stack, pos_to_idx(pos+1, stack_len))
				// fmt.Printf("remove-2:{}:{}", pos + 1, stack_len);
				pos = pos - 1 // backtrack
			} else {
				tmp := stack[first].Prefix.Add(1)
				stack[first].Prefix = *tmp.Unwrap() //reset prefix
				// fmt.Printf("easy:{}:{}=>{}", pos, stack_len, stack[first].to_string());
				pos = pos - 1 // do it with second as first
			}
		}
	}
	// fmt.Printf("agg={}:{}", pos, stack.len());
	var ret []*IPAddress
	for i := 0; i <= len(stack); i++ {
		ret = append(ret, stack[i].Network())
	}
	return &ret
}

/// Summarization (or aggregation) is the process when two or more
/// networks are taken together to check if a supernet, including all
/// and only these networks, exists. If it exists then this supernet
/// is called the summarized (or aggregated) network.
///
/// It is very important to understand that summarization can only
/// occur if there are no holes in the aggregated network, or, in other
/// words, if the given networks fill completely the address space
/// of the supernet. So the two rules are:
///
/// 1) The aggregate network must contain +all+ the IP addresses of the
///    original networks;
/// 2) The aggregate network must contain +only+ the IP addresses of the
///    original networks;
///
/// A few examples will help clarify the above. Let's consider for
/// instance the following two networks:
///
///   ip1 = IPAddress("172.16.10.0/24")
///   ip2 = IPAddress("172.16.11.0/24")
///
/// These two networks can be expressed using only one IP address
/// network if we change the prefix. Let Ruby do the work:
///
///   IPAddress::IPv4::summarize(ip1,ip2).to_s
///     ///  "172.16.10.0/23"
///
/// We note how the network "172.16.10.0/23" includes all the addresses
/// specified in the above networks, and (more important) includes
/// ONLY those addresses.
///
/// If we summarized +ip1+ and +ip2+ with the following network:
///
///   "172.16.0.0/16"
///
/// we would have satisfied rule /// 1 above, but not rule /// 2. So "172.16.0.0/16"
/// is not an aggregate network for +ip1+ and +ip2+.
///
/// If it's not possible to compute a single aggregated network for all the
/// original networks, the method returns an array with all the aggregate
/// networks found. For example, the following four networks can be
/// aggregated in a single /22:
///
///   ip1 = IPAddress("10.0.0.1/24")
///   ip2 = IPAddress("10.0.1.1/24")
///   ip3 = IPAddress("10.0.2.1/24")
///   ip4 = IPAddress("10.0.3.1/24")
///
///   IPAddress::IPv4::summarize(ip1,ip2,ip3,ip4).to_string
///     ///  "10.0.0.0/22",
///
/// But the following networks can't be summarized in a single network:
///
///   ip1 = IPAddress("10.0.1.1/24")
///   ip2 = IPAddress("10.0.2.1/24")
///   ip3 = IPAddress("10.0.3.1/24")
///   ip4 = IPAddress("10.0.4.1/24")
///
///   IPAddress::IPv4::summarize(ip1,ip2,ip3,ip4).map{|i| i.to_string}
///     ///  ["10.0.1.0/24","10.0.2.0/23","10.0.4.0/24"]
///
///
///  Summarization (or aggregation) is the process when two or more
///  networks are taken together to check if a supernet, including all
///  and only these networks, exists. If it exists then this supernet
///  is called the summarized (or aggregated) network.
///
///  It is very important to understand that summarization can only
///  occur if there are no holes in the aggregated network, or, in other
///  words, if the given networks fill completely the address space
///  of the supernet. So the two rules are:
///
///  1) The aggregate network must contain +all+ the IP addresses of the
///     original networks;
///  2) The aggregate network must contain +only+ the IP addresses of the
///     original networks;
///
///  A few examples will help clarify the above. Let's consider for
///  instance the following two networks:
///
///    ip1 = IPAddress("2000:0::4/32")
///    ip2 = IPAddress("2000:1::6/32")
///
///  These two networks can be expressed using only one IP address
///  network if we change the prefix. Let Ruby do the work:
///
///    IPAddress::IPv6::summarize(ip1,ip2).to_s
///      ///  "2000:0::/31"
///
///  We note how the network "2000:0::/31" includes all the addresses
///  specified in the above networks, and (more important) includes
///  ONLY those addresses.
///
///  If we summarized +ip1+ and +ip2+ with the following network:
///
///    "2000::/16"
///
///  we would have satisfied rule /// 1 above, but not rule /// 2. So "2000::/16"
///  is not an aggregate network for +ip1+ and +ip2+.
///
///  If it's not possible to compute a single aggregated network for all the
///  original networks, the method returns an array with all the aggregate
///  networks found. For example, the following four networks can be
///  aggregated in a single /22:
///
///    ip1 = IPAddress("2000:0::/32")
///    ip2 = IPAddress("2000:1::/32")
///    ip3 = IPAddress("2000:2::/32")
///    ip4 = IPAddress("2000:3::/32")
///
///    IPAddress::IPv6::summarize(ip1,ip2,ip3,ip4).to_string
///      ///  ""2000:3::/30",
///
///  But the following networks can't be summarized in a single network:
///
///    ip1 = IPAddress("2000:1::/32")
///    ip2 = IPAddress("2000:2::/32")
///    ip3 = IPAddress("2000:3::/32")
///    ip4 = IPAddress("2000:4::/32")
///
///    IPAddress::IPv4::summarize(ip1,ip2,ip3,ip4).map{|i| i.to_string}
///      ///  ["2000:1::/32","2000:2::/31","2000:4::/32"]
///

func Sum_first_found(arr *[]*IPAddress) *[]*IPAddress {
	var dup []*IPAddress
	copy(dup[:], *arr)
	if len(dup) < 2 {
		return &dup
	}
	for i := len(dup) - 1; i >= 0; i-- {
		a := Summarize(&[]*IPAddress{dup[i], dup[i+1]})
		// fmt.Printf("dup:{}:{}:{}", dup.len(), i, a.len());
		if len(*a) == 1 {
			dup[i] = (*a)[0].Clone()
			dup = remove_ipaddress(dup, i+1)
			break
		}
	}
	return &dup
}

func Summarize(networks *[]*IPAddress) *[]*IPAddress {
	return Aggregate(networks)
}
func Summarize_str(netstr []string) ResultIPAddresses {
	vec := To_ipaddress_vec(netstr)
	if vec.IsErr() {
		fmt.Printf("Summarize_str:%s:[%s]\n", vec.UnwrapErr(), netstr)
		return vec
	}
	fmt.Printf("Summarize_str:Aggregate:0:%s:%s\n", netstr, vec.Unwrap())
	tmp := Aggregate(vec.Unwrap())
	fmt.Printf("Summarize_str:Aggregate:1:%s:%s\n", netstr, vec.Unwrap())
	return &Oks{tmp}
}

func To_s_vec(vec *[]IPAddress) []string {
	var ret []string
	for _, i := range *vec {
		ret = append(ret, i.To_s())
	}
	return ret
}

func To_string_vec(vec *[]*IPAddress) []string {
	var ret []string
	for _, i := range *vec {
		ret = append(ret, i.To_string())
	}
	return ret
}

func To_ipaddress_vec(vec []string) ResultIPAddresses {
	ret := []*IPAddress{}
	for _, ipstr := range vec {
		ipa := Parse(ipstr)
		if ipa.IsErr() {
			fmt.Printf("To_ipaddress_vec:Err:%s\n", ipa.UnwrapErr())
			return &Errors{ipa.UnwrapErr()}
		}
		fmt.Printf("To_ipaddress_vec:%s:%s:%s\n", ipstr,
			ipa.Unwrap().To_string(),
			ipa.Unwrap())
		ret = append(ret, ipa.Unwrap())
	}
	return &Oks{&ret}
}
