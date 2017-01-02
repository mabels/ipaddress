package prefix32
import (
  "testing"
  // "reflect"
)

type Prefix32Test struct {
    netmask0 string,
    netmask8 string,
    netmask16 string,
    netmask24 string,
    netmask30 string,
    netmasks Vec<String>,
    prefix_hash HashMap<String, usize>,
    octets_hash HashMap<Vec<u16>, usize>,
    u32_hash HashMap<usize, u32>,
}

func setup() Prefix32Test {
    p32t := Prefix32Test {
        "0.0.0.0",
        "255.0.0.0",
        "255.255.0.0",
        "255.255.255.0",
        "255.255.255.252",
        netmasks: Vec::new(),
        prefix_hash: HashMap::new(),
        octets_hash: HashMap::new(),
        u32_hash: HashMap::new(),
    };
    p32t.netmasks.push(p32t.netmask0.clone());
    p32t.netmasks.push(p32t.netmask8.clone());
    p32t.netmasks.push(p32t.netmask16.clone());
    p32t.netmasks.push(p32t.netmask24.clone());
    p32t.netmasks.push(p32t.netmask30.clone());
    p32t.prefix_hash.insert(String::from("0.0.0.0"), 0);
    p32t.prefix_hash.insert(String::from("255.0.0.0"), 8);
    p32t.prefix_hash.insert(String::from("255.255.0.0"), 16);
    p32t.prefix_hash.insert(String::from("255.255.255.0"), 24);
    p32t.prefix_hash.insert(String::from("255.255.255.252"), 30);
    p32t.octets_hash.insert(vec![0, 0, 0, 0], 0);
    p32t.octets_hash.insert(vec![255, 0, 0, 0], 8);
    p32t.octets_hash.insert(vec![255, 255, 0, 0], 16);
    p32t.octets_hash.insert(vec![255, 255, 255, 0], 24);
    p32t.octets_hash.insert(vec![255, 255, 255, 252], 30);
    p32t.u32_hash.insert(0, 0);
    p32t.u32_hash.insert(8, 4278190080);
    p32t.u32_hash.insert(16, 4294901760);
    p32t.u32_hash.insert(24, 4294967040);
    p32t.u32_hash.insert(30, 4294967292);
    return p32t;
}

func TestRleCode(t *testing.T) {
  describe("", func() {
    it("test_attributes", func() {
        for num in setup().prefix_hash.values() {
            let prefix = prefix32::new(*num).unwrap();
            assert_eq!(*num, prefix.num)
        }
    })


    it("test_parse_netmask_to_prefix", func() {
        for (netmask, num) in setup().prefix_hash {
            let prefix = IPAddress::parse_netmask_to_prefix(netmask).unwrap();
            assert_eq!(num, prefix);
        }
    })
    it ("test_method_to_ip", func() {
        for (netmask, num) in setup().prefix_hash {
            let prefix = prefix32::new(num).unwrap();
            assert_eq!(*netmask, prefix.to_ip_str())
        }
    })

    it ("test_method_to_s", func() {
        let prefix = prefix32::new(8).unwrap();
        assert_eq!("8", prefix.to_s())
    })

    it ("test_method_bits", func() {
        let prefix = prefix32::new(16).unwrap();
        assert_eq!("11111111111111110000000000000000", prefix.bits())
    })

    it ("test_method_to_u32", func() {
        for (num, ip32) in setup().u32_hash {
            assert_eq!(ip32,
                       prefix32::new(num).unwrap().netmask().to_u32().unwrap())
        }
    })

    it ("test_method_plus", func() {
        let p1 = prefix32::new(8).unwrap();
        let p2 = prefix32::new(10).unwrap();
        assert_eq!(18, p1.add_prefix(&p2).unwrap().num);
        assert_eq!(12, p1.add(4).unwrap().num)
    })

    it ("test_method_minus", func() {
        let p1 = prefix32::new(8).unwrap();
        let p2 = prefix32::new(24).unwrap();
        assert_eq!(16, p1.sub_prefix(&p2).unwrap().num);
        assert_eq!(16, p2.sub_prefix(&p1).unwrap().num);
        assert_eq!(20, p2.sub(4).unwrap().num);
    })

    it ("test_initialize", func() {
        assert!(prefix32::new(33).is_err());
        assert!(prefix32::new(8).is_ok());
    })

    it ("test_method_octets", func() {
        for (arr, pref) in setup().octets_hash {
            let prefix = prefix32::new(pref).unwrap();
            assert_eq!(prefix.ip_bits.parts(&prefix.netmask()), arr);
        }
    })

    it ("test_method_brackets", func() {
        for (arr, pref) in setup().octets_hash {
            let prefix = prefix32::new(pref).unwrap();
            for index in 0..arr.len() {
                let oct = arr.get(index);
                assert_eq!(prefix.ip_bits.parts(&prefix.netmask()).get(index), oct)
            }
        }
    })

    it ("test_method_hostmask", func() {
        let prefix = prefix32::new(8).unwrap();
        assert_eq!("0.255.255.255",
                   ipv4::from_u32(prefix.host_mask().to_u32().unwrap(), 0).unwrap().to_s());
    })
  })
}
