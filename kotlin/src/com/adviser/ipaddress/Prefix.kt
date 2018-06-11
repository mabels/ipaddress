package com.adviser.ipaddress

import java.math.BigInteger

/*
interface VtFrom {
    fun <Prefix> run(p: Prefix, n: Byte): Result<Prefix>;
}
*/

public class Prefix(num: Int, ip_bits: IpBits, netmask: BigInteger,
                    vtfrom: (p: Prefix, n: Int) -> Result<Prefix>) {

    companion object {
        public fun new_netmask(prefix: Int, bits: Int): BigInteger {
            var mask = BigInteger.ZERO;
            val host_prefix = bits - prefix;
            for (i in 0..prefix) {
                mask = mask.add((BigInteger.ONE.shiftLeft(host_prefix + i)));
            }
            return mask
        }
    }


    public val num = num;
    public val ip_bits = ip_bits;
    public val net_mask = netmask;
    public val vt_from = vtfrom;

    public fun clone(): Prefix {
        return Prefix(this.num, this.ip_bits, this.net_mask, this.vt_from);
    }

    public fun equal(other: Prefix): Boolean {
        return this.ip_bits.version == other.ip_bits.version &&
                this.num == other.num;
    }

    public fun inspect(): String {
        return "Prefix: ${num}";
    }

    public fun compare(oth: Prefix): Int {
        if (this.ip_bits.version < oth.ip_bits.version) {
            return -1;
        } else if (this.ip_bits.version > oth.ip_bits.version) {
            return 1;
        } else {
            if (this.num < oth.num) {
                return -1;
            } else if (this.num > oth.num) {
                return 1;
            } else {
                return 0;
            }
        }
    }

    public fun from(num: Int): Result<Prefix> {
        return this.vt_from(this, num);
    }

    public fun to_ip_str(): String {
        return this.ip_bits.vt_as_compressed_string(this.ip_bits, this.netmask());
    }

    public fun size(): BigInteger {
        return BigInteger.ONE.shiftLeft(this.ip_bits.bits - this.num)
    }



    public fun netmask(): BigInteger {
        return BigInteger.ZERO.add(this.net_mask)
    }

    public fun get_prefix(): Int {
        return this.num
    }

    ///  The hostmask is the contrary of the subnet mask,
    ///  as it shows the bits that can change within the
    ///  hosts
    ///
    ///    prefix = IPAddress::Prefix32.new 24
    ///
    ///    prefix.hostmask
    ///      ///  "0.0.0.255"
    ///
    public fun host_mask(): BigInteger {
        var ret = BigInteger.ZERO;
        for (i in 0..this.ip_bits.bits - this.num) {
            ret = ret.shiftLeft(1).add(BigInteger.ONE);
        }
        return ret;
    }

    ///
    ///  Returns the length of the host portion
    ///  of a netmask.
    ///
    ///    prefix = Prefix128.new 96
    ///
    ///    prefix.host_prefix
    ///      ///  128
    ///
    public fun host_prefix(): Int {
        return this.ip_bits.bits - this.num;
    }

    ///
    ///  Transforms the prefix into a string of bits
    ///  representing the netmask
    ///
    ///    prefix = IPAddress::Prefix128.new 64
    ///
    ///    prefix.bits
    ///      ///  "1111111111111111111111111111111111111111111111111111111111111111"
    ///          "0000000000000000000000000000000000000000000000000000000000000000"
    ///
    public fun bits(): String {
        return this.netmask().toString(2)
    }

    public fun to_s(): String {
        return "${this.get_prefix()}"
    }

    public fun to_i(): Int {
        return this.get_prefix();
    }

    public fun add_prefix(other: Prefix): Result<Prefix> {
        return this.from(this.get_prefix() + other.get_prefix())
    }

    public fun add(other: Int): Result<Prefix> {
        return this.from(this.get_prefix() + other)
    }

    public fun sub_prefix(other: Prefix): Result<Prefix> {
        return this.sub(other.get_prefix());
    }

    public fun sub(other: Int): Result<Prefix> {
        if (other > this.get_prefix()) {
            return this.from(other - this.get_prefix());
        }
        return this.from(this.get_prefix() - other);
    }

}
