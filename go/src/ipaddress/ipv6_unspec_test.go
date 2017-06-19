package ipaddress

import "testing"
import "math/big"

type IPv6UnspecifiedTest struct {
	ip                     IPAddress
	to_s                   string
	to_string              string
	to_string_uncompressed string
	num                    big.Int
}

func ipv6UnspecSetup() IPv6UnspecifiedTest {
	return IPv6UnspecifiedTest{
		ip:                     *Ipv6UnspecNew(),
		to_s:                   "::",
		to_string:              "::/128",
		to_string_uncompressed: "0000:0000:0000:0000:0000:0000:0000:0000/128",
		num: *big.NewInt(0)}
}

func TestIpv6Unspec(tx *testing.T) {
  t := MyTesting{tx}
	t.Run("", func(t *MyTesting) {
		t.Run("test_attributes", func(t *MyTesting) {
			s := ipv6UnspecSetup()
			t.assert_bigint(s.ip.Host_address, s.num)
			t.assert_uint8(128, s.ip.Prefix.Get_prefix())
			t.assert_bool(true, s.ip.Is_unspecified())
			t.assert_string(s.to_s, s.ip.To_s())
			t.assert_string(s.to_string, s.ip.To_string())
			t.assert_string(s.to_string_uncompressed, s.ip.To_string_uncompressed())
		})
		t.Run("test_method_ipv6", func(t *MyTesting) {
			s := ipv6UnspecSetup()
			t.assert_bool(true, s.ip.Is_ipv6())
		})
	})
}
