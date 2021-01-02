package ipaddress

import (
	"math/big"
	"testing"
)

// type gochaFunc func() string

//func Describe(t *MyTesting, desc string, fn func()) {
//	fmt.Printf("describe:[%s]\n", desc)
//	fn()
//}
//
//func it(desc string, fn func()) {
//	fmt.Printf("it:[%s]\n", desc)
//	fn()
//}

type MyTesting struct {
	t *testing.T
}

func (self *MyTesting) Run(title string, fn func(t *MyTesting)) {
	self.t.Run(title, func(t *testing.T) {
		fn(self)
	})
}

func str2IntPtr(s string, base int) *big.Int {
	ret, _ := big.NewInt(0).SetString(s, base)
	return ret
}

func str2Int(s string, base int) big.Int {
	ret := str2IntPtr(s, base)
	return *ret
}

func (self *MyTesting) assert(b bool) {
	if !b {
		self.t.Errorf("t.assert failed")
	}
}

func (self *MyTesting) assert_bool(a bool, b bool) {
	if a != b {
		self.t.Errorf("[%t] != [%t]", a, b)
	}
}

func (self *MyTesting) assert_string(a string, b string) {
	if a != b {
		self.t.Errorf("[%s] != [%s]", a, b)
	}
}

func (self *MyTesting) assert_ipaddress(a *IPAddress, b *IPAddress) {
	if !a.Eq(b) {
		self.t.Errorf("[%s] != [%s]", a, b)
	}
}

func (self *MyTesting) assert_int(a int, b int) {
	if a != b {
		self.t.Errorf("[%d] != [%d]", a, b)
	}
}

func (self *MyTesting) assert_uint(a uint, b uint) {
	if a != b {
		self.t.Errorf("[%d] != [%d]", a, b)
	}
}

func (self *MyTesting) assert_bigint(a big.Int, b big.Int) {
	if a.Cmp(&b) != 0 {
		self.t.Errorf("[%s] != [%s]", a.String(), b.String())
	}
}

func (self *MyTesting) assert_uint8(a uint8, b uint8) {
	if a != b {
		self.t.Errorf("[%d] != [%d]", a, b)
	}
}

func (self *MyTesting) assert_uint16(a uint16, b uint16) {
	if a != b {
		self.t.Errorf("[%d] != [%d]", a, b)
	}
}

func (self *MyTesting) assert_uint64(a uint64, b uint64) {
	if a != b {
		self.t.Errorf("[%d] != [%d]", a, b)
	}
}

func (self *MyTesting) assert_string_array(a []string, b []string) {
	if len(a) != len(b) {
		self.t.Errorf("len [%d] != [%d]", len(a), len(b))
	}
	for i := 0; i < len(a); i++ {
		if a[i] != b[i] {
			self.t.Errorf("%d:[%s] != [%s]", i, a[i], b[i])
		}
	}
}

func (self *MyTesting) assert_uint16_array(a []uint16, b []uint16) {
	if len(a) != len(b) {
		self.t.Errorf("len [%d] != [%d]", len(a), len(b))
	}
	for i := 0; i < len(a); i++ {
		if a[i] != b[i] {
			self.t.Errorf("%d:[%d] != [%d]", i, a[i], b[i])
		}
	}
}
