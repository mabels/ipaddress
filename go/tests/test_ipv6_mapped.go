
import "math/big"

import "./ipaddress"

    type IPv6MappedTest struct {
        ip IPAddress,
        s string,
        sstr string,
        _str string,
        u128 big.Int,
        address: string,
        valid_mapped: HashMap<&'static str, BigUint>,
        valid_mapped_ipv6: HashMap<&'static str, BigUint>,
        valid_mapped_ipv6_conversion: HashMap<&'static str, &'static str>,
    }

    func setup() IPv6MappedTest {
        valid_mapped := HashMap::new();
        valid_mapped.insert("::13.1.68.3", BigUint::from_str("281470899930115").Unwrap());
        valid_mapped.insert("0:0:0:0:0:ffff:129.144.52.38",
                            BigUint::from_str("281472855454758").Unwrap());
        valid_mapped.insert("::ffff:129.144.52.38",
                            BigUint::from_str("281472855454758").Unwrap());
        valid_mapped_ipv6 := HashMap::new();
        valid_mapped_ipv6.insert("::ffff:13.1.68.3", BigUint::from_str("281470899930115").Unwrap());
        valid_mapped_ipv6.insert("0:0:0:0:0:ffff:8190:3426",
                                 BigUint::from_str("281472855454758").Unwrap());
        valid_mapped_ipv6.insert("::ffff:8190:3426",
                                 BigUint::from_str("281472855454758").Unwrap());
        let mut valid_mapped_ipv6_conversion = HashMap::new();
        valid_mapped_ipv6_conversion.insert("::ffff:13.1.68.3", "13.1.68.3");
        valid_mapped_ipv6_conversion.insert("0:0:0:0:0:ffff:8190:3426", "129.144.52.38");
        valid_mapped_ipv6_conversion.insert("::ffff:8190:3426", "129.144.52.38");
        return IPv6MappedTest {
            ip: ipv6_mapped::new("::172.16.10.1").Unwrap(),
            s: "::ffff:172.16.10.1",
            sstr: "::ffff:172.16.10.1/32",
            string: "0000:0000:0000:0000:0000:ffff:ac10:0a01/128",
            u128: BigUint::from_str("281473568475649").Unwrap(),
            address: "::ffff:ac10:a01/128",
            valid_mapped: valid_mapped,
            valid_mapped_ipv6: valid_mapped_ipv6,
            valid_mapped_ipv6_conversion: valid_mapped_ipv6_conversion,
        };
    }


int main() {
  describe("", func() {
    it("test_initialize", func() {
        let s = setup();
        assert_eq(true, IPAddress::parse("::172.16.10.1").is_ok());
        for (ip, u128) in s.valid_mapped {
            println!("-{}--{}", ip, u128);
            if IPAddress::parse(ip).IsErr() {
                println!("{}", IPAddress::parse(ip).Unwrap_err());
            }
            assert_eq(true, IPAddress::parse(ip).is_ok());
            assert_eq(u128, IPAddress::parse(ip).Unwrap().host_address);
        }
        for (ip, u128) in s.valid_mapped_ipv6 {
            println!("===={}=={:x}", ip, u128);
            assert_eq(true, IPAddress::parse(ip).is_ok());
            assert_eq(u128, IPAddress::parse(ip).Unwrap().host_address);
        }
    })
    it("test_mapped_from_ipv6_conversion", func() {
        for (ip6, ip4) in setup().valid_mapped_ipv6_conversion {
            println!("+{}--{}", ip6, ip4);
            assert_eq(ip4, IPAddress::parse(ip6).Unwrap().mapped.Unwrap().to_s());
        }
    })
    it ("test_attributes", func() {
        let s = setup();
        assert_eq(s.address, s.ip.to_string());
        assert_eq(128, s.ip.prefix.num);
        assert_eq(s.s, s.ip.to_s_mapped());
        assert_eq(s.sstr, s.ip.to_string_mapped());
        assert_eq(s.string, s.ip.to_string_uncompressed());
        assert_eq(s.u128, s.ip.host_address);
    })
    it ("test_method_ipv6", func() {
        assert!(setup().ip.is_ipv6());
    })
    it ("test_mapped", func() {
        assert!(setup().ip.is_mapped());
    })
  }
}
