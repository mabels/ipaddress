package ipaddress

// import "../ip_bits"
import "math/big"

// import "../prefix"

import "regexp"
import "../ipaddress_impl"

import "../ipv4"
import "../ipv6"

var re_MAPPED = regexp.MustCompile(":.+\\.")
var re_IPV4 = regexp.MustCompile("\\.")
var re_IPV6 = regexp.MustCompile(":")

func Parse(str string) (*ipaddress_impl.IPAddress, *string) {
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
