package com.adviser.ipaddress.java

import java.math.BigInteger

class Prefix {
    public final int num;
    public final IpBits ip_bits;
    public final BigInteger net_mask;

    interface VtFrom {
        def Result<Prefix> run(Prefix p, int n);
    }
    public final VtFrom vt_from;

    new(int num, IpBits ip_bits, BigInteger netmask, VtFrom vtfrom) {
       this.num = num
       this.ip_bits = ip_bits
       this.net_mask = netmask
       this.vt_from = vtfrom
    }


    override Prefix clone() {
        return new Prefix(num, ip_bits, net_mask, vt_from);
    }

    def boolean equal(Prefix other) {
        return this.ip_bits.version == other.ip_bits.version &&
          this.num == other.num;
    }

    def String inspect() {
        return '''Prefix: «num»'''
    }

    def int compare(Prefix oth) {
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
    
    def Result<Prefix> from(int num) {
        return this.vt_from.run(this, num)
    }

    def String to_ip_str() {
        return this.ip_bits.vt_as_compressed_string.run(this.ip_bits, this.netmask());
    }

    def BigInteger size() {
      return BigInteger.ONE.shiftLeft(this.ip_bits.bits-this.num)
    }

    static def BigInteger new_netmask(int prefix, int bits) {
        var mask = BigInteger.ZERO;
        val host_prefix = bits-prefix;
        for (var i = 0 ; i < prefix ; i++) {
            mask = mask.add((BigInteger.ONE.shiftLeft(host_prefix+i)));
        }
        return mask
    }

    def BigInteger netmask() {
        return BigInteger.ZERO.add(this.net_mask)
    }

    def int get_prefix() {
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
    def BigInteger host_mask() {
        var ret = BigInteger.ZERO;
        for (var i = 0; i  < this.ip_bits.bits-this.num; i++) {
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
    def int host_prefix() {
        return (this.ip_bits.bits) -this.num;
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
    def String bits() {
        return this.netmask().toString(2)
    }
    def String to_s() {
        return '''«this.get_prefix()»'''
    }

    def int to_i() {
        return this.get_prefix();
    }

    def Result<Prefix> add_prefix(Prefix other) {
        return this.from(this.get_prefix() + other.get_prefix())
    }
    def Result<Prefix> add(int other)  {
        return this.from(this.get_prefix() + other)
    }
    def Result<Prefix> sub_prefix(Prefix other) {
        return this.sub(other.get_prefix());
    }
    def Result<Prefix> sub(int other) {
        if (other > this.get_prefix()) {
            return this.from(other-this.get_prefix());
        }
        return this.from(this.get_prefix() - other);
    }

}
