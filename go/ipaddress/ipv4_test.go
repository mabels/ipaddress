package ipaddress

import "fmt"
import "math/big"
import "strconv"
import "strings"
import "testing"

type IPv4Prefix struct {
	ip     string
	prefix uint8
}

type IPv4Test struct {
	valid_ipv4       map[string]IPv4Prefix
	invalid_ipv4     []string
	valid_ipv4_range []string
	netmask_values   map[string]string
	decimal_values   map[string]uint32
	ip               IPAddress
	network          IPAddress
	networks         map[string]string
	broadcast        map[string]string
	class_a          IPAddress
	class_b          IPAddress
	class_c          IPAddress
	classful         map[string]uint8
}

func ipv4Setup() IPv4Test {
	ipv4t := IPv4Test{
		valid_ipv4:       map[string]IPv4Prefix{},
		invalid_ipv4:     []string{"10.0.0.256", "10.0.0.0.0"},
		valid_ipv4_range: []string{"10.0.0.1-254", "10.0.1-254.0", "10.1-254.0.0"},
		netmask_values:   map[string]string{},
		decimal_values:   map[string]uint32{},
		ip:               *Ipv4New("172.16.10.1/24").Unwrap(),
		network:          *Ipv4New("172.16.10.0/24").Unwrap(),
		networks:         map[string]string{},
		broadcast:        map[string]string{},
		class_a:          *Ipv4New("10.0.0.1/8").Unwrap(),
		class_b:          *Ipv4New("172.16.0.1/16").Unwrap(),
		class_c:          *Ipv4New("192.168.0.1/24").Unwrap(),
		classful:         map[string]uint8{}}
	ipv4t.valid_ipv4["9.9/17"] = IPv4Prefix{
		ip:     "9.0.0.9",
		prefix: 17,
	}
	ipv4t.valid_ipv4["100.1.100"] = IPv4Prefix{
		ip:     "100.1.0.100",
		prefix: 32,
	}
	ipv4t.valid_ipv4["0.0.0.0/0"] = IPv4Prefix{
		ip:     "0.0.0.0",
		prefix: 0,
	}
	ipv4t.valid_ipv4["10.0.0.0"] = IPv4Prefix{
		ip:     "10.0.0.0",
		prefix: 32,
	}
	ipv4t.valid_ipv4["10.0.0.1"] = IPv4Prefix{
		ip:     "10.0.0.1",
		prefix: 32,
	}
	ipv4t.valid_ipv4["10.0.0.1/24"] = IPv4Prefix{
		ip:     "10.0.0.1",
		prefix: 24,
	}
	ipv4t.valid_ipv4["10.0.0.9/255.255.255.0"] = IPv4Prefix{
		ip:     "10.0.0.9",
		prefix: 24,
	}

	ipv4t.netmask_values["0.0.0.0/0"] = "0.0.0.0"
	ipv4t.netmask_values["10.0.0.0/8"] = "255.0.0.0"
	ipv4t.netmask_values["172.16.0.0/16"] = "255.255.0.0"
	ipv4t.netmask_values["192.168.0.0/24"] = "255.255.255.0"
	ipv4t.netmask_values["192.168.100.4/30"] = "255.255.255.252"

	ipv4t.decimal_values["0.0.0.0/0"] = 0
	ipv4t.decimal_values["10.0.0.0/8"] = 167772160
	ipv4t.decimal_values["172.16.0.0/16"] = 2886729728
	ipv4t.decimal_values["192.168.0.0/24"] = 3232235520
	ipv4t.decimal_values["192.168.100.4/30"] = 3232261124

	ipv4t.ip = *Parse("172.16.10.1/24").Unwrap()
	ipv4t.network = *Parse("172.16.10.0/24").Unwrap()

	ipv4t.broadcast["10.0.0.0/8"] = "10.255.255.255/8"
	ipv4t.broadcast["172.16.0.0/16"] = "172.16.255.255/16"
	ipv4t.broadcast["192.168.0.0/24"] = "192.168.0.255/24"
	ipv4t.broadcast["192.168.100.4/30"] = "192.168.100.7/30"

	ipv4t.networks["10.5.4.3/8"] = "10.0.0.0/8"
	ipv4t.networks["172.16.5.4/16"] = "172.16.0.0/16"
	ipv4t.networks["192.168.4.3/24"] = "192.168.4.0/24"
	ipv4t.networks["192.168.100.5/30"] = "192.168.100.4/30"

	ipv4t.class_a = *Parse("10.0.0.1/8").Unwrap()
	ipv4t.class_b = *Parse("172.16.0.1/16").Unwrap()
	ipv4t.class_c = *Parse("192.168.0.1/24").Unwrap()

	ipv4t.classful["10.1.1.1"] = 8
	ipv4t.classful["150.1.1.1"] = 16
	ipv4t.classful["200.1.1.1"] = 24
	return ipv4t
}

func TestIpv4(tx *testing.T) {
	t := MyTesting{tx}
	t.Run("TestIpv4", func(t *MyTesting) {
		t.Run("test_initialize", func(t *MyTesting) {
			setup := ipv4Setup()
			for i, _ := range setup.valid_ipv4 {
				ip := *Parse(i).Unwrap()
				t.assert(ip.Is_ipv4() && !ip.Is_ipv6())
			}
			t.assert_uint8(32, setup.ip.Prefix.IpBits.Bits)
			t.assert(Parse("1.f.13.1/-3").IsErr())
			t.assert(Parse("10.0.0.0/8").IsOk())
		})
		t.Run("test_initialize_format_error", func(t *MyTesting) {
			for _, i := range ipv4Setup().invalid_ipv4 {
				t.assert(Parse(i).IsErr())
			}
			t.assert(Parse("10.0.0.0/asd").IsErr())
		})
		t.Run("test_initialize_without_prefix", func(t *MyTesting) {
			t.assert(Parse("10.10.0.0").IsOk())
			ip := Parse("10.10.0.0").Unwrap()
			t.assert(!ip.Is_ipv6() && ip.Is_ipv4())
			t.assert_uint8(32, ip.Prefix.Num)
		})
		t.Run("ipv4_test.test_attributes", func(t *MyTesting) {
			for arg, attr := range ipv4Setup().valid_ipv4 {
				ip := Parse(arg).Unwrap()
				// fmt.Printf("test_attributes:%s:%s\n", arg, attr.ip)
				t.assert_string(attr.ip, ip.To_s())
				t.assert_uint8(attr.prefix, ip.Prefix.Num)
			}
		})
		t.Run("test_octets", func(t *MyTesting) {
			ip := *Parse("10.1.2.3/8").Unwrap()
			t.assert_uint16_array(ip.Parts(), []uint16{10, 1, 2, 3})
		})
		t.Run("test_method_to_string", func(t *MyTesting) {
			for arg, attr := range ipv4Setup().valid_ipv4 {
				ip := *Parse(arg).Unwrap()
				t.assert_string(fmt.Sprintf("%s/%d", attr.ip, attr.prefix), ip.To_string())
			}
		})

		t.Run("test_method_to_s", func(t *MyTesting) {
			for arg, attr := range ipv4Setup().valid_ipv4 {
				ip := *Parse(arg).Unwrap()
				t.assert_string(attr.ip, ip.To_s())
				// ip_c = Parse(arg).Unwrap();
				// assert_eq(attr.ip, ip.to_s());
			}
		})

		t.Run("test_netmask", func(t *MyTesting) {
			for addr, mask := range ipv4Setup().netmask_values {
				netmask := Parse(addr).Unwrap().Netmask()
				t.assert_string(netmask.To_s(), mask)
			}
		})

		t.Run("test_method_to_u32", func(t *MyTesting) {
			for addr, val := range ipv4Setup().decimal_values {
				ip := *Parse(addr).Unwrap()
				t.assert_uint64(ip.Host_address.Uint64(), uint64(val))
			}
		})

		t.Run("test_method_is_network", func(t *MyTesting) {
			s := ipv4Setup()
			t.assert_bool(true, s.network.Is_network())
			t.assert_bool(false, s.ip.Is_network())
		})

		t.Run("test_one_address_network", func(t *MyTesting) {
			network := *Parse("172.16.10.1/32").Unwrap()
			t.assert_bool(false, network.Is_network())
		})

		t.Run("test_method_broadcast", func(t *MyTesting) {
			for addr, bcast := range ipv4Setup().broadcast {
				bcastip := Parse(addr).Unwrap().Broadcast()
				t.assert_string(bcast, bcastip.To_string())
			}
		})

		t.Run("test_method_network", func(t *MyTesting) {
			for addr, net := range ipv4Setup().networks {
				ip := Parse(addr).Unwrap().Network()
				t.assert_string(net, ip.To_string())
			}
		})

		t.Run("test_method_bits", func(t *MyTesting) {
			ip := *Parse("127.0.0.1").Unwrap()
			t.assert_string("01111111000000000000000000000001", ip.Bits())
		})

		t.Run("test_method_first", func(t *MyTesting) {
			ip := Parse("192.168.100.0/24").Unwrap().First()
			t.assert_string("192.168.100.1", ip.To_s())
			ip = Parse("192.168.100.50/24").Unwrap().First()
			t.assert_string("192.168.100.1", ip.To_s())
		})

		t.Run("test_method_last", func(t *MyTesting) {
			ip := Parse("192.168.100.0/24").Unwrap().Last()
			t.assert_string("192.168.100.254", ip.To_s())
			ip = Parse("192.168.100.50/24").Unwrap().Last()
			t.assert_string("192.168.100.254", ip.To_s())
		})

		t.Run("test_method_each_host", func(t *MyTesting) {
			ip := Parse("10.0.0.1/29").Unwrap()
			arr := []string{}
			ip.Each_host(func(i *IPAddress) { arr = append(arr, i.To_s()) })
			t.assert_string_array(arr,
				[]string{"10.0.0.1", "10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5", "10.0.0.6"})
		})

		t.Run("test_method_each", func(t *MyTesting) {
			ip := Parse("10.0.0.1/29").Unwrap()
			arr := []string{}
			ip.Each(func(i *IPAddress) { arr = append(arr, i.To_s()) })
			t.assert_string_array(arr,
				[]string{"10.0.0.0", "10.0.0.1", "10.0.0.2", "10.0.0.3", "10.0.0.4", "10.0.0.5",
					"10.0.0.6", "10.0.0.7"})
		})

		t.Run("test_method_size", func(t *MyTesting) {
			ip := *Parse("10.0.0.1/29").Unwrap()
			eight := *big.NewInt(8)
			t.assert_bigint(ip.Size(), eight)
		})

		t.Run("test_method_network_u32", func(t *MyTesting) {
			s := ipv4Setup().ip
			network := s.Network()
			t.assert_uint64(2886732288, network.Host_address.Uint64())
		})

		t.Run("test_method_broadcast_u32", func(t *MyTesting) {
			s := ipv4Setup().ip
			broadcast := s.Broadcast()
			t.assert_uint64(2886732543, broadcast.Host_address.Uint64())
		})

		t.Run("test_method_include", func(t *MyTesting) {
			ip := *Parse("192.168.10.100/24").Unwrap()
			addr := *Parse("192.168.10.102/24").Unwrap()
			t.assert_bool(true, ip.Includes(&addr))
			t.assert_bool(false,
				ip.Includes(Parse("172.16.0.48").Unwrap()))
			ip = *Parse("10.0.0.0/8").Unwrap()
			t.assert_bool(true, ip.Includes(Parse("10.0.0.0/9").Unwrap()))
			t.assert_bool(true, ip.Includes(Parse("10.1.1.1/32").Unwrap()))
			t.assert_bool(true, ip.Includes(Parse("10.1.1.1/9").Unwrap()))
			t.assert_bool(false,
				ip.Includes(Parse("172.16.0.0/16").Unwrap()))
			t.assert_bool(false, ip.Includes(Parse("10.0.0.0/7").Unwrap()))
			t.assert_bool(false, ip.Includes(Parse("5.5.5.5/32").Unwrap()))
			t.assert_bool(false, ip.Includes(Parse("11.0.0.0/8").Unwrap()))
			ip = *Parse("13.13.0.0/13").Unwrap()
			t.assert_bool(false, ip.Includes(Parse("13.16.0.0/32").Unwrap()))
		})

		t.Run("test_method_include_all", func(t *MyTesting) {
			ip := Parse("192.168.10.100/24").Unwrap()
			addr1 := Parse("192.168.10.102/24").Unwrap()
			addr2 := Parse("192.168.10.103/24").Unwrap()
			t.assert_bool(true, ip.Includes_all(&[]*IPAddress{addr1.Clone(), addr2}))
			t.assert_bool(false,
				ip.Includes_all(&[]*IPAddress{addr1, Parse("13.16.0.0/32").Unwrap()}))
		})

		t.Run("test_method_ipv4", func(t *MyTesting) {
			ip := ipv4Setup().ip
			t.assert_bool(true, ip.Is_ipv4())
		})

		t.Run("test_method_ipv6", func(t *MyTesting) {
			ip := ipv4Setup().ip
			t.assert_bool(false, ip.Is_ipv6())
		})

		t.Run("test_method_private", func(t *MyTesting) {
			t.assert_bool(true,
				Parse("169.254.10.50/24").Unwrap().Is_private())
			t.assert_bool(true,
				Parse("192.168.10.50/24").Unwrap().Is_private())
			t.assert_bool(true,
				Parse("192.168.10.50/16").Unwrap().Is_private())
			t.assert_bool(true,
				Parse("172.16.77.40/24").Unwrap().Is_private())
			t.assert_bool(true,
				Parse("172.16.10.50/14").Unwrap().Is_private())
			t.assert_bool(true,
				Parse("10.10.10.10/10").Unwrap().Is_private())
			t.assert_bool(true, Parse("10.0.0.0/8").Unwrap().Is_private())
			t.assert_bool(false,
				Parse("192.168.10.50/12").Unwrap().Is_private())
			t.assert_bool(false, Parse("3.3.3.3").Unwrap().Is_private())
			t.assert_bool(false, Parse("10.0.0.0/7").Unwrap().Is_private())
			t.assert_bool(false,
				Parse("172.32.0.0/12").Unwrap().Is_private())
			t.assert_bool(false,
				Parse("172.16.0.0/11").Unwrap().Is_private())
			t.assert_bool(false,
				Parse("192.0.0.2/24").Unwrap().Is_private())
		})

		t.Run("test_method_octet", func(t *MyTesting) {
			ip := ipv4Setup().ip
			t.assert_uint16(ip.Parts()[0], 172)
			t.assert_uint16(ip.Parts()[1], 16)
			t.assert_uint16(ip.Parts()[2], 10)
			t.assert_uint16(ip.Parts()[3], 1)
		})

		t.Run("test_method_a", func(t *MyTesting) {
			s := ipv4Setup()
			t.assert_bool(true, Is_class_a(&s.class_a))
			t.assert_bool(false, Is_class_a(&s.class_b))
			t.assert_bool(false, Is_class_a(&s.class_c))
		})

		t.Run("test_method_b", func(t *MyTesting) {
			s := ipv4Setup()
			t.assert_bool(true, Is_class_b(&s.class_b))
			t.assert_bool(false, Is_class_b(&s.class_a))
			t.assert_bool(false, Is_class_b(&s.class_c))
		})

		t.Run("test_method_c", func(t *MyTesting) {
			s := ipv4Setup()
			t.assert_bool(true, Is_class_c(&s.class_c))
			t.assert_bool(false, Is_class_c(&s.class_a))
			t.assert_bool(false, Is_class_c(&s.class_b))
		})

		t.Run("test_method_to_ipv6", func(t *MyTesting) {
			s := ipv4Setup()
			ipv6 := s.ip.To_ipv6()
			t.assert_string("::ac10:a01", ipv6.To_s())
		})

		t.Run("test_method_reverse", func(t *MyTesting) {
			s := ipv4Setup()
			t.assert_string(s.ip.Dns_reverse(), "10.16.172.in-addr.arpa")
		})

		t.Run("ipv4.test_method_dns_rev_domains", func(t *MyTesting) {
			t.assert_string_array(Parse("173.17.5.1/23").Unwrap().Dns_rev_domains(),
				[]string{"4.17.173.in-addr.arpa", "5.17.173.in-addr.arpa"})
			t.assert_string_array(Parse("173.17.1.1/15").Unwrap().Dns_rev_domains(),
				[]string{"16.173.in-addr.arpa", "17.173.in-addr.arpa"})
			t.assert_string_array(Parse("173.17.1.1/7").Unwrap().Dns_rev_domains(),
				[]string{"172.in-addr.arpa", "173.in-addr.arpa"})
			t.assert_string_array(Parse("173.17.1.1/29").Unwrap().Dns_rev_domains(),
				[]string{
					"0.1.17.173.in-addr.arpa",
					"1.1.17.173.in-addr.arpa",
					"2.1.17.173.in-addr.arpa",
					"3.1.17.173.in-addr.arpa",
					"4.1.17.173.in-addr.arpa",
					"5.1.17.173.in-addr.arpa",
					"6.1.17.173.in-addr.arpa",
					"7.1.17.173.in-addr.arpa"})
			t.assert_string_array(Parse("174.17.1.1/24").Unwrap().Dns_rev_domains(),
				[]string{"1.17.174.in-addr.arpa"})
			t.assert_string_array(Parse("175.17.1.1/16").Unwrap().Dns_rev_domains(),
				[]string{"17.175.in-addr.arpa"})
			t.assert_string_array(Parse("176.17.1.1/8").Unwrap().Dns_rev_domains(),
				[]string{"176.in-addr.arpa"})
			t.assert_string_array(Parse("177.17.1.1/0").Unwrap().Dns_rev_domains(),
				[]string{"in-addr.arpa"})
			t.assert_string_array(Parse("178.17.1.1/32").Unwrap().Dns_rev_domains(),
				[]string{"1.1.17.178.in-addr.arpa"})
		})

		t.Run("test_method_compare", func(t *MyTesting) {
			ip1 := Parse("10.1.1.1/8").Unwrap()
			ip2 := Parse("10.1.1.1/16").Unwrap()
			ip3 := Parse("172.16.1.1/14").Unwrap()
			ip4 := Parse("10.1.1.1/8").Unwrap()

			// ip2 should be greater than ip1
			t.assert_bool(true, ip1.Lt(ip2))
			t.assert_bool(false, ip1.Gt(ip2))
			t.assert_bool(false, ip2.Lt(ip1))
			// ip2 should be less than ip3
			t.assert_bool(true, ip2.Lt(ip3))
			t.assert_bool(false, ip2.Gt(ip3))
			// ip1 should be less than ip3
			t.assert_bool(true, ip1.Lt(ip3))
			t.assert_bool(false, ip1.Gt(ip3))
			t.assert_bool(false, ip3.Lt(ip1))
			// ip1 should be equal to itself
			t.assert_bool(true, ip1.Eq(ip1))
			// ip1 should be equal to ip4
			t.assert_bool(true, ip1.Eq(ip4))
			// test sorting
			res := []*IPAddress{ip1, ip2, ip3}
			Sorting(res)
			t.assert_string_array(To_string_vec(&res),
				[]string{"10.1.1.1/8", "10.1.1.1/16", "172.16.1.1/14"})
			// test same prefix
			ip1 = Parse("10.0.0.0/24").Unwrap()
			ip2 = Parse("10.0.0.0/16").Unwrap()
			ip3 = Parse("10.0.0.0/8").Unwrap()
			{
				res = []*IPAddress{ip1, ip2, ip3}
				Sorting(res)
				t.assert_string_array(To_string_vec(&res),
					[]string{"10.0.0.0/8", "10.0.0.0/16", "10.0.0.0/24"})
			}
		})

		t.Run("test_method_minus", func(t *MyTesting) {
			ip1 := Parse("10.1.1.1/8").Unwrap()
			ip2 := Parse("10.1.1.10/8").Unwrap()
			bi := ip2.Sub(ip1)
			t.assert_uint64(9, bi.Uint64())
			bi = ip1.Sub(ip2)
			t.assert_uint64(9, bi.Uint64())
		})

		t.Run("test_method_plus", func(t *MyTesting) {
			ip1 := Parse("172.16.10.1/24").Unwrap()
			ip2 := Parse("172.16.11.2/24").Unwrap()
			add := ip1.Add(ip2)
			t.assert_string_array(To_string_vec(add),
				[]string{"172.16.10.0/23"})

			ip2 = Parse("172.16.12.2/24").Unwrap()
			add = ip1.Add(ip2)
			net1 := ip1.Network()
			net2 := ip2.Network()
			t.assert_string_array(To_string_vec(add),
				[]string{net1.To_string(),
					net2.To_string()})

			ip1 = Parse("10.0.0.0/23").Unwrap()
			ip2 = Parse("10.0.2.0/24").Unwrap()
			add = ip1.Add(ip2)
			t.assert_string_array(To_string_vec(add),
				[]string{"10.0.0.0/23", "10.0.2.0/24"})

			ip1 = Parse("10.0.0.0/23").Unwrap()
			ip2 = Parse("10.0.2.0/24").Unwrap()
			add = ip1.Add(ip2)
			t.assert_string_array(To_string_vec(add),
				[]string{"10.0.0.0/23", "10.0.2.0/24"})

			ip1 = Parse("10.0.0.0/16").Unwrap()
			ip2 = Parse("10.0.2.0/24").Unwrap()
			add = ip1.Add(ip2)
			t.assert_string_array(To_string_vec(add),
				[]string{"10.0.0.0/16"})

			ip1 = Parse("10.0.0.0/23").Unwrap()
			ip2 = Parse("10.1.0.0/24").Unwrap()
			add = ip1.Add(ip2)
			t.assert_string_array(To_string_vec(add),
				[]string{"10.0.0.0/23", "10.1.0.0/24"})
		})

		t.Run("test_method_netmask_equal", func(t *MyTesting) {
			ip := Parse("10.1.1.1/16").Unwrap()
			t.assert_uint8(16, ip.Prefix.Num)
			ip2 := ip.Change_netmask("255.255.255.0").Unwrap()
			t.assert_uint8(24, ip2.Prefix.Num)
		})

		t.Run("test_method_split", func(t *MyTesting) {
			s := ipv4Setup()
			t.assert(s.ip.Split(0).IsErr())
			t.assert(s.ip.Split(257).IsErr())
			net := s.ip.Network()
			t.assert_string_array(To_string_vec(s.ip.Split(1).Unwrap()), []string{net.To_string()})

			t.assert_string_array(To_string_vec(s.network.Split(8).Unwrap()),
				[]string{"172.16.10.0/27",
					"172.16.10.32/27",
					"172.16.10.64/27",
					"172.16.10.96/27",
					"172.16.10.128/27",
					"172.16.10.160/27",
					"172.16.10.192/27",
					"172.16.10.224/27"})

			t.assert_string_array(To_string_vec(s.network.Split(7).Unwrap()),
				[]string{"172.16.10.0/27",
					"172.16.10.32/27",
					"172.16.10.64/27",
					"172.16.10.96/27",
					"172.16.10.128/27",
					"172.16.10.160/27",
					"172.16.10.192/26"})

			t.assert_string_array(To_string_vec(s.network.Split(6).Unwrap()),
				[]string{"172.16.10.0/27",
					"172.16.10.32/27",
					"172.16.10.64/27",
					"172.16.10.96/27",
					"172.16.10.128/26",
					"172.16.10.192/26"})
			t.assert_string_array(To_string_vec(s.network.Split(5).Unwrap()),
				[]string{"172.16.10.0/27",
					"172.16.10.32/27",
					"172.16.10.64/27",
					"172.16.10.96/27",
					"172.16.10.128/25"})
			t.assert_string_array(To_string_vec(s.network.Split(4).Unwrap()),
				[]string{"172.16.10.0/26", "172.16.10.64/26", "172.16.10.128/26", "172.16.10.192/26"})
			t.assert_string_array(To_string_vec(s.network.Split(3).Unwrap()),
				[]string{"172.16.10.0/26", "172.16.10.64/26", "172.16.10.128/25"})
			t.assert_string_array(To_string_vec(s.network.Split(2).Unwrap()),
				[]string{"172.16.10.0/25", "172.16.10.128/25"})
			t.assert_string_array(To_string_vec(s.network.Split(1).Unwrap()),
				[]string{"172.16.10.0/24"})
		})

		t.Run("test_method_subnet", func(t *MyTesting) {
			s := ipv4Setup()
			t.assert(s.network.Subnet(23).IsErr())
			t.assert(s.network.Subnet(33).IsErr())
			t.assert(s.ip.Subnet(30).IsOk())
			t.assert_string_array(To_string_vec(s.network.Subnet(26).Unwrap()),
				[]string{"172.16.10.0/26",
					"172.16.10.64/26",
					"172.16.10.128/26",
					"172.16.10.192/26"})
			t.assert_string_array(To_string_vec(s.network.Subnet(25).Unwrap()),
				[]string{"172.16.10.0/25", "172.16.10.128/25"})
			t.assert_string_array(To_string_vec(s.network.Subnet(24).Unwrap()),
				[]string{"172.16.10.0/24"})
		})

		t.Run("test_method_supernet", func(t *MyTesting) {
			s := ipv4Setup()
			t.assert(s.ip.Supernet(24).IsErr())
			t.assert_string("0.0.0.0/0", s.ip.Supernet(0).Unwrap().To_string())
			// assert_eq("0.0.0.0/0", ipv4Setup().ip.supernet(-2).Unwrap().to_string());
			t.assert_string("172.16.10.0/23",
				s.ip.Supernet(23).Unwrap().To_string())
			t.assert_string("172.16.8.0/22",
				s.ip.Supernet(22).Unwrap().To_string())
		})

		t.Run("test_classmethod_parse_u32", func(t *MyTesting) {
			for addr, val := range ipv4Setup().decimal_values {
				ip := From_u32(val, 32).Unwrap()
				splitted, _ := strconv.Atoi(strings.Split(addr, "/")[1])
				ip2 := ip.Change_prefix(uint8(splitted)).Unwrap()
				t.assert_string(ip2.To_string(), addr)
			}
		})

		t.Run("test_classmethod_Summarize", func(t *MyTesting) {

			s := ipv4Setup()
			// Should return self if only one network given
			net := s.ip.Network()
			addrs := []*IPAddress{net}
			t.assert_string_array(To_string_vec(Summarize(&addrs)), []string{net.To_string()})

			// Summarize homogeneous networks
			ip1 := Parse("172.16.10.1/24").Unwrap()
			ip2 := Parse("172.16.11.2/24").Unwrap()
			addrs = []*IPAddress{ip1, ip2}
			t.assert_string_array(To_string_vec(Summarize(&addrs)),
				[]string{"172.16.10.0/23"})

			{
				ip1 := Parse("10.0.0.1/24").Unwrap()
				ip2 := Parse("10.0.1.1/24").Unwrap()
				ip3 := Parse("10.0.2.1/24").Unwrap()
				ip4 := Parse("10.0.3.1/24").Unwrap()
				t.assert_string_array(To_string_vec(Summarize(&[]*IPAddress{ip1, ip2, ip3, ip4})),
					[]string{"10.0.0.0/22"})
			}
			{
				ip1 := Parse("10.0.0.1/24").Unwrap()
				ip2 := Parse("10.0.1.1/24").Unwrap()
				ip3 := Parse("10.0.2.1/24").Unwrap()
				ip4 := Parse("10.0.3.1/24").Unwrap()
				t.assert_string_array(To_string_vec(Summarize(&[]*IPAddress{ip4, ip3, ip2, ip1})),
					[]string{"10.0.0.0/22"})
			}

			// Summarize non homogeneous networks
			ip1 = Parse("10.0.0.0/23").Unwrap()
			ip2 = Parse("10.0.2.0/24").Unwrap()
			t.assert_string_array(To_string_vec(Summarize(&[]*IPAddress{ip1, ip2})),
				[]string{"10.0.0.0/23", "10.0.2.0/24"})

			ip1 = Parse("10.0.0.0/16").Unwrap()
			ip2 = Parse("10.0.2.0/24").Unwrap()
			t.assert_string_array(To_string_vec(Summarize(&[]*IPAddress{ip1, ip2})),
				[]string{"10.0.0.0/16"})

			ip1 = Parse("10.0.0.0/23").Unwrap()
			ip2 = Parse("10.1.0.0/24").Unwrap()
			t.assert_string_array(To_string_vec(Summarize(&[]*IPAddress{ip1, ip2})),
				[]string{"10.0.0.0/23", "10.1.0.0/24"})

			ip1 = Parse("10.0.0.0/23").Unwrap()
			ip2 = Parse("10.0.2.0/23").Unwrap()
			ip3 := Parse("10.0.4.0/24").Unwrap()
			ip4 := Parse("10.0.6.0/24").Unwrap()
			t.assert_string_array(To_string_vec(Summarize(&[]*IPAddress{ip1, ip2, ip3, ip4})),
				[]string{"10.0.0.0/22", "10.0.4.0/24", "10.0.6.0/24"})
			{
				ip1 = Parse("10.0.1.1/24").Unwrap()
				ip2 = Parse("10.0.2.1/24").Unwrap()
				ip3 = Parse("10.0.3.1/24").Unwrap()
				ip4 = Parse("10.0.4.1/24").Unwrap()
				t.assert_string_array(To_string_vec(Summarize(&[]*IPAddress{ip1, ip2, ip3, ip4})),
					[]string{"10.0.1.0/24", "10.0.2.0/23", "10.0.4.0/24"})
			}
			{
				ip1 = Parse("10.0.1.1/24").Unwrap()
				ip2 = Parse("10.0.2.1/24").Unwrap()
				ip3 = Parse("10.0.3.1/24").Unwrap()
				ip4 = Parse("10.0.4.1/24").Unwrap()
				t.assert_string_array(To_string_vec(Summarize(&[]*IPAddress{ip4, ip3, ip2, ip1})),
					[]string{"10.0.1.0/24", "10.0.2.0/23", "10.0.4.0/24"})
			}

			ip1 = Parse("10.0.1.1/24").Unwrap()
			ip2 = Parse("10.10.2.1/24").Unwrap()
			ip3 = Parse("172.16.0.1/24").Unwrap()
			ip4 = Parse("172.16.1.1/24").Unwrap()
			t.assert_string_array(To_string_vec(Summarize(
				&[]*IPAddress{ip1, ip2, ip3, ip4})),
				[]string{"10.0.1.0/24", "10.10.2.0/24", "172.16.0.0/23"})

			ips := []*IPAddress{Parse("10.0.0.12/30").Unwrap(),
				Parse("10.0.100.0/24").Unwrap()}
			t.assert_string_array(To_string_vec(Summarize(&ips)),
				[]string{"10.0.0.12/30", "10.0.100.0/24"})

			ips = []*IPAddress{Parse("172.16.0.0/31").Unwrap(),
				Parse("10.10.2.1/32").Unwrap()}
			t.assert_string_array(To_string_vec(Summarize(&ips)),
				[]string{"10.10.2.1/32", "172.16.0.0/31"})

			ips = []*IPAddress{Parse("172.16.0.0/32").Unwrap(),
				Parse("10.10.2.1/32").Unwrap()}
			t.assert_string_array(To_string_vec(Summarize(&ips)),
				[]string{"10.10.2.1/32", "172.16.0.0/32"})
		})

		t.Run("test_classmethod_parse_classful", func(t *MyTesting) {
			for ip, prefix := range ipv4Setup().classful {
				res := Parse_classful(ip).Unwrap()
				t.assert_uint8(prefix, res.Prefix.Num)
				t.assert_string(fmt.Sprintf("%s/%d", ip, prefix), res.To_string())
			}
			t.assert(Parse_classful("192.168.256.257").IsErr())
		})
	})
}
