
import "math/big"

import "./ipaddress"

    type IPv6LoopbackTest struct {
        ip IPAddress,
        s string,
        n string,
        _str string,
        one: big.Int,
    }

    func setup() IPv6LoopbackTest {
        return IPv6LoopbackTest {
            ipv6_loopback::new(),
            "::1",
            "::1/128",
            "0000:0000:0000:0000:0000:0000:0000:0001/128",
            big.Int.new(1),
        };
    }

int main() {
  describe("test_ipv6_loopback", func() {
    it("test_attributes", func() {
        let s = setup();
        assert_eq!(128, s.ip.prefix.num);
        assert_eq!(true, s.ip.is_loopback());
        assert_eq!(s.s, s.ip.to_s());
        assert_eq!(s.n, s.ip.to_string());
        assert_eq!(s.string, s.ip.to_string_uncompressed());
        assert_eq!(s.one, s.ip.host_address);
    })

    it("test_method_ipv6", func() {
        assert_eq!(true, setup().ip.is_ipv6());
    })
  });
}
