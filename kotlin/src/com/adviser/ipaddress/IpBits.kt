package com.adviser.ipaddress

import java.math.BigInteger

typealias Vt_as_string = (b: IpBits, bi: BigInteger) -> String;


class IpBits(ver: IpVersion, cp: Vt_as_string, ucp: Vt_as_string,
             bits: Int, part_bits: Int, dns_bits: Int, rev_domain: String,
             part_mod: BigInteger, host_ofs: BigInteger) {
    public val version: IpVersion = ver;
    public val bits: Int = bits;
    public val part_bits: Int = part_bits as Int;
    public val dns_bits: Int = dns_bits;
    public val rev_domain: String = rev_domain;
    public val part_mod: BigInteger = part_mod;
    public val host_ofs: BigInteger = host_ofs;

    public val vt_as_compressed_string = cp;
    public val vt_as_uncompressed_string = ucp;

    companion object {
        public val V4 = v4();
        public val V6 = v6();

        public fun reverse(data: IntArray): IntArray {
            var right = data.size - 1;
            for (left in 0..right) {
                // swap the values at the left and right indices
                val temp = data.get(left);
                data.set(left, data.get(right));
                data.set(right, temp);
                --right;
            }
            return data
        }
    }

    public fun parts(bu: BigInteger): IntArray {
        val len = (this.bits / this.part_bits);
        val vec = IntArray(len)
        var my = BigInteger.ZERO.add(bu);
        val part_mod = BigInteger.ONE.shiftLeft(this.part_bits);// - BigUint::one();
        for (i in 0..len) {
            val v = my.mod(part_mod);
            vec.set(i, v.intValueExact());
            my = my.shiftRight(this.part_bits);
        }
        return IpBits.reverse(vec);
    }

    public fun Inspect(): String {
        return "IpBits: ${this.version}";
    }

    public fun as_compressed_string(bu: BigInteger): String {
        return this.vt_as_compressed_string(this, bu);
    }

    public fun as_uncompressed_string(bu: BigInteger): String {
        return this.vt_as_uncompressed_string(this, bu);
    }

    //  Returns the IP address in in-addr.arpa format
    //  for DNS lookups
    //
    //    ip = IPAddress("172.16.100.50/24")
    //
    //    ip.reverse
    //      // => "50.100.16.172.in-addr.arpa"
    //
    // #[allow(dead_code)]
    // pub fn dns_reverse(&self, bu: &BigUint) -> String {
    //     let mut ret = String::new();
    //     let part_mod = BigUint::one() << 4;
    //     let the_dot = String::from(".");
    //     let mut dot = &String::from("");
    //     let mut addr = bu.clone();
    //     for _ in 0..(self.bits / self.dns_bits) {
    //         ret.push_str(dot);
    //         let lower = addr.mod_floor(&part_mod).to_usize().unwrap();
    //         ret.push_str(self.dns_part_format(lower).as_str());
    //         addr = addr >> self.dns_bits;
    //         dot = &the_dot;
    //     }
    //     ret.push_str(self.rev_domain);
    //     return ret;
    // }

    public fun dns_part_format(i: Int): String {
        return when (this.version) {
            IpVersion.V4 -> String.format("%d", i)
            IpVersion.V6 -> String.format("%01x", i)
        }
    }

}


val ipv4_as_compressed: Vt_as_string = { ip_bits: IpBits, host_address: BigInteger ->
    val ret = StringBuilder()
    var sep = "";
    for (part in ip_bits.parts(host_address)) {
        ret.append(sep);
        ret.append(part);
        sep = ".";
    }
    ret.toString();
}


fun v4(): IpBits {
    return IpBits(IpVersion.V4,
            ipv4_as_compressed,
            ipv4_as_compressed,
            32,
            8,
            8,
            "in-addr.arpa",
            BigInteger.ONE.shiftLeft(8),
            BigInteger.ONE
    );
}


val ipv6_as_compressed: Vt_as_string = { ip_bits, host_address ->
    //println!("ipv6_as_compressed:{}", host_address);
    val ret = StringBuilder();
    var the_colon = ":";
    val the_empty = "";
    var colon = the_empty;
    var done = false;
    for (rle in Rle.code(ip_bits.parts(host_address))) {
        var stop = false
        var i = 0;
        while (!stop && i < rle.cnt) {
            if (done || !(rle.part == 0 && rle.max)) {
                ret.append(String.format("%s%x", colon, rle.part));
                colon = the_colon;
            } else if (rle.part == 0 && rle.max) {
                ret.append("::");
                colon = the_empty;
                done = true
                stop = true;
            }
            ++i;
        }
    }
    ret.toString();
}

val ipv6_as_uncompressed: Vt_as_string = { ip_bits, host_address ->
        val ret = StringBuilder()
        var sep = "";
        for (part in ip_bits.parts(host_address)) {
            ret.append(sep);
            ret.append(String.format("%04x", part));
            sep = ":";
        }
        ret.toString();
}

fun v6(): IpBits {
    return IpBits(IpVersion.V6,
            ipv6_as_compressed,
            ipv6_as_uncompressed,
            128,
            16,
            4,
            "ip6.arpa",
            BigInteger.ONE.shiftLeft(16),
            BigInteger.ZERO)
}



