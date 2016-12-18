package prefix

// import "./prefix"
import "../ip_bits"
import "fmt"

///
///  Creates a new prefix object for 128 bits IPv6 addresses
///
///    prefix = IPAddressPrefix128.new 64
///      ///  64
///
func New(num uint8) (*Prefix, *string) {
    if num <= 128 {
        //static _FROM: &'static (Fn(&Prefix, usize)(*Prefix, *string)) = &from;
        //static _TO_IP_STR: &'static (Fn(&Vec<u16>)String) = &Prefix128::to_ip_str;
        ipBits := ip_bits.V6()
        bits := ipBits.Bits;
        return &Prefix {
            num,
            ipBits,
            prefix.New_netmask(num, bits),
            from, // vt_to_ip_str: _TO_IP_STR
        }, nil;
    }
    return nil, fmt.Sprintf("Prefix must be in range 0..128, got: %d", num);
}

func From(my Prefix, num uint) (*Prefix, *string) {
    return New(num);
}
