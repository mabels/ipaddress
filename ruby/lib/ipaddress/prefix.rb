require_relative "ip_bits"
require_relative "crunchy"

class IPAddress
  class Prefix
    include Comparable

    attr_reader :num, :ip_bits, :net_mask, :vt_from

    def initialize(obj)
      @num = obj[:num]
      @ip_bits = obj[:ip_bits]
      @net_mask = obj[:net_mask]
      @vt_from = obj[:vt_from]
    end

    def clone
      Prefix.new({
        num: @num,
        ip_bits: @ip_bits,
        net_mask: @net_mask,
        vt_from: @vt_from
      })
    end

    def eq(other)
      @ip_bits.version == other.ip_bits.version &&
        @num == other.num
    end

    def ne(other)
      !eq(other)
    end

    def <=>(other)
      cmp(other)
    end

    def cmp(oth)
      if @ip_bits.version < oth.ip_bits.version
        -1
      elsif @ip_bits.version > oth.ip_bits.version
        1
      elsif @num < oth.num
        -1
      elsif @num > oth.num
        1
      else
        0
      end
    end

    # #[allow(dead_code)]
    def from(num)
      @vt_from.call(self, num)
    end

    def to_ip_str
      @ip_bits.vt_as_compressed_string.call(@ip_bits, @net_mask)
    end

    def size
      Crunchy.one.shl(@ip_bits.bits - @num)
    end

    def self.new_netmask(prefix, bits)
      mask = Crunchy.zero
      host_prefix = bits - prefix
      prefix.times do |i|
        # console.log(">>>", i, host_prefix, mask)
        mask = mask.add(Crunchy.one.shl(host_prefix + i))
      end

      mask
    end

    def netmask
      @net_mask
    end

    def get_prefix
      @num
    end

    #  The hostmask is the contrary of the subnet mask,
    #  as it shows the bits that can change within the
    #  hosts
    #
    #    prefix = IPAddress::Prefix32.new 24
    #
    #    prefix.hostmask
    #      # => "0.0.0.255"
    #
    def host_mask
      ret = Crunchy.zero
      (@ip_bits.bits - @num).times do
        ret = ret.shl(1).add(Crunchy.one)
      end

      ret
    end

    #
    #  Returns the length of the host portion
    #  of a netmask.
    #
    #    prefix = Prefix128.new 96
    #
    #    prefix.host_prefix
    #      # => 128
    #
    def host_prefix
      @ip_bits.bits - @num
    end

    #
    #  Transforms the prefix into a string of bits
    #  representing the netmask
    #
    #    prefix = IPAddress::Prefix128.new 64
    #
    #    prefix.bits
    #      # => "1111111111111111111111111111111111111111111111111111111111111111"
    #          "0000000000000000000000000000000000000000000000000000000000000000"
    #
    def bits
      netmask.toString(2)
    end

    # #[allow(dead_code)]
    # def net_mask(&self) -> BigUint {
    #     return (self.in_mask.clone() >> (self.host_prefix() as usize)) << (self.host_prefix() as usize)
    # }

    def to_s
      get_prefix.to_s
    end

    # #[allow(dead_code)]
    # def inspect(&self) -> String {
    #     return self.to_s()
    # }
    def to_i
      get_prefix
    end

    def add_prefix(other)
      from(get_prefix + other.get_prefix)
    end

    def add(other)
      from(get_prefix + other)
    end

    def sub_prefix(other)
      sub(other.get_prefix)
    end

    def sub(other)
      if other > get_prefix
        return from(other - get_prefix)
      end

      from(get_prefix - other)
    end
  end
end
