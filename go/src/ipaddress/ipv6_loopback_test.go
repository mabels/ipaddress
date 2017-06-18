package ipaddress

import "testing"
// import "fmt"
import "math/big"

// import "./ipaddress"

type IPv6LoopbackTest struct {
	ip   IPAddress
	s    string
	n    string
	_str string
	one  big.Int
}

func ipv6_loopback_setup() IPv6LoopbackTest {
	return IPv6LoopbackTest{
		*Ipv6LoopbackNew(),
		"::1",
		"::1/128",
		"0000:0000:0000:0000:0000:0000:0000:0001/128",
		*big.NewInt(1),
	}
}

func TestIpv6Loopback(t *testing.T) {
	describe("test_ipv6_loopback", func() {
		it("ipv6_loopback.test_attributes", func() {
			s := ipv6_loopback_setup()
      // fmt.Printf("test_attributes-1\n")
			assert_uint8(128, s.ip.Prefix.Num)
      // fmt.Printf("test_attributes-2\n")
			assert_bool(true, s.ip.Is_loopback())
      // fmt.Printf("test_attributes-3\n")
			assert_string(s.s, s.ip.To_s())
      // fmt.Printf("test_attributes-4\n")
			assert_string(s.n, s.ip.To_string())
      // fmt.Printf("test_attributes-5\n")
			assert_string(s._str, s.ip.To_string_uncompressed())
      // fmt.Printf("test_attributes-6\n")
			assert_bigint(s.one, s.ip.Host_address)
		})

		it("ipv6_loopback.test_method_ipv6", func() {
      ip := ipv6_loopback_setup().ip;
      // fmt.Printf("test_method_ipv6:%s\n", ip)
			assert_bool(true, ip.Is_ipv6())
		})
	})
}
