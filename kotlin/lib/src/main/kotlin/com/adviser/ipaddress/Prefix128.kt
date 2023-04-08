package com.adviser.ipaddress.kotlin


class Prefix128 {

    companion object {

        fun create(num: Int): Result<Prefix> {
            if (num <= 128) {
                //static _FROM: &'static (Fn(&Prefix, usize) -> Result<Prefix, String>) = &from;
                //static _TO_IP_STR: &'static (Fn(&Vec<u16>) -> String) = &Prefix128::to_ip_str;
                val ip_bits = IpBits.V6
                val bits = ip_bits.bits
                return Result.Ok(Prefix(
                        num,
                        ip_bits,
                        Prefix.new_netmask(num, bits),
                        { _, _num: Int -> create(_num) }))
            }
            return Result.Err("Prefix must be in range 0..128, got: ${num}")
        }


        ///
        ///  Creates a new prefix object for 128 bits IPv6 addresses
        ///
        ///    prefix = IPAddressPrefix128.new 64
        ///      ///  64
        ///

        fun from(num: Int): Result<Prefix> {
            return create(num)
        }
    }
}
