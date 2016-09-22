
require_relative 'prefix'
require_relative 'ip_bits'

class IPAddress
  class Prefix32
    def self.from(my, num)
      return Prefix32.create(num)
    end

    def self.create(num)
      if (0 <= num && num <= 32)
        #static _FROM: &'static (Fn(&::prefix::Prefix, usize) -> Result<::prefix::Prefix, String>) =
        # &from
        #static _TO_IP_STR: &'static (Fn(&Vec<u16>) -> String) = &to_ip_str
        ip_bits = IpBits.v4()
        bits = ip_bits.bits
        return Prefix.new({
          num: num,
          ip_bits: ip_bits,
          net_mask: Prefix.new_netmask(num, bits),
          vt_from: -> (a,b) { Prefix32.from(a,b) }
          #vt_to_ip_str: _TO_IP_STR,
        })
      end

      return nil
    end
  end
end
