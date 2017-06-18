package ipaddress

import (
	"fmt"
	"testing"
	// "reflect"
)

// mod tests {
// use IPAddress;

// use std.str.FromStr;

type IPAddressTest struct {
	valid_ipv4     string
	valid_ipv6     string
	valid_mapped   string
	invalid_ipv4   string
	invalid_ipv6   string
	invalid_mapped string
}

func setupIPAddressTest() IPAddressTest {
	return IPAddressTest{
		"172.16.10.1/24",
		"2001:db8::8:800:200c:417a/64",
		"::13.1.68.3",
		"10.0.0.256",
		":1:2:3:4:5:6:7",
		".1:2.3.4",
	}
}

func TestIpAddress(t *testing.T) {
	describe("", func() {
		it("test_method_ipaddress", func() {
			ipt := setupIPAddressTest()
			assert(Parse(ipt.valid_ipv4).IsOk())
			assert(Parse(ipt.valid_ipv6).IsOk())
			assert(Parse(ipt.valid_mapped).IsOk())

			assert(Parse(ipt.valid_ipv4).Unwrap().Is_ipv4())
			assert(Parse(ipt.valid_ipv6).Unwrap().Is_ipv6())
			assert(Parse(ipt.valid_mapped).Unwrap().Is_mapped())

			assert(Parse(ipt.invalid_ipv4).IsErr())
			assert(Parse(ipt.invalid_ipv6).IsErr())
			assert(Parse(ipt.invalid_mapped).IsErr())
		})
		it("test_module_method_valid", func() {
			assert_bool(true, Is_valid("10.0.0.1"))
			assert_bool(true, Is_valid("10.0.0.0"))
			assert_bool(true, Is_valid("2002::1"))
			assert_bool(true, Is_valid("dead:beef:cafe:babe::f0ad"))
			assert_bool(false, Is_valid("10.0.0.256"))
			assert_bool(false, Is_valid("10.0.0.0.0"))
			assert_bool(true, Is_valid("10.0.0"))
			assert_bool(true, Is_valid("10.0"))
			assert_bool(false, Is_valid("2002:516:2:200"))
			assert_bool(false, Is_valid("2002.:1"))
		})
		it("test_module_method_valid_ipv4_netmark", func() {
			assert_bool(true, Is_valid_netmask("255.255.255.0"))
			assert_bool(false, Is_valid_netmask("10.0.0.1"))
		})
		it("test_summarize", func() {
			netstr := []string{}
			nrs := [][]uint{{1, 10}, {11, 127}, {128, 169}, {170, 172}, {173, 192}, {193, 224}}
			for _, ran := range nrs {
				for i := ran[0]; i < ran[1]; i++ {
					netstr = append(netstr, fmt.Sprintf("%d.0.0.0/8", i))
				}
			}
			for i := 0; i < 256; i++ {
				if i != 254 {
					netstr = append(netstr, fmt.Sprintf("169.%d.0.0/16", i))
				}
			}
			for i := 0; i < 256; i++ {
				if i < 16 || 31 < i {
					netstr = append(netstr, fmt.Sprintf("172.%d.0.0/16", i))
				}
			}
			for i := 0; i < 256; i++ {
				if i != 168 {
					netstr = append(netstr, fmt.Sprintf("192.%d.0.0/16", i))
				}
			}
			ip_addresses := make([]*IPAddress, len(netstr))
			for idx, net := range netstr {
				// fmt.Printf("test_summarize:-M.1:%s\n", net)
				ip_addresses[idx] = Parse(net).Unwrap()
			}

			empty_vec := []string{}
			assert_int(len(*Summarize_str(empty_vec).Unwrap()), 0)
			assert_string_array(To_string_vec(Summarize_str([]string{"10.1.0.4/24"}).Unwrap()),
				[]string{"10.1.0.0/24"})
			assert_string_array(To_string_vec(Summarize_str([]string{"2000:1::4711/32"}).Unwrap()),
				[]string{"2000:1::/32"})

			assert_string_array(To_string_vec(Summarize_str([]string{"10.1.0.4/24",
				"7.0.0.0/0",
				"1.2.3.4/4"}).Unwrap()),
				[]string{"0.0.0.0/0"})
			assert_string_array(To_string_vec(Summarize_str([]string{"2000:1::/32",
				"3000:1::/32",
				"2000:2::/32",
				"2000:3::/32",
				"2000:4::/32",
				"2000:5::/32",
				"2000:6::/32",
				"2000:7::/32",
				"2000:8::/32"}).Unwrap()),
				[]string{"2000:1::/32", "2000:2::/31", "2000:4::/30", "2000:8::/32", "3000:1::/32"})

			assert_string_array(To_string_vec(Summarize_str([]string{"10.0.1.1/24",
				"30.0.1.0/16",
				"10.0.2.0/24",
				"10.0.3.0/24",
				"10.0.4.0/24",
				"10.0.5.0/24",
				"10.0.6.0/24",
				"10.0.7.0/24",
				"10.0.8.0/24"}).Unwrap()),
				[]string{"10.0.1.0/24", "10.0.2.0/23", "10.0.4.0/22", "10.0.8.0/24", "30.0.0.0/16"})

			assert_string_array(To_string_vec(Summarize_str([]string{"10.0.0.0/23",
				"10.0.2.0/24"}).Unwrap()),
				[]string{"10.0.0.0/23", "10.0.2.0/24"})
			assert_string_array(To_string_vec(Summarize_str([]string{"10.0.0.0/24",
				"10.0.1.0/24",
				"10.0.2.0/23"}).Unwrap()),
				[]string{"10.0.0.0/22"})

			assert_string_array(To_string_vec(Summarize_str([]string{"10.0.0.0/16",
				"10.0.2.0/24"}).Unwrap()),
				[]string{"10.0.0.0/16"})
			cnt := 10
			for i := 0; i < cnt; i++ {
				addrs := Summarize(&ip_addresses)
				assert_string_array(To_string_vec(addrs),
					[]string{"1.0.0.0/8",
						"2.0.0.0/7",
						"4.0.0.0/6",
						"8.0.0.0/7",
						"11.0.0.0/8",
						"12.0.0.0/6",
						"16.0.0.0/4",
						"32.0.0.0/3",
						"64.0.0.0/3",
						"96.0.0.0/4",
						"112.0.0.0/5",
						"120.0.0.0/6",
						"124.0.0.0/7",
						"126.0.0.0/8",
						"128.0.0.0/3",
						"160.0.0.0/5",
						"168.0.0.0/8",
						"169.0.0.0/9",
						"169.128.0.0/10",
						"169.192.0.0/11",
						"169.224.0.0/12",
						"169.240.0.0/13",
						"169.248.0.0/14",
						"169.252.0.0/15",
						"169.255.0.0/16",
						"170.0.0.0/7",
						"172.0.0.0/12",
						"172.32.0.0/11",
						"172.64.0.0/10",
						"172.128.0.0/9",
						"173.0.0.0/8",
						"174.0.0.0/7",
						"176.0.0.0/4",
						"192.0.0.0/9",
						"192.128.0.0/11",
						"192.160.0.0/13",
						"192.169.0.0/16",
						"192.170.0.0/15",
						"192.172.0.0/14",
						"192.176.0.0/12",
						"192.192.0.0/10",
						"193.0.0.0/8",
						"194.0.0.0/7",
						"196.0.0.0/6",
						"200.0.0.0/5",
						"208.0.0.0/4"})
			}
			// end
			// printer = RubyProf.GraphPrinter.new(result)
			// printer.print(STDOUT, {})
			// test imutable input parameters
			a1 := Parse("10.0.0.1/24").Unwrap()
			a2 := Parse("10.0.1.1/24").Unwrap()
			addrs := Summarize(&[]*IPAddress{a1.Clone(), a2.Clone()})
			assert_string_array(To_string_vec(addrs),
				[]string{"10.0.0.0/23"})
			assert_string("10.0.0.1/24", a1.To_string())
			assert_string("10.0.1.1/24", a2.To_string())
		})
	})
}
