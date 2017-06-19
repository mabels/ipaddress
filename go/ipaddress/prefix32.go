package ipaddress

import "fmt"

func Prefix32From(my *Prefix, num uint8) ResultPrefix {
	return Prefix32New(num)
}

///  Gives the prefix in IPv4 dotted decimal format,
///  i.e. the canonical netmask we're all used to
///
///    prefix = IPAddress::prefix::Prefix32.new 24
///
///    prefix.to_ip
///      ///  "255.255.255.0"
///
func Prefix32New(num uint8) ResultPrefix {
	if num <= 32 {
		ipBits := IpBitsV4()
		bits := ipBits.Bits
		tmp := New_netmask(uint8(num), bits)
		return &PrefixOk{&Prefix{
			uint8(num),
			ipBits,
			*tmp,
			Prefix32From,
			//vt_to_ip_str: _TO_IP_STR,
		}}
	}
	tmp := fmt.Sprintf("Prefix must be in range 0..32, got: %d", num)
	return &PrefixError{&tmp}
}
