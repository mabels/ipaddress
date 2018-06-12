package com.adviser.ipaddress.java

class Prefix128 {
    ///
    ///  Creates a new prefix object for 128 bits IPv6 addresses
    ///
    ///    prefix = IPAddressPrefix128.new 64
    ///      ///  64
    ///
    public static def Result<Prefix> create(int num) {
        if(num <= 128) {
            //static _FROM: &'static (Fn(&Prefix, usize) -> Result<Prefix, String>) = &from;
            //static _TO_IP_STR: &'static (Fn(&Vec<u16>) -> String) = &Prefix128::to_ip_str;
            val ip_bits = IpBits.V6;
            val bits = ip_bits.bits;
            return Result.Ok(new Prefix(
                    num,
                    ip_bits,
                    Prefix.new_netmask(num, bits),
                    [ p, _num | return create(_num) ]
            ));
        }
        return Result.Err('''Prefix must be in range 0..128, got: «num»''')
    }

    public def Result<Prefix> from(int num) {
        return create(num);
    }
}
