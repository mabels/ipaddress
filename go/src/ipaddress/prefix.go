package ipaddress

import "math/big"
import "fmt"

type ResultPrefix interface {
	IsOk() bool
	IsErr() bool
	Unwrap() *Prefix
	UnwrapErr() *string
}

type Prefix struct {
	Num     uint8
	IpBits  *IpBits
	Netmask big.Int
	Vt_from func(prefix *Prefix, n uint8) ResultPrefix
}

type PrefixError struct {
	Err *string
}

func (self *PrefixError) IsOk() bool         { return false }
func (self *PrefixError) IsErr() bool        { return true }
func (self *PrefixError) Unwrap() *Prefix    { return nil }
func (self *PrefixError) UnwrapErr() *string { return self.Err }

// func Error(err *string) *ErrorIsh {
//     return &ErrorIsh{err}
// }

type PrefixOk struct {
	Prefix *Prefix
}

func (self *PrefixOk) IsOk() bool         { return true }
func (self *PrefixOk) IsErr() bool        { return false }
func (self *PrefixOk) Unwrap() *Prefix    { return self.Prefix }
func (self *PrefixOk) UnwrapErr() *string { return nil }

func (self *Prefix) Clone() *Prefix {
	ret := new(Prefix)
	ret.Num = self.Num
	ret.IpBits = self.IpBits
	ret.Netmask = self.Netmask
	ret.Vt_from = self.Vt_from
	return ret
}

func (self *Prefix) Equal(other Prefix) bool {
	return self.IpBits.Version == other.IpBits.Version &&
		self.Num == other.Num
}

func (self *Prefix) String() string {
	return fmt.Sprintf("Prefix: %d", self.Num)
}

func (self *Prefix) Cmp(oth *Prefix) int {
	if self.IpBits.Version < oth.IpBits.Version {
		return -1
	} else if self.IpBits.Version > oth.IpBits.Version {
		return 1
	} else {
		if self.Num < oth.Num {
			return -1
		} else if self.Num > oth.Num {
			return 1
		} else {
			return 0
		}
	}
}

func (self *Prefix) From(num uint8) ResultPrefix {
	return (self.Vt_from)(self, num)
}

func (self *Prefix) To_ip_str() string {
	return (self.IpBits.Vt_as_compressed_string)(self.IpBits, &self.Netmask)
}

func (self *Prefix) Size() *big.Int {
	my := big.NewInt(1)
	my.Lsh(my, uint(self.IpBits.Bits-self.Num))
	return my
}

func New_netmask(prefix uint8, bits uint8) *big.Int {
	mask := big.NewInt(0)
	host_prefix := bits - prefix
	for i := uint8(0); i < prefix; i++ {
		my := big.NewInt(1)
		my.Lsh(my, uint(host_prefix+i))
		mask.Add(mask, my)
	}
	return mask
}

//func (self *Prefix) Netmask() *big.Int {
//	return &self.Net_mask
//}

func (self *Prefix) Get_prefix() uint8 {
	return self.Num
}

///  The hostmask is the contrary of the subnet mask,
///  as it shows the bits that can change within the
///  hosts
///
///    prefix = IPAddress::Prefix32.new 24
///
///    prefix.hostmask
///      ///  "0.0.0.255"
///
func (self *Prefix) Host_mask() *big.Int {
	ret := big.NewInt(0)
	one := big.NewInt(1)
	for i := uint8(0); i < (self.IpBits.Bits - self.Num); i++ {
		ret.Lsh(ret, 1)
		ret.Add(ret, one)
	}
	return ret
}

///
///  Returns the length of the host portion
///  of a netmask.
///
///    prefix = Prefix128.new 96
///
///    prefix.host_prefix
///      ///  128
///
func (self *Prefix) Host_prefix() uint8 {
	return (self.IpBits.Bits) - self.Num
}

///
///  Transforms the prefix into a string of bits
///  representing the netmask
///
///    prefix = IPAddress::Prefix128.new 64
///
///    prefix.bits
///      ///  "1111111111111111111111111111111111111111111111111111111111111111"
///          "0000000000000000000000000000000000000000000000000000000000000000"
///
func (self *Prefix) Bits() string {
	return self.Netmask.Text(2)
}
func (self *Prefix) To_s() string {
	return fmt.Sprintf("%d", self.Num)
}
func (self *Prefix) To_i() uint8 {
	return self.Num
}

func (self *Prefix) Add_prefix(other *Prefix) ResultPrefix {
	return self.From(self.Num + other.Num)
}
func (self *Prefix) Add(other uint8) ResultPrefix {
	return self.From(self.Get_prefix() + other)
}
func (self *Prefix) Sub_prefix(other *Prefix) ResultPrefix {
	return self.Sub(other.Num)
}
func (self *Prefix) Sub(other uint8) ResultPrefix {
	if other > self.Num {
		return self.From(other - self.Num)
	}
	return self.From(self.Num - other)
}
