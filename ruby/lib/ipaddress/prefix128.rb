require_relative 'prefix'
require_relative 'ip_bits'

class IPAddress
  class Prefix128
    # #[derive(Ord,PartialOrd,Eq,PartialEq,Debug,Copy,Clone)]
    # pub struct Prefix128 {
    # }
    #
    # impl Prefix128 {
    #
    #  Creates a new prefix object for 128 bits IPv6 addresses
    #
    #    prefix = IPAddressPrefix128.new 64
    #      # => 64
    #
    ##[allow(unused_comparisons)]
    def self.create(num)
      if (num <= 128)
        #static _FROM: &'static (Fn(&Prefix, usize) -> Result<Prefix, String>) = &from
        #static _TO_IP_STR: &'static (Fn(&Vec<u16>) -> String) = &Prefix128::to_ip_str
        ip_bits = IpBits.v6()
        bits = ip_bits.bits
        return Prefix.new({
          num: num,
          ip_bits: ip_bits,
          net_mask: Prefix.new_netmask(num, bits),
          vt_from: ->(a,b) { Prefix128.from(a,b) }
        })
      end

      return nil
    end

    def self.from(my, num)
      return Prefix128.create(num)
    end
  end
end
