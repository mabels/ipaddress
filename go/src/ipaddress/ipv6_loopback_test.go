package ipaddress

import "testing"
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
		it("test_attributes", func() {
			s := ipv6_loopback_setup()
			assert_uint8(128, s.ip.Prefix.Num)
			assert_bool(true, s.ip.Is_loopback())
			assert_string(s.s, s.ip.To_s())
			assert_string(s.n, s.ip.To_string())
			assert_string(s._str, s.ip.To_string_uncompressed())
			assert_bigint(s.one, s.ip.Host_address)
		})

		it("test_method_ipv6", func() {
      ip := setup().ip;
			assert_bool(true, ip.Is_ipv6())
		})
	})
}
