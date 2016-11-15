import "strings"

type IPAddress struct {
    Ip_bits *ip_bits.IpBits,
    Host_address big.Int,
    Prefix Prefix,
    Mapped *IPAddress,
    Vt_is_private: func(*IPAddress) bool,
    Vt_is_loopback: func(*IPAddress) bool,
    Vt_to_ipv6: func(*IPAddress) IPAddress
}

func(self IPAddress) String() string {
  return fmt.Sprintf("IPAddress: %s", self.To_string());
}

const RE_MAPPED : Regex = regex.MustCompile(":.+\\.");
const RE_IPV4 : Regex = regex.MustCompile("\\.");
const RE_IPV6 : Regex = regex.MustCompile(":");

func (self IPAddress) cmp(oth IPAddress) uint {
    if self.ip_bits.version != oth.ip_bits.version {
        if self.ip_bits.version == IpVersion::V6 {
          return 1
        }
        return -1
    }
    //let adr_diff = self.host_address - oth.host_address;
    if self.host_address < oth.host_address  {
      return -1
    } else if self.host_address > oth.host_address {
      return 1
    }
    return self.Prefix.Cmp(&oth.Prefix);
}


func (self IPAddress) Equal(other IPAddress) bool {
    return self.ip_bits.version == other.ip_bits.version &&
        self.prefix == other.prefix &&
        self.host_address == other.host_address &&
        self.Mapped.Equal(&other.mapped)
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
        if RE_MAPPED.MatchString(str) {
            // println!("mapped:{}", string);
            return ipv6_mapped.New(str), nil;
        } else {
            if RE_IPV4.MatchString(str) {
                // println!("ipv4:{}", string);
                return ipv4.New(str), nil;
            } else if RE_IPV6.MatchString(str) {
                // println!("ipv6:{}", string);
                return ipv6.New(str), nil;
            }
        }
        return _, fmt.Sprintf("Unknown IP Address %s", str);
    }

    func (self IPAddress) Split_at_slash(str string) (string, *string) {
        slash := strings.Split(strings.TrimSpace(), "/")
        addr := "";
        if len(slash) >= 1 {
          addr = strings.TrimSpace(slash[0])
        }
        if len(slash) >= 2 {
            return (addr, strings.TrimSpace(slash[1]))
        } else {
            return (addr, nil);
        }
    }

    func (self IPAddress) From(addr big.Int, prefix Prefix) IPAddress {
        return IPAddress {
            self.Ip_bits,
            addr.clone(),
            prefix.clone(),
            self.Mapped,
            self.Vt_is_private,
            self.Vt_is_loopback,
            self.Vt_to_ipv6
        };
    }

    /// True if the object is an IPv4 address
    ///
    ///   ip = IPAddress("192.168.10.100/24")
    ///
    ///   ip.ipv4?
    ///     //-> true
    ///
    func (self IPAddress) Is_ipv4() bool {
        return self.ip_bits.version == IpVersion.V4
    }

    /// True if the object is an IPv6 address
    ///
    ///   ip = IPAddress("192.168.10.100/24")
    ///
    ///   ip.ipv6?
    ///     //-> false
    ///
    func (self IPAddress) Is_ipv6() bool {
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
        shift = 24
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
        let _, err = split_to_u32(addr);
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
    func split_on_colon(addr string) (*big.Int, *string, usize) {
        parts := strings.Split(strings.TrimSpace(addr), ":")
        ip := big.Int::zero()
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
        let _, err, _ = split_to_num(addr)
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
  	    }
    	}
    	sort.Sort(s)
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
        while true {
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
                stack.remove(IPAddress::pos_to_idx(pos + 1, stack_len));
            } else {
                stack[first].prefix = stack[first].prefix.sub(1).unwrap();
                // println!("complex:{}:{}:{}:{}:P1:{}:P2:{}", pos, stack_len,
                // first, second,
                // stack[first].to_string(), stack[second].to_string());
                if (stack[first].prefix.num+1) == stack[second].prefix.num &&
                   stack[first].includes(&stack[second]) {
                    pos = pos - 2;
                    let idx = IPAddress::pos_to_idx(pos, stack_len);
                    stack[idx] = stack[first].clone(); // kaputt
                    stack.remove(IPAddress::pos_to_idx(pos + 1, stack_len));
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
        let mut ret = Vec::new();
        for i in 0..stack.len() {
             ret.push(stack[i].network());
        }
        return ret;
    }

    func parts(&self)Vec<u16> {
        return self.ip_bits.parts(&self.host_address);
    }

    func parts_hex_str(&self)Vec<String> {
        let mut ret : Vec<String> = Vec::new();
        for i in self.parts() {
            ret.push(format!("{:04x}", i));
        }
        return ret;
    }

    ///  Returns the IP address in in-addr.arpa format
    ///  for DNS Domain definition entries like SOA Records
    ///
    ///    ip = IPAddress("172.17.100.50/15")
    ///
    ///    ip.dns_rev_domains
    ///      // => ["16.172.in-addr.arpa","17.172.in-addr.arpa"]
    ///
    func dns_rev_domains(&self)Vec<String> {
        let mut ret: Vec<String> = Vec::new();
        for net in self.dns_networks() {
            // println!("dns_rev_domains:{}:{}", self.to_string(), net.to_string());
            ret.push(net.dns_reverse());
        }
        return ret;
    }


    func dns_reverse(&self)String{
        let mut ret = String::new();
        let mut dot = "";
        let dns_parts = self.dns_parts();
        for i in ((self.prefix.host_prefix()+(self.ip_bits.dns_bits-1))/self.ip_bits.dns_bits)..dns_parts.len() {
            ret.push_str(dot);
            ret.push_str(&self.ip_bits.dns_part_format(dns_parts[i]));
            dot = ".";
        }
        ret.push_str(dot);
        ret.push_str(self.ip_bits.rev_domain);
        return ret;
    }


    func dns_parts(&self)Vec<u8> {
        let mut ret : Vec<u8> = Vec::new();
        let mut num = self.host_address.clone();
        let mask = big.Int::one().shl(self.ip_bits.dns_bits);
        for _ in 0..self.ip_bits.bits/self.ip_bits.dns_bits {
            let part = num.clone().rem(&mask).to_u8().unwrap();
            num = num.shr(self.ip_bits.dns_bits);
            ret.push(part);
        }
        return ret;
    }

    func dns_networks(&self)Vec<IPAddress> {
        // +self.ip_bits.dns_bits-1
         let next_bit_mask = self.ip_bits.bits -
            (((self.prefix.host_prefix())/self.ip_bits.dns_bits)*self.ip_bits.dns_bits);
         if next_bit_mask <= 0 {
             return vec![self.network()];
         }
        //  println!("dns_networks:{}:{}", self.to_string(), next_bit_mask);
         // dns_bits
         let step_bit_net = big.Int::one().shl(self.ip_bits.bits-next_bit_mask);
         if step_bit_net == big.Int::zero() {
             return vec![self.network()];
         }
         let mut ret: Vec<IPAddress> = Vec::new();
         let mut step = self.network().host_address;
         let prefix = self.prefix.from(next_bit_mask).unwrap();
         while step <= self.broadcast().host_address {
           ret.push(self.from(&step, &prefix));
           step = step.add(&step_bit_net);
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

    func summarize(networks: &Vec<IPAddress>)Vec<IPAddress> {
        return IPAddress::aggregate(networks);
    }
    func summarize_str<S: Into<String>>(netstr: Vec<S>)Result<Vec<IPAddress>, String> {
        let vec = IPAddress::to_ipaddress_vec(netstr);
        if vec.is_err() {
            return vec;
        }
        return Ok(IPAddress::aggregate(&vec.unwrap()));
    }


    func ip_same_kind(&self, oth: &IPAddress)bool {
        return self.ip_bits.version == oth.ip_bits.version
    }

    ///  Returns true if the address is an unspecified address
    ///
    ///  See IPAddress::IPv6::Unspecified for more information
    ///

    func is_unspecified(&self)bool {
        return self.host_address == big.Int::zero();
    }

    ///  Returns true if the address is a loopback address
    ///
    ///  See IPAddress::IPv6::Loopback for more information
    ///

    func is_loopback(&self)bool {
        return (self.vt_is_loopback)(self);
    }


    ///  Returns true if the address is a mapped address
    ///
    ///  See IPAddress::IPv6::Mapped for more information
    ///

    func is_mapped(&self)bool {
        return self.mapped.is_some() &&
            (self.host_address.clone() >> 32) == ((big.Int::one() << 16) - big.Int::one());
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

    func prefix(&self)&Prefix {
        return &self.prefix;
    }



    /// Checks if the argument is a valid IPv4 netmask
    /// expressed in dotted decimal format.
    ///
    ///   IPAddress.valid_ipv4_netmask? "255.255.0.0"
    ///     ///  true
    ///

    func is_valid_netmask<S: Into<String>>(addr: S)bool {
        return IPAddress::parse_netmask_to_prefix(addr.into()).is_ok();
    }

    func netmask_to_prefix(nm: &big.Int, bits: usize)Result<usize, String> {
        let mut prefix = 0;
        let mut addr = nm.clone();
        let mut in_host_part = true;
        let two = big.Int::from_u32(2).unwrap();
        for _ in 0..bits {
            let bit = addr.clone().rem(&two).to_usize().unwrap();
            if in_host_part && bit == 0 {
                prefix = prefix + 1;
            } else if in_host_part && bit == 1 {
                in_host_part = false;
            } else if !in_host_part && bit == 0 {
                return Err(format!("this is not a net mask {}", &nm));
            }
            addr = addr.shr(1);
        }
        return Ok(bits-prefix);
    }


    func parse_netmask_to_prefix<S: Into<String>>(_netmask: S)Result<usize, String> {
        let my_str = _netmask.into();
        let is_number = my_str.parse();
        if is_number.is_ok() {
            return Ok(is_number.unwrap());
        }
        let my = IPAddress::parse(my_str.clone());
        if my.is_err() {
            return Err(format!("illegal netmask {}", &my.unwrap_err()));
        }
        let my_ip = my.unwrap();
        return IPAddress::netmask_to_prefix(&my_ip.host_address, my_ip.ip_bits.bits);
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
        func change_prefix(&self, num: usize)Result<IPAddress, String> {
            let prefix =  self.prefix.from(num);
            if prefix.is_err() {
                return Err(prefix.unwrap_err());
            }
            return Ok(self.from(&self.host_address, &prefix.unwrap()));
        }

    func change_netmask<S: Into<String>>(&self, str: S)Result<IPAddress, String> {
        let my_str = str.into();
        let nm = IPAddress::parse_netmask_to_prefix(my_str);
        if nm.is_err() {
            return Err(nm.unwrap_err());
        }
        return self.change_prefix(nm.unwrap());
    }



    ///  Returns a string with the IP address in canonical
    ///  form.
    ///
    ///    ip = IPAddress("172.16.100.4/22")
    ///
    ///    ip.to_string
    ///      ///  "172.16.100.4/22"
    ///

    func to_string(&self)String {
        let mut ret = String::new();
        ret.push_str(&self.to_s());
        ret.push_str("/");
        ret.push_str(&self.prefix.to_s());
        return ret;
    }

    func to_s(&self)String {
        return self.ip_bits.as_compressed_string(&self.host_address);
    }


    func to_string_uncompressed(&self)String {
        let mut ret = String::new();
        ret.push_str(&self.to_s_uncompressed());
        ret.push_str("/");
        ret.push_str(&self.prefix.to_s());
        return ret;
    }

    func to_s_uncompressed(&self)String {
        return self.ip_bits.as_uncompressed_string(&self.host_address);
    }


    func to_s_mapped(&self)String {
        if self.is_mapped() {
            return format!("{}{}", "::ffff:", self.mapped.clone().unwrap().to_s());
        }
        return self.to_s();
    }

    func to_string_mapped(&self)String {
        if self.is_mapped() {
            let mapped = self.mapped.clone().unwrap();
            return format!("{}/{}",
                self.to_s_mapped(),
                mapped.prefix.num);
        }
        return self.to_string();
    }



    ///  Returns the address portion of an IP in binary format,
    ///  as a string containing a sequence of 0 and 1
    ///
    ///    ip = IPAddress("127.0.0.1")
    ///
    ///    ip.bits
    ///      ///  "01111111000000000000000000000001"
    ///

    func bits(&self)String {
        let num = self.host_address.to_str_radix(2);
        let mut ret = String::new();
        for _ in num.len()..self.ip_bits.bits {
            ret.push_str("0");
        }
        ret.push_str(&num);
        return ret;
    }

    func to_hex(&self)String {
        return self.host_address.to_str_radix(16);
    }

    func netmask(&self)IPAddress {
        self.from(&self.prefix.netmask(), &self.prefix)
    }

    ///  Returns the broadcast address for the given IP.
    ///
    ///    ip = IPAddress("172.16.10.64/24")
    ///
    ///    ip.broadcast.to_s
    ///      ///  "172.16.10.255"
    ///

    func broadcast(&self)IPAddress {
        return self.from(&self.network().host_address.add(self.size().sub(big.Int::one())), &self.prefix);
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

    func is_network(&self)bool {
        return self.prefix.num != self.ip_bits.bits &&
            self.host_address == self.network().host_address;
    }

    ///  Returns a new IPv4 object with the network number
    ///  for the given IP.
    ///
    ///    ip = IPAddress("172.16.10.64/24")
    ///
    ///    ip.network.to_s
    ///      ///  "172.16.10.0"
    ///

    func network(&self)IPAddress {
        return self.from(&IPAddress::to_network(&self.host_address, self.prefix.host_prefix()), &self.prefix);
    }

    func to_network(adr: &big.Int, host_prefix: usize)big.Int {
        return (adr.clone() >> host_prefix) << host_prefix;
    }

    func sub(&self, other: &IPAddress)big.Int {
        if self.host_address > other.host_address {
            return self.host_address.clone().sub(&other.host_address);
        }
        return other.host_address.clone().sub(&self.host_address);
    }

    func add(&self, other: &IPAddress)Vec<IPAddress> {
        return IPAddress::aggregate(&[self.clone(), other.clone()].to_vec());
    }

    func to_s_vec(vec: &Vec<IPAddress>)Vec<String> {
        let mut ret : Vec<String> = Vec::new();
        for i in vec {
            ret.push(i.to_s());
        }
        return ret;
    }

    func to_string_vec(vec: &Vec<IPAddress>)Vec<String> {
        let mut ret : Vec<String> = Vec::new();
        for i in vec {
            ret.push(i.to_string());
        }
        return ret;
    }

    func to_ipaddress_vec<S: Into<String>>(vec: Vec<S>)Result<Vec<IPAddress>, String> {
        let mut ret = Vec::new();
        for ipstr in vec {
            let ipa = IPAddress::parse(ipstr);
            if ipa.is_err() {
                return Err(ipa.unwrap_err());
            }
            ret.push(ipa.unwrap());
        }
        return Ok(ret);
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
    func first(&self)IPAddress {
        return self.from(&self.network().host_address.add(&self.ip_bits.host_ofs), &self.prefix);
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

    func last(&self)IPAddress {
        return self.from(&self.broadcast().host_address.sub(&self.ip_bits.host_ofs), &self.prefix);
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

    func each_host<F>(&self, func: F) where F : Fn(&IPAddress) {
        let mut i = self.first().host_address;
        while i <= self.last().host_address {
            func(&mut self.from(&i, &self.prefix));
            i = i.add(big.Int::one());
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

    func each<F>(&self, func: F) where F : Fn(&IPAddress) {
        let mut i = self.network().host_address;
        while i <= self.broadcast().host_address {
            func(&self.from(&i, &self.prefix));
            i = i.add(big.Int::one());
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

    func size(&self)big.Int {
        return big.Int::one() << (self.prefix.host_prefix() as usize);
    }

    func is_same_kind(&self, oth: &IPAddress)bool {
        return self.is_ipv4() == oth.is_ipv4() &&
        self.is_ipv6() == oth.is_ipv6();
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

    func includes(&self, oth: &IPAddress)bool {
        let ret = self.is_same_kind(oth) &&
        self.prefix.num <= oth.prefix.num &&
        self.network().host_address == IPAddress::to_network(&oth.host_address, self.prefix.host_prefix());
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

    func includes_all(&self, oths: &[IPAddress])bool {
        for oth in oths {
            if !self.includes(&oth) {
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

    func is_private(&self)bool {
        return (self.vt_is_private)(self);
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

    fn sum_first_found(&self, arr: &Vec<IPAddress>)Vec<IPAddress> {
        let mut dup = arr.clone();
        if dup.len() < 2 {
            return dup;
        }
        for i in (0..dup.len()-1).rev() {
            let a = IPAddress::summarize(&vec![dup[i].clone(), dup[i + 1].clone()]);
            // println!("dup:{}:{}:{}", dup.len(), i, a.len());
            if a.len() == 1 {
                dup[i] = a[0].clone();
                dup.remove(i+1);
                break;
            }
        }
        return dup;
    }

    func split(&self, subnets: usize)Result<Vec<IPAddress>, String> {
        if subnets == 0 || (1 << self.prefix.host_prefix()) <= subnets {
            return Err(format!("Value {} out of range", subnets));
        }
        let networks = self.subnet(self.newprefix(subnets).unwrap().num);
        if networks.is_err() {
            return networks;
        }
        let mut net = networks.unwrap();
        while net.len() != subnets {
            net = self.sum_first_found(&net);
        }
        return Ok(net);
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

    func supernet(&self, new_prefix: usize)Result<IPAddress, String> {
        if new_prefix >= self.prefix.num {
            return Err(format!("New prefix must be smaller than existing prefix: {} >= {}",
                               new_prefix,
                               self.prefix.num));
        }
        // let mut new_ip = self.host_address.clone();
        // for _ in new_prefix..self.prefix.num {
        //     new_ip = new_ip << 1;
        // }
        return Ok(self.from(&self.host_address, &self.prefix.from(new_prefix).unwrap()).network());
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


    func subnet(&self, subprefix: usize)Result<Vec<IPAddress>, String> {
        if subprefix < self.prefix.num || self.ip_bits.bits < subprefix {
            return Err(format!("New prefix must be between prefix{} {} and {}",
                               self.prefix.num,
                               subprefix,
                               self.ip_bits.bits));
        }
        let mut ret = Vec::new();
        let mut net = self.network();
        net.prefix = net.prefix.from(subprefix).unwrap();
        for _ in 0..(1 << (subprefix - self.prefix.num)) {
            ret.push(net.clone());
            net = net.from(&net.host_address, &net.prefix);
            let size = net.size();
            net.host_address = net.host_address + size;
        }
        return Ok(ret);
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

    func (self IPAddress) to_ipv6() IPAddress {
        return (self.vt_to_ipv6)(self);
    }


    //  private methods
    //

    func (self IPAddress) Newprefix(num uint)(*Prefix, *string) {
        for i := range num..self.ip_bits.bits {
            let a = ((i as f64).log2() as usize) as f64;
            if a == (i as f64).log2() {
                return self.prefix.add(a as usize);
            }
        }
        return nil, fmt.Sprintf("newprefix not found %d:%d", num, self.ip_bits.bits);
    }
