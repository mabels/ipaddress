package ipaddress_impl

import "strings"

// import "strconv"
import "math/big"

// import "regexp"
import "fmt"

import "../ip_bits"
import "../ip_version"
import "../prefix"
import "bytes"

// import "../ip_version"
// import "../ipaddress"
// import "../ipv4"
// import "../ipv6"

type IPAddress struct {
	Ip_bits                    *ip_bits.IpBits
	Host_address               big.Int
	prefix                     prefix.Prefix
	Mapped                     *IPAddress
	Vt_is_private              func(*IPAddress) bool
	Vt_is_loopback             func(*IPAddress) bool
	Vt_to_ipv6                 func(*IPAddress) IPAddress
	Vt_parse_netmask           func(*string) (*uint8, *string)
	Vt_aggregate               func(*[]IPAddress) []IPAddress
}

func (self *IPAddress) String() string {
	return fmt.Sprintf("IPAddress: %s", self.To_string())
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
	return self.prefix.Cmp(&oth.prefix)
}

func (self *IPAddress) Equal(other IPAddress) bool {
	return self.Ip_bits.Version == other.Ip_bits.Version &&
		self.prefix.Cmp(&other.prefix) == 0 &&
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

func (self *IPAddress) Split_at_slash(str string) (string, *string) {
	trimmed := strings.TrimSpace(str)
	slash := strings.Split(trimmed, "/")
	addr := ""
	if len(slash) >= 1 {
		addr = strings.TrimSpace(slash[0])
	}
	if len(slash) >= 2 {
		tslash := strings.TrimSpace(slash[1])
		return addr, &tslash
	} else {
		return addr, nil
	}
}

func (self *IPAddress) From(addr *big.Int, prefix *prefix.Prefix) IPAddress {
	return IPAddress{
		self.Ip_bits,
		*addr,
		prefix.Clone(),
		self.Mapped,
		self.Vt_is_private,
		self.Vt_is_loopback,
		self.Vt_to_ipv6,
		self.Vt_parse_netmask,
		self.Vt_aggregate}
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

func (self *IPAddress) parts() []uint16 {
	return self.Ip_bits.Parts(self.Host_address)
}

func (self *IPAddress) parts_hex_str() []string {
	var ret []string
	for i := range self.parts() {
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
	for _, net := range self.dns_networks() {
		// println!("dns_rev_domains:{}:{}", self.to_string(), net.to_string());
		ret = append(ret, net.dns_reverse())
	}
	return ret
}

func (self *IPAddress) dns_reverse() string {
	var ret bytes.Buffer
	dot := ""
	dns_parts := self.dns_parts()
	for i := ((self.prefix.Host_prefix() + (self.Ip_bits.Dns_bits - 1)) / self.Ip_bits.Dns_bits); i <= uint8(len(dns_parts)); i++ {
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

func (self *IPAddress) dns_networks() []IPAddress {
	// +self.ip_bits.dns_bits-1
	next_bit_mask := self.Ip_bits.Bits -
		(((self.prefix.Host_prefix()) / self.Ip_bits.Dns_bits) * self.Ip_bits.Dns_bits)
	if next_bit_mask <= 0 {
		return []IPAddress{self.Network()}
	}
	//  println!("dns_networks:{}:{}", self.to_string(), next_bit_mask);
	// dns_bits
	step_bit_net := big.NewInt(0).Lsh(big.NewInt(1), uint(self.Ip_bits.Bits-next_bit_mask))
	if step_bit_net.Cmp(big.NewInt(0)) == 0 {
		return []IPAddress{self.Network()}
	}
	var ret []IPAddress
	step := self.Network().Host_address
	prefix, _ := self.prefix.From(next_bit_mask)
	baddr := self.Broadcast().Host_address
	for baddr.Cmp(&step) > 0 {
		ret = append(ret, self.From(&step, prefix))
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
	return self.Mapped != nil &&
		num.Rsh(&self.Host_address, 32).Cmp(rest.Sub(mask, big.NewInt(1))) == 0
}

///  Returns the prefix portion of the IPv4 object
///  as a IPAddress::Prefix32 object
///
///    ip = IPAddress("172.16.100.4/22")
///
///    ip.prefix
///      ///  22
///
///    ip.prefix.class
///      ///  IPAddress::Prefix32
///

func (self *IPAddress) Prefix() prefix.Prefix {
	return self.prefix
}

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
///    ip.prefix = 22
///
///    puts ip
///      ///  172.16.100.4/22
///
func (self *IPAddress) Change_prefix(num uint8) (*IPAddress, *string) {
	prefix, err := self.prefix.From(num)
	if err != nil {
		return nil, err
	}
	from := self.From(&self.Host_address, prefix)
	return &from, nil
}

func (self *IPAddress) Change_netmask(my_str *string) (*IPAddress, *string) {
	nm, err := self.Vt_parse_netmask(my_str)
	if err == nil {
		return nil, err
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
	ret.WriteString(self.prefix.To_s())
	return ret.String()
}

func (self *IPAddress) To_s() string {
	return self.Ip_bits.As_compressed_string(self.Host_address)
}

func (self *IPAddress) To_string_uncompressed() string {
	var ret bytes.Buffer
	ret.WriteString(self.To_s_uncompressed())
	ret.WriteString("/")
	ret.WriteString(self.prefix.To_s())
	return ret.String()
}

func (self *IPAddress) To_s_uncompressed() string {
	return self.Ip_bits.As_uncompressed_string(self.Host_address)
}

func (self *IPAddress) To_s_mapped() string {
	if self.Is_mapped() {
		return fmt.Sprintf("::ffff:%s", self.Mapped.To_s())
	}
	return self.To_s()
}

func (self *IPAddress) to_string_mapped() string {
	if self.Is_mapped() {
		mapped := self.Mapped
		return fmt.Sprintf("%s/%d",
			self.To_s_mapped(),
			mapped.prefix.Num)
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

func (self *IPAddress) Netmask() IPAddress {
	nm := self.prefix.Netmask()
	return self.From(&nm, &self.prefix)
}

///  Returns the broadcast address for the given IP.
///
///    ip = IPAddress("172.16.10.64/24")
///
///    ip.broadcast.to_s
///      ///  "172.16.10.255"
///

func (self *IPAddress) Broadcast() IPAddress {
	size := self.Size()
  h_a := self.Network().Host_address
	return self.From(big.NewInt(0).Add(&h_a,
		big.NewInt(0).Sub(&size, big.NewInt(1))), &self.prefix)
	// IPv4::parse_u32(self.broadcast_u32, self.prefix)
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
	return self.prefix.Num != self.Ip_bits.Bits &&
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

func (self *IPAddress) Network() IPAddress {
	to_n := To_network(&self.Host_address, self.prefix.Host_prefix())
	return self.From(&to_n, &self.prefix)
}

func To_network(adr *big.Int, host_prefix uint8) big.Int {
	num := big.NewInt(0)
	num.Rsh(adr, uint(host_prefix)).Lsh(num, uint(host_prefix))
  return *num
}

func (self *IPAddress) sub(other *IPAddress) big.Int {
	var ret big.Int
	if self.Host_address.Cmp(&other.Host_address) > 0 {
		return *ret.Sub(&self.Host_address, &other.Host_address)
	}
	return *ret.Sub(&other.Host_address, &self.Host_address)
}

func (self *IPAddress) Add(other *IPAddress) []IPAddress {
	return self.Vt_aggregate(&[]IPAddress{*self, *other})
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
func (self *IPAddress) First() IPAddress {
	ha := self.Network().Host_address
	return self.From(big.NewInt(0).Add(&ha, &self.Ip_bits.Host_ofs), &self.prefix)
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

func (self *IPAddress) Last() IPAddress {
	ha := self.Broadcast().Host_address
	return self.From(big.NewInt(0).Sub(&ha, &self.Ip_bits.Host_ofs), &self.prefix)
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
    ip := self.From(&i, &self.prefix)
		fn(&ip)
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
    ip := self.From(&i, &self.prefix)
		fn(&ip)
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
	ret.Lsh(ret, uint(self.prefix.Host_prefix()))
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
  to_n := To_network(&oth.Host_address, self.prefix.Host_prefix())
  h_a := self.Network().Host_address
	ret := self.Is_same_kind(oth) &&
		self.prefix.Num <= oth.prefix.Num &&
		h_a.Cmp(&to_n) == 0
	// println!("includes:{}=={}=>{}", self.to_string(), oth.to_string(), ret);
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

func (self *IPAddress) Includes_all(oths *[]IPAddress) bool {
	for _, oth := range *oths {
		if !self.Includes(&oth) {
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

func (self *IPAddress) Sum_first_found(arr *[]IPAddress) []IPAddress {
	var dup []IPAddress
	copy(dup[:], *arr)
	if len(dup) < 2 {
		return dup
	}
	for i := len(dup) - 1; i >= 0; i-- {
		a := IPAddress.Summarize([]IPAddress{dup[i].clone(), dup[i+1].clone()})
		// println!("dup:{}:{}:{}", dup.len(), i, a.len());
		if len(a) == 1 {
			dup[i] = a[0].clone()
			remove(dup, i+1)
			break
		}
	}
	return dup
}

func (self *IPAddress) split(subnets uint) (*[]IPAddress, *string) {
	if subnets == 0 || (1<<self.Prefix.Host_prefix()) <= subnets {
		return fmt.Sprintf("Value %s out of range", subnets)
	}
	networks, err := self.Subnet(self.Newprefix(subnets).num)
	if err {
		return nil, err
	}
	net := networks
	for len(net) != subnets {
		net = self.Sum_first_found(net)
	}
	return net, nil
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

func (self *IPAddress) Supernet(new_prefix uint8) (*IPAddress, *string) {
	if new_prefix >= self.Prefix.Num {
		return nil, fmt.Sprintf("New prefix must be smaller than existing prefix: %d >= %d",
			new_prefix,
			self.Prefix.Num)
	}
	// let mut new_ip = self.host_address.clone();
	// for _ in new_prefix..self.prefix.num {
	//     new_ip = new_ip << 1;
	// }
	return self.From(self.Host_address, self.Prefix.From(new_prefix)).Network()
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

func (self *IPAddress) Subnet(subprefix uint8) (*[]IPAddress, string) {
	if subprefix < self.prefix.num || self.ip_bits.bits < subprefix {
		return nil, fmt.Sprintf("New prefix must be between prefix%d %d and %d",
			self.Prefix.Num,
			subprefix,
			self.Ip_bits.Bits)
	}
	var ret []IPAddress
	net := self.Network()
	net.prefix = net.Prefix.From(subprefix)
	for i := 0; i < (1 << (subprefix - self.Prefix.Num)); i++ {
		ret = append(ret, net.clone())
		net = net.From(net.Host_address, net.Prefix)
		size := net.Size()
		net.Host_address = net.Host_address + size
	}
	return ret, nil
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

func (self *IPAddress) to_ipv6() IPAddress {
	return (self.vt_to_ipv6)(self)
}

//  private methods
//

func (self *IPAddress) Newprefix(num uint) (*prefix.Prefix, *string) {
	for i := num; i < self.Ip_bits.Bits; i++ {
		a := float(uint(math.log2(float64(i))))
		if a == Math.log2(float(i)) {
			return self.Prefix.Add(uint(a))
		}
	}
	return nil, fmt.Sprintf("newprefix not found %d:%d", num, self.Ip_bits.Bits)
}
