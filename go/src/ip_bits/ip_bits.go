package ip_bits

import "math/big"
import "bytes"
import "fmt"
import "../rle"
import "../ip_version"


type IpBits struct {
    Version ip_version.Family
    Vt_as_compressed_string func(ipb *IpBits, d big.Int)string
    Vt_as_uncompressed_string func(ipb *IpBits, d big.Int)string
    Bits uint8
    Part_bits uint8
    Dns_bits uint8
    Rev_domain string
    Part_mod big.Int
    Host_ofs big.Int // ipv4=1, ipv6=0
}

func ipv4_as_compressed(ip_bits *IpBits, host_address big.Int) string {
  var ret bytes.Buffer
  sep := ""
  for _,part := range ip_bits.Parts(host_address) {
      ret.WriteString(sep);
      ret.WriteString(fmt.Sprintf("%d", part));
      sep = ".";
  }
  return ret.String();
}

func ipv6_as_compressed(ip_bits *IpBits, host_address big.Int) string {
    //println!("ipv6_as_compressed:{}", host_address);
    var ret bytes.Buffer
    the_colon := ":";
    the_empty := "";
    colon := &the_empty;
    done := false;
    for _,rle := range rle.Code(ip_bits.Parts(host_address)) {
        // println!(">>{:?}", rle);
        for i := 0; i < rle.Cnt; i++ {
            if done || !(rle.Part == 0 && rle.Max) {
                ret.WriteString(fmt.Sprintf("%s%x", colon, rle.Part));
                colon = &the_colon;
            } else if rle.Part == 0 && rle.Max {
                ret.WriteString("::");
                colon = &the_empty;
                done = true;
                break;
            }
        }
    }
    return ret.String();
}

func ipv6_as_uncompressed(ip_bits *IpBits, host_address big.Int) string {
    var ret bytes.Buffer
    sep := ""
    for _,part := range ip_bits.Parts(host_address) {
        ret.WriteString(sep);
        ret.WriteString(fmt.Sprintf("%04x", part));
        sep = ":";
    }
    return ret.String();
}


func v4const() IpBits {
  return IpBits {
    ip_version.V4,
    ipv4_as_compressed,
    ipv4_as_compressed,
    32,
    8,
    8,
    "in-addr.arpa",
    *big.NewInt(1<<8),
    *big.NewInt(1),
  };
}

func v6const() IpBits {
  return IpBits {
    ip_version.V6,
    ipv6_as_compressed,
    ipv6_as_uncompressed,
    128,
    16,
    4,
    "ip6.arpa",
    *big.NewInt(1<<16),
    *big.NewInt(0),
  }
};

func (ipb IpBits) String() string {
	return fmt.Sprintf("IpBits:version:{%d},bits:{%d},part_bits:{%d},dns_bits:{%d},rev_domain:{%s},part_mod:{%s},host_ofs:{%s}",
    ipb.Version, ipb.Bits, ipb.Part_bits, ipb.Dns_bits, ipb.Rev_domain, ipb.Part_mod, ipb.Host_ofs)
}

func reverse(numbers []uint16) []uint16 {
	for i := 0; i < len(numbers)/2; i++ {
		j := len(numbers) - i - 1
		numbers[i], numbers[j] = numbers[j], numbers[i]
	}
	return numbers
}


func (self *IpBits) Parts(bu big.Int) []uint16 {
  vec := make([]uint16, 0)
  my := bu
  // part_mod := BigUint::one() << self.part_bits;// - BigUint::one();
  for i := uint8(0); i < (self.Bits / self.Part_bits); i++ {
      //func (z *Int) Mod(x, y *Int) *Int
      // func (x *Int) Int64() int64
      // func (z *Int) Rem(x, y *Int) *Int
      my.Rem(&my, &self.Part_mod)
      vec = append(vec, uint16(my.Int64()))
      my.Rsh(&my, uint(self.Part_bits))
  }
  return reverse(vec)
}

func (self *IpBits) As_compressed_string(bu big.Int) string {
    return (self.Vt_as_compressed_string)(self, bu);
}

func (self *IpBits) As_uncompressed_string(bu big.Int) string {
    return (self.Vt_as_uncompressed_string)(self, bu);
}


func (self *IpBits) Dns_part_format(i  uint8) string {
  switch self.Version {
    case ip_version.V4 : return fmt.Sprintf("%d", i);
    case ip_version.V6 : return fmt.Sprintf("%x", i);
    default: return "";
  }
}

var v4ref *IpBits;
func V4() *IpBits {
  return v4ref;
}

var v6ref *IpBits;
func V6() *IpBits {
  return v6ref;
}
