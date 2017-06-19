package ipaddress

import "testing"
import "./prefix/prefix32"

// import "../../../gocha"

type Prefix32ArrayTuple struct {
	arr []uint16
	num uint8
}

type Prefix32Test struct {
	netmask0    string
	netmask8    string
	netmask16   string
	netmask24   string
	netmask30   string
	netmasks    []string
	prefix_hash map[string]uint8
	octets_hash []Prefix32ArrayTuple
	u32_hash    map[uint8]uint64
}

func prefix32Setup() Prefix32Test {
	p32t := Prefix32Test{
		netmask0:    "0.0.0.0",
		netmask8:    "255.0.0.0",
		netmask16:   "255.255.0.0",
		netmask24:   "255.255.255.0",
		netmask30:   "255.255.255.252",
		netmasks:    []string{},
		prefix_hash: map[string]uint8{},
		octets_hash: []Prefix32ArrayTuple{},
		u32_hash:    map[uint8]uint64{}}

	p32t.netmasks = append(p32t.netmasks, p32t.netmask0)
	p32t.netmasks = append(p32t.netmasks, p32t.netmask8)
	p32t.netmasks = append(p32t.netmasks, p32t.netmask16)
	p32t.netmasks = append(p32t.netmasks, p32t.netmask24)
	p32t.netmasks = append(p32t.netmasks, p32t.netmask30)

	p32t.prefix_hash["0.0.0.0"] = 0
	p32t.prefix_hash["255.0.0.0"] = 8
	p32t.prefix_hash["255.255.0.0"] = 16
	p32t.prefix_hash["255.255.255.0"] = 24
	p32t.prefix_hash["255.255.255.252"] = 30

	p32t.octets_hash = append(p32t.octets_hash, Prefix32ArrayTuple{[]uint16{0, 0, 0, 0}, 0})
	p32t.octets_hash = append(p32t.octets_hash, Prefix32ArrayTuple{[]uint16{255, 0, 0, 0}, 8})
	p32t.octets_hash = append(p32t.octets_hash, Prefix32ArrayTuple{[]uint16{255, 255, 0, 0}, 16})
	p32t.octets_hash = append(p32t.octets_hash, Prefix32ArrayTuple{[]uint16{255, 255, 255, 0}, 24})
	p32t.octets_hash = append(p32t.octets_hash, Prefix32ArrayTuple{[]uint16{255, 255, 255, 252}, 30})

	p32t.u32_hash[0] = 0
	p32t.u32_hash[8] = 4278190080
	p32t.u32_hash[16] = 4294901760
	p32t.u32_hash[24] = 4294967040
	p32t.u32_hash[30] = 4294967292
	return p32t
}

func TestPrefix32(tx *testing.T) {
  t := MyTesting{tx}
	t.Run("TestPrefix32", func(t *MyTesting) {
		t.Run("test_attributes", func(t *MyTesting) {
			for _, num := range prefix32Setup().prefix_hash {
				prefix := prefix32.New(num).Unwrap()
				t.assert_uint8(num, prefix.Num)
			}
		})

		t.Run("test_parse_netmask_to_prefix", func(t *MyTesting) {
			for netmask, num := range prefix32Setup().prefix_hash {
				pnum, _ := Parse_netmask_to_prefix(netmask)
				t.assert_uint8(num, *pnum)
			}
		})
		t.Run("test_method_to_ip", func(t *MyTesting) {
			for netmask, num := range prefix32Setup().prefix_hash {
				prefix := prefix32.New(num).Unwrap()
				t.assert_string(netmask, prefix.To_ip_str())
			}
		})

		t.Run("test_method_to_s", func(t *MyTesting) {
			prefix := prefix32.New(8).Unwrap()
			t.assert_string("8", prefix.To_s())
		})

		t.Run("test_method_bits", func(t *MyTesting) {
			prefix := prefix32.New(16).Unwrap()
			t.assert_string("11111111111111110000000000000000", prefix.Bits())
		})

		t.Run("test_method_to_u32", func(t *MyTesting) {
			for num, ip32 := range prefix32Setup().u32_hash {
				t.assert_uint64(ip32, prefix32.New(num).Unwrap().Netmask.Uint64())
			}
		})

		t.Run("test_method_plus", func(t *MyTesting) {
			p1 := prefix32.New(8).Unwrap()
			p2 := prefix32.New(10).Unwrap()
			t.assert_uint8(18, p1.Add_prefix(p2).Unwrap().Num)
			t.assert_uint8(12, p1.Add(4).Unwrap().Num)
		})

		t.Run("test_method_minus", func(t *MyTesting) {
			p1 := prefix32.New(8).Unwrap()
			p2 := prefix32.New(24).Unwrap()
			t.assert_uint8(16, p1.Sub_prefix(p2).Unwrap().Num)
			t.assert_uint8(16, p2.Sub_prefix(p1).Unwrap().Num)
			t.assert_uint8(20, p2.Sub(4).Unwrap().Num)
		})

		t.Run("test_initialize", func(t *MyTesting) {
			t.assert(prefix32.New(33).IsErr())
			t.assert(prefix32.New(8).IsOk())
		})

		t.Run("test_method_octets", func(t *MyTesting) {
			for _, e := range prefix32Setup().octets_hash {
				pref := e.num
				prefix := prefix32.New(pref).Unwrap()
				t.assert_uint16_array(prefix.IpBits.Parts(&prefix.Netmask), e.arr)
			}
		})

		t.Run("test_method_brackets", func(t *MyTesting) {
			for _, e := range prefix32Setup().octets_hash {
				arr := e.arr
				pref := e.num
				prefix := prefix32.New(pref).Unwrap()
				for index := 0; index < len(arr); index++ {
					oct := arr[index]
					t.assert_uint16(prefix.IpBits.Parts(&prefix.Netmask)[index], oct)
				}
			}
		})

		t.Run("test_method_hostmask", func(t *MyTesting) {
			prefix := prefix32.New(8).Unwrap()
			t.assert_string("0.255.255.255",
				From_u32(uint32(prefix.Host_mask().Uint64()), 0).Unwrap().To_s())
		})
	})
}
