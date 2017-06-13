package ipaddress

// import "../ip_bits"
import "math/big"

// import "../prefix"

import "regexp"
import "fmt"
import "strconv"
import "strings"

// import "./data"

// import "../ipv4"
// import "../ipv6"

var re_MAPPED = regexp.MustCompile(":.+\\.")
var re_IPV4 = regexp.MustCompile("\\.")
var re_IPV6 = regexp.MustCompile(":")

func Parse(str string) ResultIPAddress {
	fmt.Printf("p-1\n");
	if re_MAPPED.MatchString(str) {
		fmt.Printf("p-2\n");
		// println!("mapped:{}", string);
		return Ipv6MappedNew(str)
	} else {
		if re_IPV4.MatchString(str) {
			fmt.Printf("p-3\n");
			// println!("ipv4:{}", string);
			return Ipv4New(str)
		} else if re_IPV6.MatchString(str) {
			fmt.Printf("p-7\n");
			// println!("ipv6:{}", string);
			return Ipv6New(str)
		}
	}
	fmt.Printf("p-8\n");
  tmp := fmt.Sprintf("Unknown IP Address %s", str)
	return &Error{&tmp}
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
	return Is_valid_ipv4(addr) || Is_valid_ipv6(addr)
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
	if err == nil {
    tmp := fmt.Sprintf("IP must contain numbers %s", addr)
		return nil, &tmp
	}
	part_num := uint32(part)
	if part_num >= 256 {
    tmp := fmt.Sprintf("IP items has to lower than 256. %s", addr)
		return nil, &tmp
	}
	return &part_num, nil
}

func remove_string(stack []string, idx int) []string {
	var p []string
	for i, v := range stack {
		if i != idx {
			p = append(p, v)
		}
	}
	return p
}

func split_to_u32(addr string) (*uint32, *string) {
	ip := uint32(0)
	shift := uint(24)
	split_addr := strings.Split(strings.TrimSpace(addr), ".")
	split_addr_len := len(split_addr)
	if split_addr_len > 4 {
    tmp := fmt.Sprintf("IP has not the right format:%s", addr)
		return nil, &tmp
	}
	if split_addr_len < 4 {
		_, err := parse_ipv4_part(split_addr[split_addr_len-1], addr)
		if err != nil {
			return nil, err
		}
		// ip := part
		split_addr = remove_string(split_addr, split_addr_len-1)
	}
	for _, i := range split_addr {
		part, err := parse_ipv4_part(i, addr)
		if err != nil {
			return nil, err
		}
		// println!("{}-{}", part_num, shift);
		ip = ip | (*part << shift)
		shift -= 8
	}
	return &ip, nil
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
	parts_len := uint(len(parts))
	if parts_len == 1 && parts[0] != "" {
		return ip, nil, 0
	}
	shift := uint((parts_len - 1) * 16)
	for _, i := range parts {
		part, err := strconv.ParseUint(i, 16, 32)
		if err != nil {
      tmp := fmt.Sprintf("IP must contain hex numbers %s->%s", addr, i)
			return nil, &tmp, 0
		}
		part_num := int64(part)
		if part_num >= 65536 {
      tmp := fmt.Sprintf("IP items has to lower than 65536. %s", addr)
			return nil, &tmp, 0
		}
		bi_part_num := big.NewInt(part_num)
		bi_part_num = bi_part_num.Lsh(bi_part_num, shift)
		ip = ip.Add(ip, bi_part_num)
		shift -= 16
	}
	return ip, nil, parts_len
}

func split_to_num(addr string) (*big.Int, *string) {
	//let mut ip = 0;
	pre_post := strings.Split(strings.TrimSpace(addr), "::")
	if len(pre_post) > 2 {
    tmp := fmt.Sprintf("IPv6 only allow one :: %s", addr)
		return nil, &tmp
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
		return big.NewInt(0).Add(pre.Lsh(pre, 128-(pre_parts*16)), post), nil
	}
	//println!("split_to_num:no double:{}", addr);
	ret, err, parts := split_on_colon(addr)
  if err != nil {
		return nil, err
  }
	if parts != 128/16 {
    tmp := fmt.Sprintf("incomplete IPv6")
		return nil, &tmp
	}
	return ret, nil
}

func Is_valid_ipv6(addr string) bool {
	_, err := split_to_num(addr)
	return err != nil
}
