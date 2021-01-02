package com.adviser.ipaddress.kotlin

import java.math.BigInteger

/*
interface VtFrom {
    fun <Prefix> run(p: Prefix, n: Byte): Result<Prefix>
}
*/

public class Prefix(val num: Int,
                    val ip_bits: IpBits,
                    val net_mask: BigInteger,
                    val vt_from: (p: Prefix, n: Int) -> Result<Prefix>) {

    companion object {
        fun new_netmask(prefix: Int, bits: Int): BigInteger {
            var mask = BigInteger.ZERO
            val host_prefix = bits - prefix
            for (i in 0 until prefix) {
                mask = mask.add((BigInteger.ONE.shiftLeft(host_prefix + i)))
            }
            return mask
        }
    }

    fun clone(): Prefix {
        return Prefix(this.num, this.ip_bits, this.net_mask, this.vt_from)
    }

    fun equal(other: Prefix): Boolean {
        return this.ip_bits.version == other.ip_bits.version &&
                this.num == other.num
    }

    fun inspect(): String {
        return "Prefix: ${num}"
    }

    fun compare(oth: Prefix): Int {
        if (this.ip_bits.version < oth.ip_bits.version) {
            return -1
        } else if (this.ip_bits.version > oth.ip_bits.version) {
            return 1
        } else {
            if (this.num < oth.num) {
                return -1
            } else if (this.num > oth.num) {
                return 1
            } else {
                return 0
            }
        }
    }

    fun from(num: Int): Result<Prefix> {
        return this.vt_from(this, num)
    }

    fun to_ip_str(): String {
        return this.ip_bits.vt_as_compressed_string(this.ip_bits, this.netmask())
    }

    fun size(): BigInteger {
        return BigInteger.ONE.shiftLeft(this.ip_bits.bits - this.num)
    }


    fun netmask(): BigInteger {
        return BigInteger.ZERO.add(this.net_mask)
    }

    fun get_prefix(): Int {
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
    fun host_mask(): BigInteger {
        var ret = BigInteger.ZERO
        for (i in 0 until this.ip_bits.bits - this.num) {
            ret = ret.shiftLeft(1).add(BigInteger.ONE)
        }
        return ret
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
    fun host_prefix(): Int {
        return this.ip_bits.bits - this.num
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
    fun bits(): String {
        return this.netmask().toString(2)
    }

    fun to_s(): String {
        return "${this.get_prefix()}"
    }

    fun to_i(): Int {
        return this.get_prefix()
    }

    fun add_prefix(other: Prefix): Result<Prefix> {
        return this.from(this.get_prefix() + other.get_prefix())
    }

    fun add(other: Int): Result<Prefix> {
        return this.from(this.get_prefix() + other)
    }

    fun sub_prefix(other: Prefix): Result<Prefix> {
        return this.sub(other.get_prefix())
    }

    fun sub(other: Int): Result<Prefix> {
        if (other > this.get_prefix()) {
            return this.from(other - this.get_prefix())
        }
        return this.from(this.get_prefix() - other)
    }

}
