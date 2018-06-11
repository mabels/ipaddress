package com.adviser.ipaddress


class Prefix32 {

    companion object {
        public fun from(my: Prefix, num: Int): Result<Prefix> {
            return create(num);
        }

        ///  Gives the prefix in IPv4 dotted decimal format,
        ///  i.e. the canonical netmask we're all used to
        ///
        ///    prefix = IPAddress::prefix::Prefix32.new 24
        ///
        ///    prefix.to_ip
        ///      ///  "255.255.255.0"
        ///
        public fun create(num: Int): Result<Prefix> {
            if (0 <= num && num <= 32) {
                val ip_bits = IpBits.V4;
                val bits = ip_bits.bits;
                return Result.Ok(Prefix(
                        num,
                        ip_bits,
                        Prefix.new_netmask(num, bits),
                        { p: Prefix, _num: Int -> create(_num) }
                ));
            }
            return Result.Err("Prefix must be in range 0..32, got: ${num}");
        }
    }
}

