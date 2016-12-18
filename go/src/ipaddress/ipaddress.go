package ipaddress

import "strings"
import "math/big"
import "regexp"
import "fmt"

import "../ip_bits"
import "../ip_version"
import "../prefix"
// import "../ipv4"
// import "../ipv6"

type IPAddress struct {
    Ip_bits *ip_bits.IpBits
    Host_address big.Int
    prefix prefix.Prefix
    Mapped *IPAddress
    Vt_is_private func(*IPAddress) bool
    Vt_is_loopback func(*IPAddress) bool
    Vt_to_ipv6 func(*IPAddress) IPAddress
}

var re_MAPPED = regexp.MustCompile(":.+\\.");
var re_IPV4 = regexp.MustCompile("\\.");
var re_IPV6 = regexp.MustCompile(":");


func(self *IPAddress) String() string {
  return fmt.Sprintf("IPAddress: %s", self.To_string());
}


func (self *IPAddress) cmp(oth IPAddress) int {
    if self.Ip_bits.Version != oth.Ip_bits.Version {
        if self.Ip_bits.Version == ip_version.V6 {
          return 1
        }
        return -1
    }
    //let adr_diff = self.host_address - oth.host_address;
    if self.Host_address.Cmp(&oth.Host_address) < 0  {
      return -1
    } else if self.Host_address.Cmp(&oth.Host_address) > 0 {
      return 1
    }
    return self.prefix.Cmp(&oth.prefix);
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
  func Parse(str string) (*IPAddress, *string) {
      if re_MAPPED.MatchString(str) {
          // println!("mapped:{}", string);
          return ipv6_mapped.New(str), nil;
      } else {
          if re_IPV4.MatchString(str) {
              // println!("ipv4:{}", string);
              return ipv4.New(str), nil;
          } else if re_IPV6.MatchString(str) {
              // println!("ipv6:{}", string);
              return ipv6.New(str), nil;
          }
      }
      return _, fmt.Sprintf("Unknown IP Address %s", str);
  }

  func (self *IPAddress) Split_at_slash(str string) (string, *string) {
      slash := strings.Split(strings.TrimSpace(), "/")
      addr := "";
      if len(slash) >= 1 {
        addr = strings.TrimSpace(slash[0])
      }
      if len(slash) >= 2 {
          return addr, strings.TrimSpace(slash[1])
      } else {
          return addr, nil
      }
  }

  func (self *IPAddress) From(addr big.Int, prefix prefix.Prefix) IPAddress {
      return IPAddress {
          self.Ip_bits,
          addr.clone(),
          prefix.clone(),
          self.Mapped,
          self.Vt_is_private,
          self.Vt_is_loopback,
          self.Vt_to_ipv6};
  }

  /// True if the object is an IPv4 address
  ///
  ///   ip = IPAddress("192.168.10.100/24")
  ///
  ///   ip.ipv4?
  ///     //-> true
  ///
  func (self *IPAddress) Is_ipv4() bool {
      return self.ip_bits.version == IpVersion.V4
  }

  /// True if the object is an IPv6 address
  ///
  ///   ip = IPAddress("192.168.10.100/24")
  ///
  ///   ip.ipv6?
  ///     //-> false
  ///
  func (self *IPAddress) Is_ipv6() bool {
    return self.ip_bits.version == IpVersion.V6
  }

  /// Checks if the given string is a valid IP address,
  /// either IPv4 or IPv6
  ///
  /// Example:
  ///
  ///  IPAddress::valid? "2002::1"
  ///    //=> true
  ///
  ///  IPAddress::valid? "10.0.0.256"
  ///    //=> false
  ///
  func Is_valid(addr string) bool {
      return IPAddress.Is_valid_ipv4(addr) || IPAddress.Is_valid_ipv6(addr);
  }



  /// Checks if the given string is a valid IPv4 address
  ///
  /// Example:
  ///
  ///   IPAddress::valid_ipv4? "2002::1"
  ///     //=> false
  ///
  ///   IPAddress::valid_ipv4? "172.16.10.1"
  ///     //=> true
  ///
  func parse_ipv4_part(i string, addr string) (*uint32, *string) {
      part, err := strconv.ParseUint(i, 10, 32)
      if err {
          return nil, fmt.Sprintf("IP must contain numbers %s", addr);
      }
      part_num := part
      if part_num >= 256 {
          return nil, fmt.Sprintf("IP items has to lower than 256. %s", addr);
      }
      return part_num, nil;
  }

  func split_to_u32(addr string) (*uint32, *string) {
      ip := 0
      shift := 24
      split_addr := strings.Split(strings.TrimSpace(addr), ".")
      split_addr_len := len(split_add);
      if split_addr_len > 4 {
          return nil, fmt.Sprintf("IP has not the right format:%s", addr);
      }
      if split_addr_len < 4 {
          part, err := parse_ipv4_part(split_addr[split_addr_len-1], addr);
          if err {
              return nil, err
          }
          ip := part
          split_addr = append(split_addr, split_addr_len-1);
      }
      for _,i := range split_addr {
          part, err := parse_ipv4_part(i, addr)
          if err {
              return nil, err
          }
          // println!("{}-{}", part_num, shift);
          ip = ip | (part << shift)
          shift -= 8
      }
      return ip, nil;
  }

  func Is_valid_ipv4(addr string) bool {
      _, err := split_to_u32(addr);
      return err != nil
  }


  /// Checks if the given string is a valid IPv6 address
  ///
  /// Example:
  ///
  ///   IPAddress::valid_ipv6? "2002::1"
  ///     //=> true
  ///
  ///   IPAddress::valid_ipv6? "2002::DEAD::BEEF"
  ///     // => false
  ///
  func split_on_colon(addr string) (*big.Int, *string, uint) {
      parts := strings.Split(strings.TrimSpace(addr), ":")
      ip := big.NewInt(0)
      parts_len := len(parts)
      if parts_len == 1 && parts[0] != "" {
          return ip, nil, 0
      }
      shift := ((parts_len - 1) * 16);
      for _, i := range parts {
          part, err := strcov.ParseUint(i, 16, 32)
          if err {
              return nil, fmt.Sprintf("IP must contain hex numbers %s->%s", addr, i), 0;
          }
          part_num := part
          if part_num >= 65536 {
              return nil, fmt.Sprintf("IP items has to lower than 65536. %s", addr), 0;
          }
          bi_part_num = bigInt.new(part_num)
          bi_part_num = bigInt.Lsh(bi_part_num, shift)
          ip = bigInt.Add(ip, bi_part_num)
          shift -= 16
      }
      return ip, nil, parts_len
  }
  func split_to_num(addr string) (*big.Int, *string) {
      //let mut ip = 0;
      pre_post := strings.Split(strings.TrimSpace(addr), "::");
      if len(pre_post) > 2 {
          return nil, fmt.Sprintf("IPv6 only allow one :: %s", addr);
      }
      if len(pre_post) == 2 {
          //println!("{}=::={}", pre_post[0], pre_post[1]);
          pre, err, pre_parts := split_on_colon(pre_post[0])
          if err != nil {
              return nil, err
          }
          post, err, _ := split_on_colon(pre_post[1])
          if err != nil {
              return nil, err;
          }
          // println!("pre:{} post:{}", pre_parts, post_parts);
          return bigInt.Add(bigInt.Lsh(prep, 128 - (pre_parts * 16)), post)
      }
      //println!("split_to_num:no double:{}", addr);
      ret, err, parts = split_on_colon(addr);
      if parts != 128/16 {
          return nil, fmt.Sprintf("incomplete IPv6");
      }
      return ret, nil;
  }

  func is_valid_ipv6(addr string) bool {
      _, err, _ := split_to_num(addr)
      return err != nil
  }


  /// private helper for summarize
  /// assumes that networks is output from reduce_networks
  /// means it should be sorted lowers first and uniq
  ///

  func pos_to_idx(pos int32, len int32) uint32 {
      ilen := len
      // let ret = pos % ilen;
      rem := ((pos % ilen) + ilen) % ilen;
      // println!("pos_to_idx:{}:{}=>{}:{}", pos, len, ret, rem);
      return rem
  }

  type ipaddressSorter struct {
    ipaddress []IPAddress
  	by      func(ip1, ip2 *IPAddress) bool // Closure used in the Less method.
  }


  func sort(ips []IPAddress) {
  	s := &ipaddressSorter{
  		ips: ips,
  		by:  func(ip1, ip2 *IPAddress) bool {
		      return cmp(ip1, ip2) < 0
	    }}
  	sort.Sort(s)
  }

  func remove(stack []IPAddress, idx uint) []IPAddress {
    var p []IPAddress
    for i, v := range s {
      if i != idx {
        p = append(p, v)
      }
    }
    return p
  }

  func aggregate(networks []IPAddress) []IPAddress {
      if len(networks) == 0 {
          return []IPAddress {}
      }
      if len(networks) == 1 {
          return []IPAddress { networks[0].network() };
      }
      var stack []IPAddress
      for _, i := range networks {
          stack = append(stack, i.Network())
      }
      sort(stack)
      // for i in 0..networks.len() {
      //     println!("{}==={}", &networks[i].to_string_uncompressed(),
      //         &stack[i].to_string_uncompressed());
      // }
      pos := 0
      for true {
          if pos < 0 {
              pos = 0
          }
          stack_len := len(stack) // borrow checker
          // println!("loop:{}:{}", pos, stack_len);
          // if stack_len == 1 {
          //     println!("exit 1");
          //     break;
          // }
          if pos >= stack_len {
              // println!("exit first:{}:{}", stack_len, pos);
              break;
          }
          first := pos_to_idx(pos, stack_len)
          pos = pos + 1
          if pos >= stack_len {
              // println!("exit second:{}:{}", stack_len, pos);
              break
          }
          second := pos_to_idx(pos, stack_len)
          pos = pos + 1
          //let mut firstUnwrap = first.unwrap();
          if stack[first].includes(stack[second]) {
              pos = pos - 2
              // println!("remove:1:{}:{}:{}=>{}", first, second, stack_len, pos + 1);
              remove(stack, IPAddress.pos_to_idx(pos + 1, stack_len));
          } else {
              stack[first].prefix = stack[first].prefix.sub(1).unwrap();
              // println!("complex:{}:{}:{}:{}:P1:{}:P2:{}", pos, stack_len,
              // first, second,
              // stack[first].to_string(), stack[second].to_string());
              if (stack[first].prefix.num+1) == stack[second].prefix.num &&
                 stack[first].includes(&stack[second]) {
                  pos = pos - 2;
                  idx := IPAddress.pos_to_idx(pos, stack_len);
                  stack[idx] = stack[first].clone(); // kaputt
                  stack.remove(IPAddress.pos_to_idx(pos + 1, stack_len));
                  // println!("remove-2:{}:{}", pos + 1, stack_len);
                  pos = pos - 1; // backtrack
              } else {
                  stack[first].prefix = stack[first].prefix.add(1).unwrap(); //reset prefix
                  // println!("easy:{}:{}=>{}", pos, stack_len, stack[first].to_string());
                  pos = pos - 1; // do it with second as first
              }
          }
      }
      // println!("agg={}:{}", pos, stack.len());
      var ret []IPAddress
      for i := 0; i <= len(stack); i++ {
           ret.push(stack[i].network());
      }
      return ret;
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
      for net := range self.dns_networks() {
          // println!("dns_rev_domains:{}:{}", self.to_string(), net.to_string());
          ret = append(ret, net.dns_reverse())
      }
      return ret
  }


  func (self *IPAddress) dns_reverse() string{
      var ret bytes.Buffer
      dot := ""
      dns_parts := self.dns_parts();
      for i := ((self.prefix.host_prefix()+(self.ip_bits.dns_bits-1))/self.ip_bits.dns_bits);
          i <= len(dns_parts); i++ {
          ret.WriteString(dot);
          ret.WriteString(self.ip_bits.dns_part_format(dns_parts[i]));
          dot = ".";
      }
      ret.WriteString(dot);
      ret.WriteString(self.ip_bits.rev_domain);
      return ret.String();
  }


  func (self *IPAddress) dns_parts() []uint8 {
      var ret []uint8
      num := self.host_address
      mask := big.NewInt(1).Lsh(uint(self.Ip_bits.Dns_bits));
      for i := 0; i < self.Ip_bits.Bits/self.Ip_bits.Dns_bits; i++ {
          part := num.Rem(mask).to_u8().unwrap();
          num = num.Rsh(uint(self.Ip_bits.Dns_bits));
          ret = append(ret, part)
      }
      return ret;
  }

  func (self *IPAddress) dns_networks() []IPAddress {
      // +self.ip_bits.dns_bits-1
       next_bit_mask := self.ip_bits.bits -
          (((self.Prefix.Host_prefix())/self.Ip_bits.Dns_bits)*self.Ip_bits.Dns_bits);
       if next_bit_mask <= 0 {
           return []IPAddress{self.network()}
       }
      //  println!("dns_networks:{}:{}", self.to_string(), next_bit_mask);
       // dns_bits
       step_bit_net := big.NewInt(1).Lsh(uint(self.Ip_bits.Bits-next_bit_mask));
       if step_bit_net == big.NewInt(0) {
           return []IPAddress{self.network()}
       }
       var ret []IPAddress
       step := self.Network().Host_address;
       prefix := self.Prefix.From(next_bit_mask);
       for  step <= self.Broadcast().Host_address {
         ret = append(ret, self.From(&step, &prefix))
         step = step.Add(step_bit_net);
       }
       return ret;
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

  func Summarize(networks []IPAddress) []IPAddress {
      return IPAddress.aggregate(networks);
  }
  func Summarize_str(netstr []IPAddress)(*[]IPAddress, *string) {
      vec, err := IPAddress.To_ipaddress_vec(netstr)
      if vec == nil {
          return nil, err;
      }
      return IPAddress.aggregate(vec), nil
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
      return (self.Vt_is_loopback)(self);
  }


  ///  Returns true if the address is a mapped address
  ///
  ///  See IPAddress::IPv6::Mapped for more information
  ///

  func (self *IPAddress) Is_mapped()bool {
      return self.Mapped != nil &&
          self.Host_address.Rsh(32).Cmp(((big.NewInt(1).Lsh(16)).Sub(big.NewInt(1)))) == 0
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
      return self.prefix;
  }



  /// Checks if the argument is a valid IPv4 netmask
  /// expressed in dotted decimal format.
  ///
  ///   IPAddress.valid_ipv4_netmask? "255.255.0.0"
  ///     ///  true
  ///

  func is_valid_netmask(addr string) bool {
      return IPAddress.parse_netmask_to_prefix(addr) != nil;
  }

  func netmask_to_prefix(nm big.Int, bits uint) (*uint, *string) {
      prefix := 0
      addr := nm
      in_host_part := true;
      two := big.NewInt(2)
      for i := 0; i < bits; i++ {
          bit := addr.Mod(two).Uint64()
          if in_host_part && bit == 0 {
              prefix = prefix + 1
          } else if in_host_part && bit == 1 {
              in_host_part = false;
          } else if !in_host_part && bit == 0 {
              return nil, fmt.Strintf("this is not a net mask %s", nm);
          }
          addr = addr.Rsh(1);
      }
      return bits-prefix, nil;
  }


  func parse_netmask_to_prefix(netmask string) (*uint, *string) {
      is_number, err := strconv.ParseInt(netmask, 10, 64)
      if !err {
          return is_number, nil
      }
      my_ip, err := IPAddress.parse(netmask)
      if err {
          return nil, fmt.Sprintf("illegal netmask %s", netmask)
      }
      return IPAddress.netmask_to_prefix(my_ip.Host_address, my_ip.Ip_bits.Bits)
  }


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
      func (self *IPAddress) Change_prefix(num uint) (*IPAddress, *string) {
          prefix, err := self.Prefix.From(num);
          if err {
              return nil, err
          }
          return self.From(self.Host_address, prefix), nil
      }

  func (self *IPAddress) Change_netmask(my_str string) (*IPAddress, *string) {
      nm, err := IPAddress.parse_netmask_to_prefix(my_str)
      if err {
          return nil, err
      }
      return self.Change_prefix(nm), nil
  }



  ///  Returns a string with the IP address in canonical
  ///  form.
  ///
  ///    ip = IPAddress("172.16.100.4/22")
  ///
  ///    ip.to_string
  ///      ///  "172.16.100.4/22"
  ///

  func (self *IPAddress) To_string()string {
      var ret bytes.Buffer
      ret.WriteString(self.To_s());
      ret.WriteString("/");
      ret.WriteString(self.Prefix.To_s());
      return ret.String();
  }

  func (self *IPAddress) To_s() string {
      return self.Ip_bits.As_compressed_string(self.Host_address)
  }

  func (self *IPAddress) To_string_uncompressed() string {
      var ret bytes.Buffer
      ret.WriteString(self.To_s_uncompressed());
      ret.WriteString("/");
      ret.WriteString(self.Prefix.To_s());
      return ret.String();
  }

  func (self *IPAddress) To_s_uncompressed() string {
      return self.Ip_bits.As_uncompressed_string(self.Host_address);
  }

  func (self *IPAddress) To_s_mapped() string {
      if self.Is_mapped() {
          return fmt.Sprintf("::ffff:%s", self.Mapped.To_s());
      }
      return self.To_s();
  }

  func (self *IPAddress) to_string_mapped() string {
      if self.Is_mapped() {
          mapped := self.Mapped;
          return fmt.Sprintf("%s/%d",
              self.To_s_mapped(),
              mapped.Prefix.Num);
      }
      return self.To_string();
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
      num := self.Host_address.To_str_radix(2);
      var ret bytes.Buffer
      for i := len(num); i < self.Ip_bits.Bits; i++ {
          ret.WriteString("0");
      }
      ret.WriteString(num);
      return ret.String();
  }

  func (self *IPAddress) To_hex() string {
      return self.Host_address.To_str_radix(16);
  }

  func (self *IPAddress) Netmask() IPAddress {
      self.From(self.Prefix.Netmask(), self.Prefix)
  }

  ///  Returns the broadcast address for the given IP.
  ///
  ///    ip = IPAddress("172.16.10.64/24")
  ///
  ///    ip.broadcast.to_s
  ///      ///  "172.16.10.255"
  ///

  func (self *IPAddress) Broadcast() IPAddress {
      return self.From(self.Network().Host_address.Add(self.Size().Sub(big.NewInt(1))),
        self.Prefix)
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
      return self.Prefix.Num != self.Ip_bits.Bits &&
          self.Host_address.Cmp(self.Network().Host_address) == 0;
  }

  ///  Returns a new IPv4 object with the network number
  ///  for the given IP.
  ///
  ///    ip = IPAddress("172.16.10.64/24")
  ///
  ///    ip.network.to_s
  ///      ///  "172.16.10.0"
  ///

  func (self *IPAddress) network()IPAddress {
      return self.From(IPAddress.To_network(self.Host_address, self.Prefix.Host_prefix()), self.Prefix);
  }

  func To_network(adr big.Int, host_prefix uint) big.Int {
      return adr.Rsh(host_prefix).Lsh(host_prefix);
  }

  func (self *IPAddress) sub(other *IPAddress) big.Int {
      if self.Host_address.Cmp(other.Host_address) > 0 {
          return self.Host_address.Sub(other.Host_address);
      }
      return other.Host_address.Sub(self.Host_address);
  }

  func (self *IPAddress) Add(other *IPAddress) []IPAddress {
      return IPAddress.Aggregate([]IPAddress{self.clone(), other.clone()})
  }

  func to_s_vec(vec *[]IPAddress) []string {
      var ret []string
      for i := range vec {
          ret = append(ret, i.To_s());
      }
      return ret;
  }

  func to_string_vec(vec []IPAddress) []string {
      var ret []string
      for i := range vec {
          ret = append(ret, i.To_string());
      }
      return ret;
  }

  func to_ipaddress_vec(vec []string) (*[]IPAddress, string) {
      var ret []IPAddress
      for ipstr := range vec {
          ipa, err := IPAddress.parse(ipstr)
          if err {
              return nil, err
          }
          ret = append(ret, ipa)
      }
      return ret, nil
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
  func (self *IPAddress) first() IPAddress {
      return self.From(self.Network().Host_address.Add(self.Ip_bits.Host_ofs), self.Prefix);
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

  func (self *IPAddress) last() IPAddress {
      return self.From(self.Broadcast().Host_address.Sub(self.Ip_bits.Host_ofs), self.Prefix);
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

  func (self *IPAddress) each_host(fn func(*IPAddress)) {
      i := self.First().Host_address;
      for i.Cmp(self.Last().Host_address) <= 0 {
          fn(self.From(i, self.Prefix));
          i = i.add(big.NewInt(1))
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

  func (self *IPAddress) each(fn func(*IPAddress)) {
      i := self.Network().Host_address;
      for i.Cmp(self.Broadcast().Host_address) <= 0 {
          fn(self.From(i, self.prefix));
          i = i.Add(big.NewInt(1))
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

  func (self *IPAddress) size() big.Int {
      return big.NewInt(1).Lsh(self.Prefix.Host_prefix());
  }

  func (self *IPAddress) Is_same_kind(oth *IPAddress)bool {
      return self.Is_ipv4() == oth.Is_ipv4() &&
      self.Is_ipv6() == oth.Is_ipv6();
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

  func (self *IPAddress) Includes(oth *IPAddress)bool {
      ret := self.Is_same_kind(oth) &&
      self.Prefix.num <= oth.Prefix.Num &&
      self.Network().Host_address == IPAddress.To_network(oth.Host_address,
        self.Prefix.Host_prefix());
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
      for oth := range oths {
          if !self.Includes(oth) {
              return false;
          }
      }
      return true;
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

  func (self *IPAddress) Is_private()bool {
      return (self.Vt_is_private)(self);
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
      var dup [len(arr)]IPAddress
      copy(dup[:], arr);
      if len(dup) < 2 {
          return dup;
      }
      for i := len(dup)-1; i >= 0; i-- {
          a := IPAddress.Summarize([]IPAddress{dup[i].clone(), dup[i + 1].clone()})
          // println!("dup:{}:{}:{}", dup.len(), i, a.len());
          if len(a) == 1 {
              dup[i] = a[0].clone();
              remove(dup, i+1)
              break;
          }
      }
      return dup;
  }

  func (self *IPAddress) split(subnets uint) (*[]IPAddress, *string) {
      if subnets == 0 || (1 << self.Prefix.Host_prefix()) <= subnets {
          return fmt.sprintf("Value %s out of range", subnets);
      }
      networks, err := self.Subnet(self.Newprefix(subnets).num);
      if err {
          return nil, err
      }
      net := networks
      for len(net) != subnets {
          net = self.Sum_first_found(net);
      }
      return net, nil;
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
                             self.Prefix.Num);
      }
      // let mut new_ip = self.host_address.clone();
      // for _ in new_prefix..self.prefix.num {
      //     new_ip = new_ip << 1;
      // }
      return self.From(self.Host_address, self.Prefix.From(new_prefix)).Network();
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
      net := self.Network();
      net.prefix = net.Prefix.From(subprefix);
      for i := 0; i < (1 << (subprefix - self.Prefix.Num)); i++ {
          ret = append(ret, net.clone());
          net = net.From(net.Host_address, net.Prefix);
          size := net.Size();
          net.Host_address = net.Host_address + size;
      }
      return ret, nil;
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
      return (self.vt_to_ipv6)(self);
  }


  //  private methods
  //

  func (self *IPAddress) Newprefix(num uint)(*Prefix, *string) {
      for i := num; i < self.Ip_bits.Bits; i++ {
          a := float(uint(math.log2(float64(i))))
          if a == Math.log2(float(i)) {
              return self.Prefix.Add(uint(a))
          }
      }
      return nil, fmt.Sprintf("newprefix not found %d:%d", num, self.Ip_bits.Bits);
  }
