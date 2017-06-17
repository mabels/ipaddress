package ipaddress

import "testing"
import "math/big"
import "fmt"

type IPv6Test struct {
	compress_addr map[string]string
	valid_ipv6    map[string]big.Int
	invalid_ipv6  []string
	networks      map[string]string
	ip            IPAddress
	network       IPAddress
	arr           []uint16
	hex           string
}

func ipv6Setup() IPv6Test {
	ip6t := IPv6Test{
		compress_addr: map[string]string{},
		valid_ipv6:    map[string]big.Int{},
		invalid_ipv6:  []string{":1:2:3:4:5:6:7", ":1:2:3:4:5:6:7", "2002:516:2:200", "dd"},
		networks:      map[string]string{},
		ip:            *Parse("2001:db8::8:800:200c:417a/64").Unwrap(),
		network:       *Parse("2001:db8:8:800::/64").Unwrap(),
		arr:           []uint16{8193, 3512, 0, 0, 8, 2048, 8204, 16762},
		hex:           "20010db80000000000080800200c417a",
	}

	ip6t.compress_addr["2001:db8:0000:0000:0008:0800:200c:417a"] = "2001:db8::8:800:200c:417a"
	ip6t.compress_addr["2001:db8:0:0:8:800:200c:417a"] = "2001:db8::8:800:200c:417a"
	ip6t.compress_addr["ff01:0:0:0:0:0:0:101"] = "ff01::101"
	ip6t.compress_addr["0:0:0:0:0:0:0:1"] = "::1"
	ip6t.compress_addr["0:0:0:0:0:0:0:0"] = "::"

	ip6t.valid_ipv6["FEDC:BA98:7654:3210:FEDC:BA98:7654:3210"] = str2Int("338770000845734292534325025077361652240", 10)
	ip6t.valid_ipv6["1080:0000:0000:0000:0008:0800:200C:417A"] = str2Int("21932261930451111902915077091070067066", 10)
	ip6t.valid_ipv6["1080:0:0:0:8:800:200C:417A"] = str2Int("21932261930451111902915077091070067066", 10)
	ip6t.valid_ipv6["1080:0::8:800:200C:417A"] = str2Int("21932261930451111902915077091070067066", 10)
	ip6t.valid_ipv6["1080::8:800:200C:417A"] = str2Int("21932261930451111902915077091070067066", 10)
	ip6t.valid_ipv6["FF01:0:0:0:0:0:0:43"] = str2Int("338958331222012082418099330867817087043", 10)
	ip6t.valid_ipv6["FF01:0:0::0:0:43"] = str2Int("338958331222012082418099330867817087043", 10)
	ip6t.valid_ipv6["FF01::43"] = str2Int("338958331222012082418099330867817087043", 10)
	ip6t.valid_ipv6["0:0:0:0:0:0:0:1"] = str2Int("1", 10)
	ip6t.valid_ipv6["0:0:0::0:0:1"] = str2Int("1", 10)
	ip6t.valid_ipv6["::1"] = str2Int("1", 10)
	ip6t.valid_ipv6["0:0:0:0:0:0:0:0"] = str2Int("0", 10)
	ip6t.valid_ipv6["0:0:0::0:0:0"] = str2Int("0", 10)
	ip6t.valid_ipv6["::"] = str2Int("0", 10)
	ip6t.valid_ipv6["::/0"] = str2Int("0", 10)
	ip6t.valid_ipv6["1080:0:0:0:8:800:200C:417A"] = str2Int("21932261930451111902915077091070067066", 10)
	ip6t.valid_ipv6["1080::8:800:200C:417A"] = str2Int("21932261930451111902915077091070067066", 10)

	ip6t.networks["2001:db8:1:1:1:1:1:1/32"] = "2001:db8::/32"
	ip6t.networks["2001:db8:1:1:1:1:1::/32"] = "2001:db8::/32"
	ip6t.networks["2001:db8::1/64"] = "2001:db8::/64"
	return ip6t
}

func TestIpv6(t *testing.T) {

	describe("", func() {
		it("test_attribute_address", func() {
			addr := "2001:0db8:0000:0000:0008:0800:200c:417a"
			s := ipv6Setup()
			assert_string(addr, s.ip.To_s_uncompressed())
		})
		it("test_initialize", func() {
			s := ipv6Setup()
			assert_bool(false, s.ip.Is_ipv4())

			for ip, _ := range s.valid_ipv6 {
				assert_bool(true, Parse(ip).IsOk())
			}
			for _, ip := range s.invalid_ipv6 {
				assert_bool(true, Parse(ip).IsErr())
			}
			assert_uint8(64, s.ip.Prefix.Num)

			assert_bool(false, Parse("::10.1.1.1").IsErr())
		})
		it("test_attribute_groups", func() {
			ipv6Setup := ipv6Setup()
			assert_uint16_array(ipv6Setup.arr, ipv6Setup.ip.Parts())
		})
		it("test_method_hexs", func() {
			ipv6Setup := ipv6Setup()
			assert_string_array(ipv6Setup.ip.Parts_hex_str(),
				[]string{"2001", "0db8", "0000", "0000", "0008", "0800", "200c", "417a"})
		})

		it("test_method_to_i", func() {
			for ip, num := range ipv6Setup().valid_ipv6 {
				assert_bigint(num, Parse(ip).Unwrap().Host_address)
			}
		})
		// #[test]
		// fn test_method_bits() {
		//     let bits = "0010000000000001000011011011100000000000000000000" +
		//                "000000000000000000000000000100000001000000000000010000" +
		//                "0000011000100000101111010";
		//     assert_eq(bits, ipv6Setup().ip.host_address.to_str_radix(2));
		// }
		it("test_method_set_prefix", func() {
			ip := Parse("2001:db8::8:800:200c:417a").Unwrap()
			assert_uint8(128, ip.Prefix.Num)
			assert_string("2001:db8::8:800:200c:417a/128", ip.To_string())
			nip := ip.Change_prefix(64).Unwrap()
			assert_uint8(64, nip.Prefix.Num)
			assert_string("2001:db8::8:800:200c:417a/64", nip.To_string())
		})
		it("test_method_mapped", func() {
			s := ipv6Setup()
			assert_bool(false, s.ip.Is_mapped())
			ip6 := Parse("::ffff:1234:5678").Unwrap()
			assert_bool(true, ip6.Is_mapped())
		})
		// #[test]
		// fn test_method_literal() {
		//     let str = "2001-0db8-0000-0000-0008-0800-200c-417a.ipv6-literal.net";
		//     assert_eq(str, ipv6Setup().ip.literal());
		// }
		it("test_method_group", func() {
			s := ipv6Setup()
			assert_uint16_array(s.ip.Parts(), s.arr)
		})
		it("test_method_ipv4", func() {
			s := ipv6Setup()
			assert_bool(false, s.ip.Is_ipv4())
		})
		it("test_method_ipv6", func() {
			s := ipv6Setup()
			assert_bool(true, s.ip.Is_ipv6())
		})
		it("test_method_network_known", func() {
			s := ipv6Setup()
			assert_bool(true, s.network.Is_network())
			assert_bool(false, s.ip.Is_network())
		})
		it("test_method_network_u128", func() {
			s := ipv6Setup()
			assert_ipaddress(From_int(str2IntPtr("42540766411282592856903984951653826560", 10), 64).Unwrap(),
				s.ip.Network())
		})
		it("test_method_broadcast_u128", func() {
			s := ipv6Setup()
			assert_ipaddress(From_int(str2IntPtr("42540766411282592875350729025363378175", 10), 64).Unwrap(),
				s.ip.Broadcast())
		})
		it("test_method_size", func() {
			one := big.NewInt(1)
			ip := Parse("2001:db8::8:800:200c:417a/64").Unwrap()
			assert_bigint(*one.Lsh(one, 64), ip.Size())
			ip = Parse("2001:db8::8:800:200c:417a/32").Unwrap()
			one = big.NewInt(1)
			assert_bigint(*one.Lsh(one, 96), ip.Size())
			ip = Parse("2001:db8::8:800:200c:417a/120").Unwrap()
			one = big.NewInt(1)
			assert_bigint(*one.Lsh(one, 8), ip.Size())
			ip = Parse("2001:db8::8:800:200c:417a/124").Unwrap()
			one = big.NewInt(1)
			assert_bigint(*one.Lsh(one, 4), ip.Size())
		})
		it("test_method_includes", func() {
			ip := ipv6Setup().ip
			assert_bool(true, ip.Includes(&ip))
			// test prefix on same address
			included := Parse("2001:db8::8:800:200c:417a/128").Unwrap()
			not_included := Parse("2001:db8::8:800:200c:417a/46").Unwrap()
			assert_bool(true, ip.Includes(included))
			assert_bool(false, ip.Includes(not_included))
			// test address on same prefix
			included = Parse("2001:db8::8:800:200c:0/64").Unwrap()
			not_included = Parse("2001:db8:1::8:800:200c:417a/64").Unwrap()
			assert_bool(true, ip.Includes(included))
			assert_bool(false, ip.Includes(not_included))
			// general test
			included = Parse("2001:db8::8:800:200c:1/128").Unwrap()
			not_included = Parse("2001:db8:1::8:800:200c:417a/76").Unwrap()
			assert_bool(true, ip.Includes(included))
			assert_bool(false, ip.Includes(not_included))
		})
		it("test_method_to_hex", func() {
      s := ipv6Setup()
			assert_string(s.hex, s.ip.To_hex())
		})
		it("test_method_to_s", func() {
      s := ipv6Setup()
			assert_string("2001:db8::8:800:200c:417a", s.ip.To_s())
		})
		it("test_method_to_string", func() {
      s := ipv6Setup()
			assert_string("2001:db8::8:800:200c:417a/64", s.ip.To_string())
		})
		it("test_method_to_string_uncompressed", func() {
			str := "2001:0db8:0000:0000:0008:0800:200c:417a/64"
      s := ipv6Setup()
			assert_string(str, s.ip.To_string_uncompressed())
		})
		it("test_method_reverse", func() {
			str := "f.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.2.0.0.0.5.0.5.0.e.f.f.3.ip6.arpa"
			assert_string(str,
				Parse("3ffe:505:2::f").Unwrap().Dns_reverse())
		})
		it("test_method_dns_rev_domains", func() {
			assert_string_array(Parse("f000:f100::/3").Unwrap().Dns_rev_domains(),
				[]string{"e.ip6.arpa", "f.ip6.arpa"})
			assert_string_array(Parse("fea3:f120::/15").Unwrap().Dns_rev_domains(),
				[]string{"2.a.e.f.ip6.arpa", "3.a.e.f.ip6.arpa"})
			assert_string_array(Parse("3a03:2f80:f::/48").Unwrap().Dns_rev_domains(),
				[]string{"f.0.0.0.0.8.f.2.3.0.a.3.ip6.arpa"})

			assert_string_array(Parse("f000:f100::1234/125").Unwrap().Dns_rev_domains(),
				[]string{"0.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
					"1.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
					"2.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
					"3.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
					"4.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
					"5.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
					"6.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa",
					"7.3.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.f.0.0.0.f.ip6.arpa"})
		})
		it("test_method_compressed", func() {
			assert_string("1:1:1::1",
				Parse("1:1:1:0:0:0:0:1").Unwrap().To_s())
			assert_string("1:0:1::1",
				Parse("1:0:1:0:0:0:0:1").Unwrap().To_s())
			assert_string("1::1:1:1:2:3:1",
				Parse("1:0:1:1:1:2:3:1").Unwrap().To_s())
			assert_string("1::1:1:0:2:3:1",
				Parse("1:0:1:1::2:3:1").Unwrap().To_s())
			assert_string("1:0:0:1::1",
				Parse("1:0:0:1:0:0:0:1").Unwrap().To_s())
			assert_string("1::1:0:0:1",
				Parse("1:0:0:0:1:0:0:1").Unwrap().To_s())
			assert_string("1::1", Parse("1:0:0:0:0:0:0:1").Unwrap().To_s())
			// assert_eq("1:1::1:2:0:0:1", Parse("1:1:0:1:2::1").Unwrap().to_s
		})
		it("test_method_unspecified", func() {
			assert_bool(true, Parse("::").Unwrap().Is_unspecified())
      s := ipv6Setup();
			assert_bool(false, s.ip.Is_unspecified())
		})
		it("test_method_loopback", func() {
			assert_bool(true, Parse("::1").Unwrap().Is_loopback())
      s := ipv6Setup();
			assert_bool(false, s.ip.Is_loopback())
		})
		it("test_method_network", func() {
			for addr, net := range ipv6Setup().networks {
				ip := Parse(addr).Unwrap()
				assert_string(net, ip.Network().To_string())
			}
		})
		it("test_method_each", func() {
			ip := Parse("2001:db8::4/125").Unwrap()
			arr := []string{}
			ip.Each(func(i *IPAddress) { arr = append(arr, i.To_s()) })
			assert_string_array(arr,
				[]string{"2001:db8::",
					"2001:db8::1",
					"2001:db8::2",
					"2001:db8::3",
					"2001:db8::4",
					"2001:db8::5",
					"2001:db8::6",
					"2001:db8::7"})
		})
		it("test_method_each_net", func() {
			test_addrs := []string{"0000:0000:0000:0000:0000:0000:0000:0000",
				"1111:1111:1111:1111:1111:1111:1111:1111",
				"2222:2222:2222:2222:2222:2222:2222:2222",
				"3333:3333:3333:3333:3333:3333:3333:3333",
				"4444:4444:4444:4444:4444:4444:4444:4444",
				"5555:5555:5555:5555:5555:5555:5555:5555",
				"6666:6666:6666:6666:6666:6666:6666:6666",
				"7777:7777:7777:7777:7777:7777:7777:7777",
				"8888:8888:8888:8888:8888:8888:8888:8888",
				"9999:9999:9999:9999:9999:9999:9999:9999",
				"aaaa:aaaa:aaaa:aaaa:aaaa:aaaa:aaaa:aaaa",
				"bbbb:bbbb:bbbb:bbbb:bbbb:bbbb:bbbb:bbbb",
				"cccc:cccc:cccc:cccc:cccc:cccc:cccc:cccc",
				"dddd:dddd:dddd:dddd:dddd:dddd:dddd:dddd",
				"eeee:eeee:eeee:eeee:eeee:eeee:eeee:eeee",
				"ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff"}
			for prefix := uint(0); prefix < 128; prefix++ {
				nr_networks := 1 << ((128 - prefix) % 4)
				for adr := range test_addrs {
					net_adr := Parse(fmt.Sprintf("%s/%d", adr, prefix)).Unwrap()
					ret := net_adr.Dns_networks()
					assert_uint8(ret[0].Prefix.Num%4, 0)
					assert_int(len(ret), nr_networks)
					assert_string(net_adr.Network().To_s(), ret[0].Network().To_s())
					assert_string(net_adr.Broadcast().To_s(), ret[len(ret)-1].Broadcast().To_s())
					//        puts "//{adr}///{prefix} //{nr_networks} //{ret}"
				}
			}
			ret0 := []string{}
			for _,i := range Parse("fd01:db8::4/3").Unwrap().Dns_networks() {
				ret0 = append(ret0, i.To_string())
			}
			assert_string_array(ret0, []string{"e000::/4", "f000::/4"})
			ret1 := []string{}
			for _,i := range Parse("3a03:2f80:f::/48").Unwrap().Dns_networks() {
				ret1 = append(ret1, i.To_string())
			}
			assert_string_array(ret1, []string{"3a03:2f80:f::/48"})
		})
		it("test_method_compare", func() {
			ip1 := Parse("2001:db8:1::1/64").Unwrap()
			ip2 := Parse("2001:db8:2::1/64").Unwrap()
			ip3 := Parse("2001:db8:1::2/64").Unwrap()
			ip4 := Parse("2001:db8:1::1/65").Unwrap()

			// ip2 should be greater than ip1
			assert_bool(true, ip2.Gt(ip1))
			assert_bool(false, ip1.Gt(ip2))
			assert_bool(false, ip2.Lt(ip1))
			// ip3 should be less than ip2
			assert_bool(true, ip2.Gt(ip3))
			assert_bool(false, ip2.Lt(ip3))
			// ip1 should be less than ip3
			assert_bool(true, ip1.Lt(ip3))
			assert_bool(false, ip1.Gt(ip3))
			assert_bool(false, ip3.Lt(ip1))
			// ip1 should be bool to itself
			assert_bool(true, ip1.Eq(ip1))
			// ip4 should be greater than ip1
			assert_bool(true, ip1.Lt(ip4))
			assert_bool(false, ip1.Gt(ip4))
			// test sorting
			r := []*IPAddress{ip1, ip2, ip3, ip4}
			Sorting(r)
			ret := []string{}
			for _,i := range r {
				ret = append(ret, i.To_string())
			}
			assert_string_array(ret,
				[]string{"2001:db8:1::1/64",
					"2001:db8:1::1/65",
					"2001:db8:1::2/64",
					"2001:db8:2::1/64"})
		})

		// fn test_classmethod_expand() {
		//   let compressed = "2001:db8:0:cd30::";
		//   let expanded = "2001:0db8:0000:cd30:0000:0000:0000:0000";
		//   assert_eq(expanded, @klass.expand(compressed));
		//   assert_eq(expanded, @klass.expand("2001:0db8:0::cd3"));
		//   assert_eq(expanded, @klass.expand("2001:0db8::cd30"));
		//   assert_eq(expanded, @klass.expand("2001:0db8::cd3"));
		// }
		it("test_classmethod_compress", func() {
			compressed := "2001:db8:0:cd30::"
			expanded := "2001:0db8:0000:cd30:0000:0000:0000:0000"
			assert_string(compressed, Parse(expanded).Unwrap().To_s())
			assert_string("2001:db8::cd3",
				Parse("2001:0db8:0::cd3").Unwrap().To_s())
			assert_string("2001:db8::cd30",
				Parse("2001:0db8::cd30").Unwrap().To_s())
			assert_string("2001:db8::cd3",
				Parse("2001:0db8::cd3").Unwrap().To_s())
		})
		it("test_classhmethod_parse_u128", func() {
			for ip, num := range ipv6Setup().valid_ipv6 {
				fmt.Printf(">>>%s===%s", ip, num)
				assert_string(Parse(ip).Unwrap().To_s(),
					From_int(&num, 128).Unwrap().To_s())
			}
		})
		it("test_classmethod_parse_hex", func() {
      s := ipv6Setup()
			assert_string(s.ip.To_string(),
				From_str(s.hex, 16, 64).Unwrap().To_string())
		})
	})
}
