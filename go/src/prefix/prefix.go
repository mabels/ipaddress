package prefix

import "../ip_bits"
import "math/big"
import "fmt"

type Prefix struct {
    Num uint8
    Ip_bits *ip_bits.IpBits
    Net_mask big.Int
    Vt_from func(prefix *Prefix, n uint8)(*Prefix, *string)
}

    func (self *Prefix) Clone() Prefix {
        return Prefix {
            self.Num,
            self.Ip_bits,
            self.Net_mask,
            self.Vt_from }
    }

func (self *Prefix) Equal(other Prefix) bool {
    return self.Ip_bits.Version == other.Ip_bits.Version &&
      self.Num == other.Num;
}


func (self *Prefix) String() string {
  return fmt.Sprintf("Prefix: %d", self.Num)
}

func (self *Prefix) Cmp(oth *Prefix) int {
        if self.Ip_bits.Version < oth.Ip_bits.Version {
            return -1
        } else if self.Ip_bits.Version > oth.Ip_bits.Version {
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

func (self *Prefix) From(num uint8) (*Prefix, *string) {
  return (self.Vt_from)(self, num)
}

func (self *Prefix) To_ip_str()string {
    return (self.Ip_bits.Vt_as_compressed_string)(self.Ip_bits, self.Netmask())
}

func (self *Prefix) Size() *big.Int {
  my := big.NewInt(1)
  my.Lsh(my, uint(self.Ip_bits.Bits-self.Num))
  return my
}

func New_netmask(prefix uint8, bits uint8)*big.Int {
    mask := big.NewInt(0)
    host_prefix := bits-prefix;
    for i := uint8(0); i< prefix; i++ {
      my := big.NewInt(1)
      my.Lsh(my, uint(host_prefix+i))
      mask.Add(mask, my)
    }
    return mask
}

func (self *Prefix) Netmask() big.Int {
    return self.Net_mask
}

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
    for i :=  uint8(0); i < (self.Ip_bits.Bits-self.Num); i++ {
        ret.Lsh(ret,1)
        ret.Add(ret, one)
    }
    return ret;
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
    return (self.Ip_bits.Bits) - self.Num;
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
func (self *Prefix) Bits()  string {
    return self.Net_mask.Text(2)
}
func (self *Prefix) To_s()  string {
    return fmt.Sprintf("%d", self.Num);
}
func (self *Prefix) To_i() uint8 {
    return self.Num
}

func (self *Prefix) Add_prefix(other *Prefix) (*Prefix, *string) {
    return self.From(self.Num + other.Num)
}
func (self *Prefix) Add(other uint8) (*Prefix, *string) {
    return self.From(self.Get_prefix() + other)
}
func (self *Prefix) Sub_prefix(other Prefix) (*Prefix, *string) {
    return self.Sub(other.Num);
}
func (self *Prefix) Sub(other uint8) (*Prefix, *string) {
    if other > self.Num {
        return self.From(other-self.Num);
    }
    return self.From(self.Num - other);
}
