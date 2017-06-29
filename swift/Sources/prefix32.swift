//
//import Prefix from './prefix';
//import IpBits from './ip_bits';

class Prefix32 {
    class func from(_ my: Prefix, _ num: UInt8) -> Prefix? {
        return Prefix32.create(num);
    }

    class func create(_ num: UInt8) -> Prefix? {
        if (0 <= num && num <= 32) {
            let ip_bits = IpBits.v4();
            let bits = ip_bits.bits;
            return Prefix(
                num: num,
                ip_bits: ip_bits,
                net_mask: Prefix.new_netmask(num, bits),
                vt_from: Prefix32.from
            );
        }
        return nil;
    }

}


//export default Prefix32;
