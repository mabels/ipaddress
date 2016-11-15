
import "./prefix"
import "../ip_bits"
import "fmt"


func From(my Prefix, num uint) (*Prefix, *string) {
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
func New(num uint) (*Prefix, *string) {
    if num <= 32 {
        ipBits := ip_bits.V4();
        bits := ipBits.bits;
        return &Prefix {
            num,
            ip_bits,
            Prefix::New_netmask(num, bits),
            from,
            //vt_to_ip_str: _TO_IP_STR,
        }), nil;
    }
    return nil, fmt.Sprintf("Prefix must be in range 0..32, got: %d", num);
}
