package ipaddress

import "math/big"
import "testing"
import "bytes"
import "./prefix/prefix128"

type Prefix128Test struct {
	u128_hash map[uint8]big.Int
}

func prefix128Setup() Prefix128Test {
	p128t := Prefix128Test{u128_hash: map[uint8]big.Int{}}
	p128t.u128_hash[32] = str2Int("340282366841710300949110269838224261120", 10)
	p128t.u128_hash[64] = str2Int("340282366920938463444927863358058659840", 10)
	p128t.u128_hash[96] = str2Int("340282366920938463463374607427473244160", 10)
	p128t.u128_hash[126] = str2Int("340282366920938463463374607431768211452", 10)
	return p128t
}

func TestPrefix128(tx *testing.T) {
	t := MyTesting{tx}
	t.Run("TestRleCode", func(t *MyTesting) {
		t.Run("test_initialize", func(t *MyTesting) {
			t.assert(prefix128.New(129).IsErr())
			t.assert(prefix128.New(64).IsOk())
		})

		t.Run("test_method_bits", func(t *MyTesting) {
			prefix := prefix128.New(64).Unwrap()
			var str bytes.Buffer
			for i := 0; i < 64; i++ {
				str.WriteString("1")
			}
			for i := 0; i < 64; i++ {
				str.WriteString("0")
			}
			t.assert_string(str.String(), prefix.Bits())
		})

		t.Run("test_method_to_u32", func(t *MyTesting) {
			for num, u128 := range prefix128Setup().u128_hash {
				t.assert_bigint(u128, prefix128.New(num).Unwrap().Netmask)
			}
		})
	})
}
