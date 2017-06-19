package prefix32

// import "./prefix"
import "../../ip_bits"
import "../../prefix"
import "fmt"

func From(my *prefix.Prefix, num uint8) prefix.ResultPrefix {
    return New(num);
}
///  Gives the prefix in IPv4 dotted decimal format,
///  i.e. the canonical netmask we're all used to
///
///    prefix = IPAddress::prefix::Prefix32.new 24
///
///    prefix.to_ip
///      ///  "255.255.255.0"
///
func New(num uint8) prefix.ResultPrefix {
    if num <= 32 {
        ipBits := ip_bits.V4();
        bits := ipBits.Bits;
        tmp := prefix.New_netmask(uint8(num), bits)
        return &prefix.Ok{&prefix.Prefix {
            uint8(num),
            ipBits,
            *tmp,
            From,
            //vt_to_ip_str: _TO_IP_STR,
        }};
    }
    tmp := fmt.Sprintf("Prefix must be in range 0..32, got: %d", num)
    return &prefix.Error{&tmp}
}
