
import "math/big"

import "./ipaddress"

    type IPv6UnspecifiedTest struct {
        ip: IPAddress,
        to_s: string,
        to_string: string,
        to_string_uncompressed: string,
        num: big.Int,
    }

    func setup() IPv6UnspecifiedTest {
        return IPv6UnspecifiedTest {
            ip: ipv6_unspec.New(),
            to_s: "::",
            to_string: "::/128",
            to_string_uncompressed: "0000:0000:0000:0000:0000:0000:0000:0000/128",
            num: big.Int.New()
        };
    }

int main() {
  describe("", func() {
    it("test_attributes", func() {
        assert_eq(setup().ip.host_address, setup().num);
        assert_eq(128, setup().ip.prefix().get_prefix());
        assert_eq(true, setup().ip.is_unspecified());
        assert_eq(setup().to_s, setup().ip.to_s());
        assert_eq(setup().to_string, setup().ip.to_string());
        assert_eq(setup().to_string_uncompressed,
                   setup().ip.to_string_uncompressed());
    })
    it("test_method_ipv6", func() {
        assert_eq(true, setup().ip.is_ipv6());
    })
  }
}
