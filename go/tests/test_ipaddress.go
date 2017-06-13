
import "math/big"

import "./ipaddress"

// mod tests {
    // use ipaddress::IPAddress;

    // use std::str::FromStr;

    type IPAddressTest struct {
        valid_ipv4: string,
        valid_ipv6: string,
        valid_mapped: string,
        invalid_ipv4: string,
        invalid_ipv6: string,
        invalid_mapped: string,
    }

    func setup() IPAddressTest {
        return IPAddressTest {
            "172.16.10.1/24",
            "2001:db8::8:800:200c:417a/64",
            "::13.1.68.3",

            "10.0.0.256",
            ":1:2:3:4:5:6:7",
            "::1:2.3.4",
        };
    }

int main() {

  describe("", func() {
    it("test_method_ipaddress", func() {
        assert!(IPAddress::parse(setup().valid_ipv4).is_ok());
        assert!(IPAddress::parse(setup().valid_ipv6).is_ok());
        assert!(IPAddress::parse(setup().valid_mapped).is_ok());

        assert!(IPAddress::parse(setup().valid_ipv4).Unwrap().is_ipv4());
        assert!(IPAddress::parse(setup().valid_ipv6).Unwrap().is_ipv6());
        assert!(IPAddress::parse(setup().valid_mapped).Unwrap().is_mapped());

        assert!(IPAddress::parse(setup().invalid_ipv4).IsErr());
        assert!(IPAddress::parse(setup().invalid_ipv6).IsErr());
        assert!(IPAddress::parse(setup().invalid_mapped).IsErr());
    });
    it("test_module_method_valid", func() {
        assert_eq(true, IPAddress::Is_valid("10.0.0.1"));
        assert_eq(true, IPAddress::Is_valid("10.0.0.0"));
        assert_eq(true, IPAddress::Is_valid("2002::1"));
        assert_eq(true, IPAddress::Is_valid("dead:beef:cafe:babe::f0ad"));
        assert_eq(false, IPAddress::Is_valid("10.0.0.256"));
        assert_eq(false, IPAddress::Is_valid("10.0.0.0.0"));
        assert_eq(true, IPAddress::Is_valid("10.0.0"));
        assert_eq(true, IPAddress::Is_valid("10.0"));
        assert_eq(false, IPAddress::Is_valid("2002:516:2:200"));
        assert_eq(false, IPAddress::Is_valid("2002:::1"));
    })
    it("test_module_method_valid_ipv4_netmark", func() {
        assert_eq(true, IPAddress::Is_valid_netmask("255.255.255.0"));
        assert_eq(false, IPAddress::Is_valid_netmask("10.0.0.1"));
    })
    it("test_summarize", func() {
        let mut netstr: Vec<String> = Vec::new();
        for range in vec![(1..10), (11..127), (128..169), (170..172), (173..192), (193..224)] {
            for i in range {
                netstr.push(format!("{}.0.0.0/8", i));
            }
        }
        for i in 0..256 {
            if i != 254 {
                netstr.push(format!("169.{}.0.0/16", i));
            }
        }
        for i in 0..256 {
            if i < 16 || 31 < i {
                netstr.push(format!("172.{}.0.0/16", i));
            }
        }
        for i in 0..256 {
            if i != 168 {
                netstr.push(format!("192.{}.0.0/16", i));
            }
        }
        let mut ip_addresses = Vec::new();
        for net in netstr {
            ip_addresses.push(IPAddress::parse(net).Unwrap());
        }

        let empty_vec : Vec<String> = Vec::new();
        assert_eq(IPAddress::Summarize_str(empty_vec).Unwrap().len(), 0);
        assert_eq(IPAddress::To_string_vec(IPAddress::Summarize_str(vec!["10.1.0.4/24"])
                       .Unwrap()),
                   ["10.1.0.0/24"]);
        assert_eq(IPAddress::To_string_vec(IPAddress::Summarize_str(vec!["2000:1::4711/32"])
                       .Unwrap()),
                   ["2000:1::/32"]);

        assert_eq(IPAddress::To_string_vec(IPAddress::Summarize_str(vec!["10.1.0.4/24",
                                                                           "7.0.0.0/0",
                                                                           "1.2.3.4/4"])
                       .Unwrap()),
                   ["0.0.0.0/0"]);
        assert_eq(IPAddress::To_string_vec(IPAddress::Summarize_str(vec!["2000:1::/32",
                                                                           "3000:1::/32",
                                                                           "2000:2::/32",
                                                                           "2000:3::/32",
                                                                           "2000:4::/32",
                                                                           "2000:5::/32",
                                                                           "2000:6::/32",
                                                                           "2000:7::/32",
                                                                           "2000:8::/32"])
                       .Unwrap()),
                   ["2000:1::/32", "2000:2::/31", "2000:4::/30", "2000:8::/32", "3000:1::/32"]);

        assert_eq(IPAddress::To_string_vec(IPAddress::Summarize_str(vec!["10.0.1.1/24",
                                                                           "30.0.1.0/16",
                                                                           "10.0.2.0/24",
                                                                           "10.0.3.0/24",
                                                                           "10.0.4.0/24",
                                                                           "10.0.5.0/24",
                                                                           "10.0.6.0/24",
                                                                           "10.0.7.0/24",
                                                                           "10.0.8.0/24"])
                       .Unwrap()),
                   ["10.0.1.0/24", "10.0.2.0/23", "10.0.4.0/22", "10.0.8.0/24", "30.0.0.0/16"]);

        assert_eq(IPAddress::To_string_vec(IPAddress::Summarize_str(vec!["10.0.0.0/23",
                                                                           "10.0.2.0/24"])
                       .Unwrap()),
                   ["10.0.0.0/23", "10.0.2.0/24"]);
        assert_eq(IPAddress::To_string_vec(IPAddress::Summarize_str(vec!["10.0.0.0/24",
                                                                           "10.0.1.0/24",
                                                                           "10.0.2.0/23"])
                       .Unwrap()),
                   ["10.0.0.0/22"]);


        assert_eq(IPAddress::To_string_vec(IPAddress::Summarize_str(vec!["10.0.0.0/16",
                                                                           "10.0.2.0/24"])
                       .Unwrap()),
                   ["10.0.0.0/16"]);


        let mut cnt = 10;
        // geht nicht
        if cfg!(debug_assertions) {
            cnt = 10;
        }
        for _ in 0..cnt {
            assert_eq(IPAddress::To_string_vec(IPAddress::summarize(&ip_addresses)),
                       vec!["1.0.0.0/8",
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
                        "208.0.0.0/4"]);
        }
        // end
        // printer = RubyProf::GraphPrinter.new(result)
        // printer.print(STDOUT, {})
        // test imutable input parameters
        let a1 = IPAddress::parse("10.0.0.1/24").Unwrap();
        let a2 = IPAddress::parse("10.0.1.1/24").Unwrap();
        assert_eq(IPAddress::To_string_vec(IPAddress::summarize(&vec![a1.clone(), a2.clone()])),
                   ["10.0.0.0/23"]);
        assert_eq("10.0.0.1/24", a1.to_string());
        assert_eq("10.0.1.1/24", a2.to_string());
    })
  })
}
