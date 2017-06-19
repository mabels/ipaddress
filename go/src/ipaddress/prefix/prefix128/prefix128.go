package prefix128

// import "./prefix"
import "../../ip_bits"
import "fmt"
import "../../prefix"

///
///  Creates a new prefix object for 128 bits IPv6 addresses
///
///    prefix = IPAddressPrefix128.new 64
///      ///  64
///
func New(num uint8) prefix.ResultPrefix {
    if num <= 128 {
        //static _FROM: &'static (Fn(&Prefix, usize)(*Prefix, *string)) = &from;
        //static _TO_IP_STR: &'static (Fn(&Vec<u16>)String) = &Prefix128::to_ip_str;
        ipBits := ip_bits.V6()
        bits := ipBits.Bits;
        return &prefix.Ok{&prefix.Prefix {
            num,
            ipBits,
            *prefix.New_netmask(num, bits),
            From, // vt_to_ip_str: _TO_IP_STR
        }};
    }
    tmp :=  fmt.Sprintf("Prefix must be in range 0..128, got: %d", num);
    return &prefix.Error{&tmp}
}

func From(my *prefix.Prefix, num uint8) prefix.ResultPrefix {
    return New(num);
}
