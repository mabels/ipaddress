package ipaddress

import "testing"
import "math/big"
import "fmt"


    type IPv6MappedTest struct {
        ip IPAddress
        s string
        sstr string
        _str string
        u128 big.Int
        address string
        valid_mapped map[string]big.Int
        valid_mapped_ipv6 map[string]big.Int
        valid_mapped_ipv6_conversion map[string]string
    }

    func str2IntPtr(s string, base int) *big.Int {
        ret, _ := big.NewInt(0).SetString(s, base)
        return ret
    }

    func str2Int(s string, base int) big.Int {
      ret := str2IntPtr(s, base)
      return *ret
    }

    func ipv6MappedSetup() IPv6MappedTest {
        valid_mapped := map[string]big.Int{}
        valid_mapped["::13.1.68.3"] = str2Int("281470899930115", 10);
        valid_mapped["0:0:0:0:0:ffff:129.144.52.38"] = str2Int("281472855454758", 10)
        valid_mapped["::ffff:129.144.52.38"] = str2Int("281472855454758", 10)
        valid_mapped_ipv6 := map[string]big.Int{}
        valid_mapped_ipv6["::ffff:13.1.68.3"] = str2Int("281470899930115", 10)
        valid_mapped_ipv6["0:0:0:0:0:ffff:8190:3426"] = str2Int("281472855454758", 10)
        valid_mapped_ipv6["::ffff:8190:3426"] = str2Int("281472855454758", 10)
        valid_mapped_ipv6_conversion := map[string]string{}
        valid_mapped_ipv6_conversion["::ffff:13.1.68.3"] = "13.1.68.3"
        valid_mapped_ipv6_conversion["0:0:0:0:0:ffff:8190:3426"] = "129.144.52.38"
        valid_mapped_ipv6_conversion["::ffff:8190:3426"] = "129.144.52.38"
        return IPv6MappedTest {
            ip: *Ipv6MappedNew("::172.16.10.1").Unwrap(),
            s: "::ffff:172.16.10.1",
            sstr: "::ffff:172.16.10.1/32",
            _str: "0000:0000:0000:0000:0000:ffff:ac10:0a01/128",
            u128: str2Int("281473568475649", 10),
            address: "::ffff:ac10:a01/128",
            valid_mapped: valid_mapped,
            valid_mapped_ipv6: valid_mapped_ipv6,
            valid_mapped_ipv6_conversion: valid_mapped_ipv6_conversion,
        };
    }


func TestIpv6Mapped(t *testing.T) {
  describe("", func() {
    it("test_initialize", func() {
        s := ipv6MappedSetup()
        assert_bool(true, Parse("::172.16.10.1").IsOk())
        for ip, u128 := range s.valid_mapped {
            // fmt.Printf("-%s--%s\n", ip, u128);
            if Parse(ip).IsErr() {
                fmt.Printf("%s\n", Parse(ip).UnwrapErr());
            }
            assert_bool(true, Parse(ip).IsOk());
            assert_bigint(u128, Parse(ip).Unwrap().Host_address);
        }
        for ip, u128 := range s.valid_mapped_ipv6 {
            // fmt.Printf("====%s==%s", ip, u128);
            assert_bool(true, Parse(ip).IsOk());
            assert_bigint(u128, Parse(ip).Unwrap().Host_address);
        }
    })
    it("test_mapped_from_ipv6_conversion", func() {
        for ip6, ip4 := range ipv6MappedSetup().valid_mapped_ipv6_conversion {
            // fmt.Printf("+%s--%s", ip6, ip4);
            assert_string(ip4, Parse(ip6).Unwrap().Mapped.To_s());
        }
    })
    it ("test_attributes", func() {
        s := ipv6MappedSetup();
        assert_string(s.address, s.ip.To_string());
        assert_uint8(128, s.ip.Prefix.Num);
        assert_string(s.s, s.ip.To_s_mapped());
        assert_string(s.sstr, s.ip.To_string_mapped());
        assert_string(s._str, s.ip.To_string_uncompressed());
        assert_bigint(s.u128, s.ip.Host_address);
    })
    it ("test_method_ipv6", func() {
      s := ipv6MappedSetup().ip
        assert(s.Is_ipv6());
    })
    it ("test_mapped", func() {
      s := ipv6MappedSetup().ip
        assert(s.Is_mapped());
    })
  })
}
