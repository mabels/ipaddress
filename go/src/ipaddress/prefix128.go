package ipaddress

import "fmt"

///
///  Creates a new prefix object for 128 bits IPv6 addresses
///
///    prefix = IPAddressPrefix128.new 64
///      ///  64
///
func Prefix128New(num uint8) ResultPrefix {
	if num <= 128 {
		//static _FROM: &'static (Fn(&Prefix, usize)(*Prefix, *string)) = &from;
		//static _TO_IP_STR: &'static (Fn(&Vec<u16>)String) = &Prefix128::to_ip_str;
		ipBits := IpBitsV6()
		bits := ipBits.Bits
		return &PrefixOk{&Prefix{
			num,
			ipBits,
			*New_netmask(num, bits),
			Prefix128From, // vt_to_ip_str: _TO_IP_STR
		}}
	}
	tmp := fmt.Sprintf("Prefix must be in range 0..128, got: %d", num)
	return &PrefixError{&tmp}
}

func Prefix128From(my *Prefix, num uint8) ResultPrefix {
	return Prefix128New(num)
}
