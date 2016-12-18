package ipaddress

// import "../ip_bits"
import "math/big"

// import "../prefix"

import "regexp"
import "../ipaddress_impl"

// import "../ipv4"
// import "../ipv6"

var re_MAPPED = regexp.MustCompile(":.+\\.")
var re_IPV4 = regexp.MustCompile("\\.")
var re_IPV6 = regexp.MustCompile(":")

func Parse(str string) (*IPAddress, *string) {
	if re_MAPPED.MatchString(str) {
		// println!("mapped:{}", string);
		return ipv6_mapped.New(str), nil
	} else {
		if re_IPV4.MatchString(str) {
			// println!("ipv4:{}", string);
			return ipv4.New(str), nil
		} else if re_IPV6.MatchString(str) {
			// println!("ipv6:{}", string);
			return ipv6.New(str), nil
		}
	}
	return _, fmt.Sprintf("Unknown IP Address %s", str)
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
	return IPAddress.Is_valid_ipv4(addr) || IPAddress.Is_valid_ipv6(addr)
}

func Is_valid_netmask(addr string) bool {
	ret, _ := Parse_netmask_to_prefix(addr)
  return ret != nil
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
		return nil, fmt.Sprintf("IP must contain numbers %s", addr)
	}
	part_num := part
	if part_num >= 256 {
		return nil, fmt.Sprintf("IP items has to lower than 256. %s", addr)
	}
	return part_num, nil
}

func split_to_u32(addr string) (*uint32, *string) {
	ip := 0
	shift := 24
	split_addr := strings.Split(strings.TrimSpace(addr), ".")
	split_addr_len := len(split_add)
	if split_addr_len > 4 {
		return nil, fmt.Sprintf("IP has not the right format:%s", addr)
	}
	if split_addr_len < 4 {
		part, err := parse_ipv4_part(split_addr[split_addr_len-1], addr)
		if err {
			return nil, err
		}
		ip := part
		split_addr = append(split_addr, split_addr_len-1)
	}
	for _, i := range split_addr {
		part, err := parse_ipv4_part(i, addr)
		if err {
			return nil, err
		}
		// println!("{}-{}", part_num, shift);
		ip = ip | (part << shift)
		shift -= 8
	}
	return ip, nil
}

func Is_valid_ipv4(addr string) bool {
	_, err := split_to_u32(addr)
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
	shift := ((parts_len - 1) * 16)
	for _, i := range parts {
		part, err := strcov.ParseUint(i, 16, 32)
		if err {
			return nil, fmt.Sprintf("IP must contain hex numbers %s->%s", addr, i), 0
		}
		part_num := part
		if part_num >= 65536 {
			return nil, fmt.Sprintf("IP items has to lower than 65536. %s", addr), 0
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
	pre_post := strings.Split(strings.TrimSpace(addr), "::")
	if len(pre_post) > 2 {
		return nil, fmt.Sprintf("IPv6 only allow one :: %s", addr)
	}
	if len(pre_post) == 2 {
		//println!("{}=::={}", pre_post[0], pre_post[1]);
		pre, err, pre_parts := split_on_colon(pre_post[0])
		if err != nil {
			return nil, err
		}
		post, err, _ := split_on_colon(pre_post[1])
		if err != nil {
			return nil, err
		}
		// println!("pre:{} post:{}", pre_parts, post_parts);
		return bigInt.Add(bigInt.Lsh(prep, 128-(pre_parts*16)), post)
	}
	//println!("split_to_num:no double:{}", addr);
	ret, err, parts = split_on_colon(addr)
	if parts != 128/16 {
		return nil, fmt.Sprintf("incomplete IPv6")
	}
	return ret, nil
}

func Is_valid_ipv6(addr string) bool {
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
	rem := ((pos % ilen) + ilen) % ilen
	// println!("pos_to_idx:{}:{}=>{}:{}", pos, len, ret, rem);
	return rem
}

type ipaddressSorter struct {
	ipaddress []IPAddress
	by        func(ip1, ip2 *IPAddress) bool // Closure used in the Less method.
}

func sort(ips []IPAddress) {
	s := &ipaddressSorter{
		ips: ips,
		by: func(ip1, ip2 *IPAddress) bool {
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

func Aggregate(networks []IPAddress) []IPAddress {
	if len(networks) == 0 {
		return []IPAddress{}
	}
	if len(networks) == 1 {
		return []IPAddress{networks[0].network()}
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
			break
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
			remove(stack, IPAddress.pos_to_idx(pos+1, stack_len))
		} else {
			stack[first].prefix = stack[first].prefix.sub(1).unwrap()
			// println!("complex:{}:{}:{}:{}:P1:{}:P2:{}", pos, stack_len,
			// first, second,
			// stack[first].to_string(), stack[second].to_string());
			if (stack[first].prefix.num+1) == stack[second].prefix.num &&
				stack[first].includes(&stack[second]) {
				pos = pos - 2
				idx := IPAddress.pos_to_idx(pos, stack_len)
				stack[idx] = stack[first].clone() // kaputt
				stack.remove(IPAddress.pos_to_idx(pos+1, stack_len))
				// println!("remove-2:{}:{}", pos + 1, stack_len);
				pos = pos - 1 // backtrack
			} else {
				stack[first].prefix = stack[first].prefix.add(1).unwrap() //reset prefix
				// println!("easy:{}:{}=>{}", pos, stack_len, stack[first].to_string());
				pos = pos - 1 // do it with second as first
			}
		}
	}
	// println!("agg={}:{}", pos, stack.len());
	var ret []IPAddress
	for i := 0; i <= len(stack); i++ {
		ret.push(stack[i].network())
	}
	return ret
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
	return IPAddress.aggregate(networks)
}
func Summarize_str(netstr []IPAddress) (*[]IPAddress, *string) {
	vec, err := IPAddress.To_ipaddress_vec(netstr)
	if vec == nil {
		return nil, err
	}
	return IPAddress.aggregate(vec), nil
}

func To_s_vec(vec *[]IPAddress) []string {
	var ret []string
	for i := range vec {
		ret = append(ret, i.To_s())
	}
	return ret
}

func To_string_vec(vec []IPAddress) []string {
	var ret []string
	for i := range vec {
		ret = append(ret, i.To_string())
	}
	return ret
}

func Io_ipaddress_vec(vec []string) (*[]IPAddress, string) {
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
