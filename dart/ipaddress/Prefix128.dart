
import 'IpBits.dart';
import 'Prefix.dart';
import 'Result.dart';

class Prefix128 {
    ///
    ///  Creates a prefix object for 128 bits IPv6 addresses
    ///
    ///    prefix = IPAddressPrefix128.64
    ///      ///  64
    ///
     static Result<Prefix> create(int num) {
        if(num <= 128) {
            //static _FROM: &'static (Fn(&Prefix, usize) -> Result<Prefix, String>) = &from;
            //static _TO_IP_STR: &'static (Fn(&Vec<u16>) -> String) = &Prefix128::to_ip_str;
            final ip_bits = IpBits.V6;
            final bits = ip_bits.bits;
            return Result.Ok(Prefix(
                    num,
                    ip_bits,
                    Prefix.new_netmask(num, bits),
                    (p, _num) => create(_num)
            ));
        }
        return Result.Err("Prefix must be in range 0..128, got: ${num}");
    }

     Result<Prefix> from(int num) {
        return create(num);
    }
}
