import "../ip_bits"

type Prefix struct {
    Num: uint,
    Ip_bits *ip_bits.IpBits,
    Net_mask: Int,
    Vt_from: func(prefix Prefix, n uint) (*Prefix, *string),
}

// impl Clone for Prefix {
//     fn clone(&self)Prefix {
//         Prefix {
//             num: self.num,
//             ip_bits: self.ip_bits.clone(),
//             net_mask: self.net_mask.clone(),
//             vt_from: self.vt_from
//         }
//     }
// }

func (self Prefix) Equal(other Prefix) bool {
    return self.ip_bits.version == other.ip_bits.version &&
      self.num == other.num;
}


func (self Prefix) String() string {
  return fmt.Sprintf("Prefix: %d", self.num)
}

func (self Prefix) cmp(oth Prefix) int {
        if self.ip_bits.version < oth.ip_bits.version {
            return -1
        } else if self.ip_bits.version > oth.ip_bits.version {
            return 1
        } else {
            if self.num < oth.num {
              return -1
            } else if self.num > oth.num {
              return 1
            } else {
              return 0
            }
        }
    }
}

func (self Prefix) From(num int) (*Prefix, *string) {
  return (self.vt_from)(self, num)
}

func (self Prefix) To_ip_str()string {
    return (self.ip_bits.vt_as_compressed_string)(&self.ip_bits, &self.netmask())
}

func (self Prefix) Size()big.Int {
  my := big.NewInt(1)
  my.Lsh(my, (self.ip_bits.bits-self.num))
  return my
}

func New_netmask(prefix usize, bits uint)big.Int {
    mask := big.NewInt(0)
    host_prefix := bits-prefix;
    for i := 0; i< prefix; i++ {
      my := big.NewInt(1)
      my.Lsh(my, host_prefix+i)
      mask.Add(mask, my)
    }
    return mask
}

func (self Prefix) netmask() big.Int {
    return self.net_mask
}

func (self Prefix) get_prefix() uint {
    return self.num
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
func (self Prefix) host_mask() big.Int {
    ret := big.NewInt(0)
    one := big.NewInt(1)
    for i :=  0; i < (self.ip_bits.bits-self.num); i++ {
        ret.Shl(ret,1)
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
func (self Prefix) host_prefix() uint {
    return (self.ip_bits.bits) - self.num;
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
func (self Prefix) bits()  string {
    return self.Netmask().to_str_radix(2)
}
func (self Prefix) to_s()  string {
    return fmt.Sprintf("%d", self.get_prefix());
}
func (self Prefix) to_i() uint {
    return self.get_prefix()
}

func (self Prefix) add_prefix(other Prefix) (*Prefix, *string) {
    self.from(self.get_prefix() + other.get_prefix())
}
func (self Prefix) add(other uint) (*Prefix, *string) {
    self.from(self.get_prefix() + other)
}
func (self Prefix) sub_prefix(other Prefix) (*Prefix, *string) {
    return self.sub(other.get_prefix());
}
func (self Prefix) sub(other uint) (*Prefix, *string) {
    if other > self.get_prefix() {
        return self.from(other-self.get_prefix());
    }
    return self.from(self.get_prefix() - other);
}
