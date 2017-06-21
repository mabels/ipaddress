package com.adviser.ipaddress

import java.math.BigInteger

// #[derive(Debug, Clone)]
class IpBits {
    public final IpVersion version;
    public final int bits;
    public final int part_bits;
    public final int dns_bits;
    public final String rev_domain;
    public final BigInteger part_mod;
    public final BigInteger host_ofs;
    interface Vt_as_string {
        def String run(IpBits b, BigInteger bi)
    }
    public final Vt_as_string vt_as_compressed_string;
    public final Vt_as_string vt_as_uncompressed_string;

    new(IpVersion ver, Vt_as_string cp, Vt_as_string ucp,
    int bits, int part_bits, int dns_bits, String rev_domain,
    BigInteger part_mod, BigInteger host_ofs) {
        this.version = ver
        this.vt_as_compressed_string = cp
        this.vt_as_uncompressed_string = ucp
        this.bits = bits
        this.part_bits = part_bits
        this.dns_bits = dns_bits
        this.rev_domain = rev_domain
        this.part_mod = part_mod
        this.host_ofs = host_ofs
    }

    public static def IpBits v4() {
        val ipv4_as_compressed = [IpBits ip_bits, BigInteger host_address |
            val ret = new StringBuffer()
            var sep = "";
            for(part : ip_bits.parts(host_address)) {
                ret.append(sep);
                ret.append(part);
                sep = ".";
            }
            return ret.toString();
        ]
        return new IpBits(IpVersion.V4,
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
    public static final IpBits V4 = v4();

    public static def IpBits v6() {
        val ipv6_as_compressed = [IpBits ip_bits, BigInteger host_address |
            //println!("ipv6_as_compressed:{}", host_address);
            val ret = new StringBuffer();
            var the_colon = ":";
            val the_empty = "";
            var colon = the_empty;
            var done = false;
            for(rle : Rle.code(ip_bits.parts(host_address))) {
                var break = false
                for(var _ = 0; !break && _ < rle.cnt; _++) {
                    if(done || !(rle.part == 0 && rle.max)) {
                        ret.append(String.format("%s%x", colon, rle.part));
                        colon = the_colon;
                    } else if(rle.part == 0 && rle.max) {
                        ret.append("::");
                        colon = the_empty;
                        done = true
                        break = true
                    }
                }
            }
            return ret.toString();
        ];
        val ipv6_as_uncompressed = [IpBits ip_bits, BigInteger host_address |
            val ret = new StringBuffer()
            var sep = "";
            for(part : ip_bits.parts(host_address)) {
                ret.append(sep);
                ret.append(String.format("%04x", part));
                sep = ":";
            }
            return ret.toString();
        ]
        return new IpBits(IpVersion.V6,
        ipv6_as_compressed,
        ipv6_as_uncompressed,
        128,
        16,
        4,
        "ip6.arpa",
        BigInteger.ONE.shiftLeft(16),
        BigInteger.ZERO)
    }
    public static final IpBits V6 = v6();

    public def String Inspect() {
        return '''IpBits: «this.version»'''
    }

    public static def int[] reverse(int[] data) {
        var right = data.length - 1;
        for (var left = 0; left < right; left++, right--) {
            // swap the values at the left and right indices
            val temp = data.get(left);
            data.set(left,  data.get(right));
            data.set(right, temp);
        }
        return data
    }

    public def int[] parts(BigInteger bu) {
        val len = (this.bits / this.part_bits);
        var int[] vec = newIntArrayOfSize(len)
        var my = BigInteger.ZERO.add(bu);
        val part_mod = BigInteger.ONE.shiftLeft(this.part_bits);// - BigUint::one();
        for(var i = 0; i < len ; i++) {
            val v = my.mod(part_mod).intValue();
            vec.set(i, v);
            my = my.shiftRight(this.part_bits);
        }
        return IpBits.reverse(vec);
    }

    public def String as_compressed_string(BigInteger bu) {
        return this.vt_as_compressed_string.run(this, bu);
    }
    public def String as_uncompressed_string(BigInteger bu) {
        return this.vt_as_uncompressed_string.run(this, bu);
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

    public def String dns_part_format(int i) {
        switch this.version {
            case IpVersion.V4 : return String.format("%d", i)
            case IpVersion.V6 : return String.format("%01x", i)
        }
    }

}


