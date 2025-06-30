import 'package:result_monad/result_monad.dart';

import 'IPAddress.dart';
import 'IpBits.dart';
import 'IpV6.dart';
import 'Prefix128.dart';
import 'Prefix32.dart';

class IpV4 {
  static bool ipv4_is_private(IPAddress my) {
    return [
          IPAddress.parse("10.0.0.0/8").value,
          IPAddress.parse("169.254.0.0/16").value,
          IPAddress.parse("172.16.0.0/12").value,
          IPAddress.parse("192.168.0.0/16").value
        ].indexWhere((i) => i.includes(my)) >=
        0;
  }

  static bool ipv4_is_loopback(IPAddress my) {
    return IPAddress.parse("127.0.0.0/8").value.includes(my);
  }

  static IPAddress to_ipv6(IPAddress ia) {
    return IPAddress(
        IpBits.V6,
        ia.host_address,
        Prefix128.create(ia.prefix.num).value,
        null,
        IpV6.ipv6_is_private,
        IpV6.ipv6_is_loopback,
        IpV6.ipv6_to_ipv6);
  }

  static Result<IPAddress, String> from_u32(int addr, int _prefix) {
    final prefix = Prefix32.create(_prefix);
    if (prefix.isFailure) {
      return Result.error(prefix.error);
    }
    return Result.ok(IPAddress(IpBits.v4(), BigInt.from(addr), prefix.value,
        null, ipv4_is_private, ipv4_is_loopback, to_ipv6));
  }

  static Result<IPAddress, String> create(String str) {
    final splitted = IPAddress.split_at_slash(str);
    if (!IPAddress.is_valid_ipv4(splitted.addr)) {
      return Result.error("IpV4-create: Invalid IP ${str}");
    }
    var ip_prefix_num = Result.ok(32);
    if (splitted.netmask != null) {
      //  netmask is defined
      ip_prefix_num = IPAddress.parse_netmask_to_prefix(splitted.netmask!);
      if (ip_prefix_num.isFailure) {
        return Result.error(ip_prefix_num.error);
      }
      //if ip_prefix.ip_bits.version
    }
    final ip_prefix = Prefix32.create(ip_prefix_num.value);
    if (ip_prefix.isFailure) {
      return Result.error(ip_prefix.error);
    }
    final split_u32 = IPAddress.split_to_u32(splitted.addr);
    if (split_u32.isFailure) {
      return Result.error(split_u32.error);
    }
    return Result.ok(IPAddress(IpBits.V4, BigInt.from(split_u32.value),
        ip_prefix.value, null, ipv4_is_private, ipv4_is_loopback, to_ipv6));
  }

  // pub fn is_private(my: &IPAddress) -> bool {
  //     for i in vec![IPv4::new("10.0.0.0/8"),

  //                   IPv4::new("172.16.0.0/12"),

  //                   IPv4::new("192.168.0.0/16")] {

  //         if my.includes(&i) {

  //             return true;

  //         }

  //     }
  //     return false;

  // }

  // pub fn dns_reverse(my: &IPAddress) {

  //     let parts = self.ip_bits.parts(&my.host_address);

  //     return String.format("{}.{}.{}.{}.in-addr.arpa",
  //                    parts.get(3),

  //                    parts.get(2),

  //                    parts.get(1),

  //                    parts.get(0));

  // }

  // pub fn to_ipv4_str(value: u32) {

  //   String.format("{}.{}.{}.{}",

  //       (value >> 24) & 0xff,

  //       (value >> 16) & 0xff,

  //       (value >> 8) & 0xff,

  //        value & 0xff)

  // }

  //  Returns the address portion of the IPv4 object

  //  as a string.
  //

  //    ip = IPAddress("172.16.100.4/22")
  //

  //    ip.address

  //      // => "172.16.100.4"
  //
  // pub fn address(&self) {

  //   return self.address
  // }

  //  Returns the prefix portion of the IPv4 object

  //  as a IPAddress::Prefix32 object

  //

  //    ip = IPAddress("172.16.100.4/22")
  //

  //    ip.prefix

  //      // => 22

  //

  //    ip.prefix.class
  //      // => IPAddress::Prefix32
  //

  // pub fn prefix(&self) {

  //   return self.prefix
  // }

  //  Set a prefix number for the object
  //

  //  This is useful if you want to change the prefix

  //  to an object created with IPv4::parse_u32 or

  //  if the object was created using the classful

  //  mask.
  //

  //    ip = IPAddress("172.16.100.4")
  //

  //    puts ip

  //      // => 172.16.100.4/16
  //

  //    ip.prefix = 22
  //

  //    puts ip

  //      // => 172.16.100.4/22
  //

  // pub fn set_prefix(&mut self, num: u8) {

  //   self.prefix = Prefix32::new(num)
  // }

  //  Returns the address as an array of decimal values
  //

  //    ip = IPAddress("172.16.100.4")
  //
  //    ip.octets

  //      // => [172, 16, 100, 4]
  //
  // pub fn octets(&self) {

  //   self.octets
  // }

  //  Returns a string with the address portion of
  //  the IPv4 object
  //

  //    ip = IPAddress("172.16.100.4/22")

  //
  //    ip.to_s

  //      // => "172.16.100.4"
  //

  // pub fn to_s(&self) {

  //   self.address

  // }

  // pub fn compressed(&self) {

  //   self.address
  // }

  //  Returns a string with the IP address in canonical
  //  form.
  //

  //    ip = IPAddress("172.16.100.4/22")
  //

  //    ip.to_string

  //      // => "172.16.100.4/22"

  //

  // pub fn to_string(&self) {

  //   String.format("{}/{}", self.address.to_s, self.prefix.to_s)
  // }

  //  Returns the prefix as a string in IP format

  //

  //    ip = IPAddress("172.16.100.4/22")
  //

  //    ip.netmask
  //      // => "255.255.252.0"
  //

  // pub fn netmask(&self) {
  //   self.prefix.to_ip()
  // }

  //  Like IPv4// prefix=, this method allow you to

  //  change the prefix / netmask of an IP address
  //  object.
  //

  //    ip = IPAddress("172.16.100.4")
  //
  //    puts ip

  //      // => 172.16.100.4/16
  //

  //    ip.netmask = "255.255.252.0"
  //

  //    puts ip

  //      // => 172.16.100.4/22
  //

  // pub fn set_netmask(&self, addr: &String) {

  //   self.prefix = Prefix32::parse_netmask_to_prefix(addr)
  // }
  //
  //

  //  Returns the address portion in unsigned
  //  32 bits integer format.
  //

  //  This method is identical to the C function

  //  inet_pton to create a 32 bits address family

  //  structure.
  //
  //    ip = IPAddress("10.0.0.0/8")
  //

  //    ip.to_i
  //      // => 167772160
  //

  // pub fn u32() {

  //   self.ip32
  // }
  // pub fn to_i() {

  //   self.ip32
  // }

  // pub fn to_u32() {

  //   self.ip32
  // }
  //

  //  Returns the address portion of an IPv4 object

  //  in a network byte order format.
  //

  //    ip = IPAddress("172.16.10.1/24")
  //

  //    ip.data
  //      // => "\254\020\n\001"
  //

  //  It is usually used to include an IP address

  //  in a data packet to be sent over a socket
  //

  //    a = Socket.open(params) //  socket details here
  //    ip = IPAddress("10.1.1.0/24")

  //    binary_data = ["Address: "].pack("a*") + ip.data

  //
  //    //  Send binary data
  //    a.puts binary_data
  //

  // pub fn data(&self) {

  //   self.ip32
  // }

  //  Returns the octet specified by index
  //

  //    ip = IPAddress("172.16.100.50/24")
  //
  //    ip[0]

  //      // => 172
  //    ip[1]

  //      // => 16

  //    ip[2]
  //      // => 100
  //    ip[3]

  //      // => 50
  //
  // pub fn get(&self, index: u8) {

  //   self.octets.get(index)
  // }

  // pub fn octet(&self, index: u8) {

  //   self.octets.get(index)
  // }

  //  Returns the address portion of an IP in binary format,

  //  as a string containing a sequence of 0 and 1
  //

  //    ip = IPAddress("127.0.0.1")
  //

  //    ip.bits

  //      // => "01111111000000000000000000000001"
  //
  // pub fn bits(&self) {

  //   self.ip32.to_string()
  // }

  //  Returns the broadcast address for the given IP.
  //

  //    ip = IPAddress("172.16.10.64/24")
  //
  //    ip.broadcast.to_s

  //      // => "172.16.10.255"
  //

  // pub fn broadcast(&self) {

  //   IPv4::parse_u32(self.broadcast_u32, self.prefix)
  // }

  //  Checks if the IP address is actually a network
  //

  //    ip = IPAddress("172.16.10.64/24")
  //
  //    ip.network?

  //      // => false
  //

  //    ip = IPAddress("172.16.10.64/26")
  //
  //    ip.network?

  //      // => true
  //
  // pub fn is_network() {

  //   (self.prefix.num < 32) && (self.ip32 | self.prefix.to_u32 == self.prefix.to_u32)
  // }

  //  Returns a IPv4 object with the network number
  //  for the given IP.
  //

  //    ip = IPAddress("172.16.10.64/24")
  //

  //    ip.network.to_s

  //      // => "172.16.10.0"
  //
  // pub fn network()

  //   self.class.parse_u32(self.network_u32, prefix)
  //

  //  Returns a IPv4 object with the

  //  first host IP address in the range.
  //

  //  Example: given the 192.168.100.0/24 network, the first

  //  host IP address is 192.168.100.1.
  //

  //    ip = IPAddress("192.168.100.0/24")
  //
  //    ip.first.to_s

  //      // => "192.168.100.1"
  //

  //  The object IP doesn't need to be a network: the method

  //  automatically gets the network number from it
  //

  //    ip = IPAddress("192.168.100.50/24")
  //

  //    ip.first.to_s
  //      // => "192.168.100.1"
  //

  // pub fn first(&self) {

  //   IPv4::parse_u32(self.network_u32+1, self.prefix)
  // }

  //  Like its sibling method IPv4// first, this method
  //  returns a IPv4 object with the

  //  last host IP address in the range.
  //

  //  Example: given the 192.168.100.0/24 network, the last

  //  host IP address is 192.168.100.254
  //

  //    ip = IPAddress("192.168.100.0/24")
  //

  //    ip.last.to_s
  //      // => "192.168.100.254"
  //

  //  The object IP doesn't need to be a network: the method

  //  automatically gets the network number from it
  //
  //    ip = IPAddress("192.168.100.50/24")
  //

  //    ip.last.to_s

  //      // => "192.168.100.254"
  //
  // pub fn last(&self) {

  //   IPv4::parse_u32(self.broadcast_u32-1, self.prefix)
  // }
  //
  //

  //  Iterates over all the hosts IP addresses for the given

  //  network (or IP address).
  //

  //    ip = IPAddress("10.0.0.1/29")
  //
  //    ip.each_host do |i|

  //      p i.to_s
  //    end

  //      // => "10.0.0.1"

  //      // => "10.0.0.2"

  //      // => "10.0.0.3"
  //      // => "10.0.0.4"
  //      // => "10.0.0.5"

  //      // => "10.0.0.6"
  //
  // pub fn each_host(&self, fn: ) {

  //   (self.network_u32+1..self.broadcast_u32-1).each do |i|

  //     yield self.class.parse_u32(i, @prefix)
  //   end
  // }

  //  Iterates over all the IP addresses for the given

  //  network (or IP address).
  //

  //  The object yielded is a IPv4 object created

  //  from the iteration.
  //

  //    ip = IPAddress("10.0.0.1/29")
  //
  //    ip.each do |i|

  //      p i.address
  //    end
  //      // => "10.0.0.0"

  //      // => "10.0.0.1"
  //      // => "10.0.0.2"

  //      // => "10.0.0.3"

  //      // => "10.0.0.4"
  //      // => "10.0.0.5"

  //      // => "10.0.0.6"

  //      // => "10.0.0.7"
  //
  // pub fn each(&self) {

  //   (self.network_u32..self.broadcast_u32).each do |i|

  //     yield self.class.parse_u32(i, @prefix)
  //   end

  // }

  //  Spaceship operator to compare IPv4 objects
  //

  //  Comparing IPv4 addresses is useful to ordinate

  //  them into lists that match our intuitive

  //  perception of ordered IP addresses.
  //

  //  The first comparison criteria is the u32 value.

  //  For example, 10.100.100.1 will be considered

  //  to be less than 172.16.0.1, because, in a ordered list,

  //  we expect 10.100.100.1 to come before 172.16.0.1.
  //

  //  The second criteria, in case two IPv4 objects

  //  have identical addresses, is the prefix. An higher

  //  prefix will be considered greater than a lower

  //  prefix. This is because we expect to see

  //  10.100.100.0/24 come before 10.100.100.0/25.
  //
  //  Example:
  //

  //    ip1 = IPAddress "10.100.100.1/8"

  //    ip2 = IPAddress "172.16.0.1/16"
  //    ip3 = IPAddress "10.100.100.1/16"
  //

  //    ip1 < ip2
  //      // => true
  //    ip1 > ip3

  //      // => false
  //

  //    [ip1,ip2,ip3].sort.map{|i| i.to_string}

  //      // => ["10.100.100.1/8","10.100.100.1/16","172.16.0.1/16"]
  //

  // pub fn cmp(&self, oth: IPv4) {

  //   if self.to_u32() == oth.to_u32() {

  //     return self.prefix.num - oth.prefix.num

  //   }
  //   self.to_u32() - oth.to_u32()

  // }

  //  Returns the number of IP addresses included

  //  in the network. It also counts the network

  //  address and the broadcast address.
  //

  //    ip = IPAddress("10.0.0.1/29")
  //
  //    ip.size
  //      // => 8
  //
  // pub fn size(&self) {

  //   2 ** self.prefix.host_prefix()
  // }

  //  Returns an array with the IP addresses of
  //  all the hosts in the network.
  //

  //    ip = IPAddress("10.0.0.1/29")
  //

  //    ip.hosts.map {|i| i.address}
  //      // => ["10.0.0.1",

  //      // =>  "10.0.0.2",
  //      // =>  "10.0.0.3",

  //      // =>  "10.0.0.4",

  //      // =>  "10.0.0.5",
  //      // =>  "10.0.0.6"]

  //

  // pub fn hosts(&self) {

  //   self.to_a[1..-2]
  // }

  //  Returns the network number in Unsigned 32bits format
  //
  //    ip = IPAddress("10.0.0.1/29")
  //

  //    ip.network_u32

  //      // => 167772160
  //
  // pub fn network_u32(&self) {

  //   self.ip32 & self.prefix.to_u32()

  // }

  //  Returns the broadcast address in Unsigned 32bits format
  //

  //    ip = IPaddress("10.0.0.1/29")
  //

  //    ip.broadcast_u32

  //      // => 167772167
  //

  // pub fn broadcast_u32(&self) {

  //   self.network_u32 + self.size - 1
  // }

  //  Checks whether a subnet includes the given IP address.
  //

  //  Accepts an IPAddress::IPv4 object.
  //

  //    ip = IPAddress("192.168.10.100/24")

  //

  //    addr = IPAddress("192.168.10.102/24")
  //
  //    ip.include? addr

  //      // => true
  //
  //    ip.include? IPAddress("172.16.0.48/16")

  //      // => false
  //

  // pub fn include?(&self, oth: IPv4) {

  //   self.prefix.num <= oth.prefix.num &&

  //   self.network_u32 == (oth.to_u32() & self.prefix.to_u32())
  // }

  //  Checks whether a subnet includes all the
  //  given IPv4 objects.

  //

  //    ip = IPAddress("192.168.10.100/24")
  //

  //    addr1 = IPAddress("192.168.10.102/24")

  //    addr2 = IPAddress("192.168.10.103/24")

  //

  //    ip.include_all?(addr1,addr2)

  //      // => true
  //
  // pub fn include_all?(*others)

  //   others.all? {|oth| include?(oth)}
  // end

  //  Checks if an IPv4 address objects belongs

  //  to a private network RFC1918
  //
  //  Example:
  //
  //    ip = IPAddress "10.1.1.1/24"

  //    ip.private?
  //      // => true
  //

  //  Returns the IP address in in-addr.arpa format
  //  for DNS lookups
  //

  //    ip = IPAddress("172.16.100.50/24")
  //
  //    ip.reverse

  //      // => "50.100.16.172.in-addr.arpa"
  //

  // pub fn reverse(&self) {

  //    return String.format("{}.{}.{}.{}.in-addr.arpa",

  //      self.octets.get(3), self.octets.get(2),

  //      self.octets.get(1), self.octets.get(0))
  // }
  // pub fn arpa(&self) {

  //     return self.reverse()

  // }

  //  Returns the IP address in in-addr.arpa format

  //  for DNS Domain definition entries like SOA Records
  //

  //    ip = IPAddress("172.17.100.50/15")
  //

  //    ip.dns_rev_domains

  //      // => ["16.172.in-addr.arpa","17.172.in-addr.arpa"]
  //

  // pub fn dns_rev_domains(&self) {

  //   let mut net = [ self.network ]

  //   let mut cut = 4 - (self.prefix.num/8)

  //   if (self.prefix.num <= 8) { //  edge case class a

  //     cut = 3

  // } else if (self.prefix.num > 24) { //  edge case class c

  //     cut = 1

  //     net = [network.supernet(24)]
  // }

  // if (self.prefix.num < 24 && (self.prefix.num % 8) != 0) { //  case class less

  //     cut = 3-(self.prefix.num/8)

  //     net = network.subnet(self.prefix.num+1)
  // }

  // return net.map(|n| n.reverse.split('.')[cut .. -1].join('.'))

  // }

  //  Splits a network into different subnets
  //

  //  If the IP Address is a network, it can be divided into

  //  multiple networks. If +self+ is not a network, this

  //  method will calculate the network from the IP and then
  //  subnet it.
  //

  //  If +subnets+ is an power of two number, the resulting

  //  networks will be divided evenly from the supernet.
  //

  //    network = IPAddress("172.16.10.0/24")
  //

  //    network / 4   //  implies map{|i| i.to_string}

  //      // => ["172.16.10.0/26",
  //           "172.16.10.64/26",

  //           "172.16.10.128/26",
  //           "172.16.10.192/26"]
  //

  //  If +num+ is any other number, the supernet will be

  //  divided into some networks with a even number of hosts and

  //  other networks with the remaining addresses.
  //

  //    network = IPAddress("172.16.10.0/24")
  //

  //    network / 3   //  implies map{|i| i.to_string}
  //      // => ["172.16.10.0/26",

  //           "172.16.10.64/26",
  //           "172.16.10.128/25"]
  //

  //  Returns an array of IPv4 objects
  //

  // pub fn split(my : &IPAddress, subnets: usize) {

  //   if subnets <= 1 || (1<<self.prefix.host_prefix()) <= subnets {

  //      return Err(String.format("Value {} out of range", subnets))
  //   }

  //   let mut networks = self.subnet(self.newprefix(subnets))

  //   if (networks.len() != subnets) {

  //     networks = sum_first_found(networks)
  //   }
  //   return networks
  // }

  // alias_method :/, :split

  //  Returns a IPv4 object from the supernetting

  //  of the instance network.
  //

  //  Supernetting is similar to subnetting, except

  //  that you getting as a result a network with a

  //  smaller prefix (bigger host space). For example,

  //  given the network
  //
  //    ip = IPAddress("172.16.10.0/24")
  //

  //  you can supernet it with a /23 prefix
  //

  //    ip.supernet(23).to_string
  //      // => "172.16.10.0/23"
  //

  //  However if you supernet it with a /22 prefix, the

  //  network address will change:
  //

  //    ip.supernet(22).to_string

  //      // => "172.16.8.0/22"
  //

  //  If +new_prefix+ is less than 1, returns 0.0.0.0/0
  //

  // pub fn supernet(&self, new_prefix: u8) {
  //     if (new_prefix >= self.prefix.num) {

  //         return Err(String.format("prefix must be smaller than existing prefix: {} >= {}",

  //             new_prefix, self.prefix.num))

  //     }
  //     if new_prefix < 1 {

  //         return Ok(IPv4::new("0.0.0.0/0"))
  //     }

  //     return Ok(IPv4::new(String.format("{}/{}", self.address, self.prefix.num)))

  // }

  //  This method implements the subnetting function

  //  similar to the one described in RFC3531.
  //

  //  By specifying a prefix, the method calculates

  //  the network number for the given IPv4 object

  //  and calculates the subnets associated to the new
  //  prefix.

  //

  //  For example, given the following network:
  //
  //    ip = IPAddress "172.16.10.0/24"
  //

  //  we can calculate the subnets with a /26 prefix
  //

  //    ip.subnets(26).map(&:to_string)

  //      // => ["172.16.10.0/26", "172.16.10.64/26",

  //           "172.16.10.128/26", "172.16.10.192/26"]
  //

  //  The resulting number of subnets will of course always be

  //  a power of two.
  //

  // pub fn subnet(&self, subprefix: u8) {

  //   if (subprefix <= self.prefix.num || 32 <= subprefix) {

  //     return Err(String.format("prefix must be between {} and 32", subprefix))

  //   }
  //   let mut ret = Vec::new();

  //   for (i = 0; i < (1 << (subprefix-self.prefix.num)); ++i) {

  //     ret.push(IPv4::parse_u32(self.network_u32+(i*(1<<(32-subprefix))), subprefix));
  //   }
  //   return ret
  // }

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
  static final BigInt x80000000 = BigInt.from(2147483648);
  static final BigInt xc0000000 = BigInt.from(3221225472);
  static final BigInt xe0000000 = BigInt.from(3758096384);

  static bool is_class_a(IPAddress my) {
//      const ret = my.host_address.compareTo(x80000000)
    return my.is_ipv4() && my.host_address.compareTo(x80000000) < 0;
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
  static bool is_class_b(IPAddress my) {
    return my.is_ipv4() &&
        x80000000.compareTo(my.host_address) <= 0 &&
        my.host_address.compareTo(xc0000000) < 0;
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

  static bool is_class_c(IPAddress my) {
    return my.is_ipv4() &&
        xc0000000.compareTo(my.host_address) <= 0 &&
        my.host_address.compareTo(xe0000000) < 0;
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

  // pub fn to_ipv6(my: &IPAddress) {

  //     let part_mod = BigUint::one() << 16;

  //     return String.format("{:04x}:{:04x}",

  //                    (my.host_address >> 16).mod_floor(&part_mod).to_u16().value,

  //                    my.host_address.mod_floor(&part_mod).to_u16().value);
  // }

  //  Creates a IPv4 object from an
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

  // pub fn parse_u32(ip32: u32, prefix: u8) {

  //   IPv4::new(String.format("{}/{}", IPv4::to_ipv4_str(ip32), prefix))
  // }

  //  Creates a IPv4 object from binary data,

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

  // pub fn self.parse_data(str, prefix=32)

  //   self.new(str.unpack("C4").join(".")+"/// {prefix}")
  // end

  //  Extract an IPv4 address from a string and
  //  returns a object
  //
  //  Example:
  //

  //    str = "foobar172.16.10.1barbaz"

  //    ip = IPAddress::IPv4::extract str
  //
  //    ip.to_s

  //      // => "172.16.10.1"
  //
  // pub fn self.extract(str) {

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

  // pub fn self.summarize(args)
  //   IPAddress.summarize(args)
  // end

  //  Creates a IPv4 address object by parsing the
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
  static Result<IPAddress, String> parse_classful(String ip_s) {
    if (!IPAddress.is_valid_ipv4(ip_s)) {
      return Result.error("parse_classful: Invalid IP ${ip_s}");
    }
    final o_ip = IPAddress.parse(ip_s);
    if (o_ip.isFailure) {
      return o_ip;
    }
    final ip = o_ip.value;
    if (IpV4.is_class_a(ip)) {
      return IPAddress.parse("${ip.to_s()}/8");
    } else if (IpV4.is_class_b(ip)) {
      return IPAddress.parse("${ip.to_s()}/16");
    } else if (IpV4.is_class_c(ip)) {
      return IPAddress.parse("${ip.to_s()}/24");
    }
    return Result.ok(ip);
  }
}
