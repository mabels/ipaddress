
require_relative 'crunchy'
require_relative 'prefix32'
require_relative '../ipaddress'
require_relative 'ip_bits'
require_relative 'prefix128'
require_relative 'ipv6'

class IPAddress
  class Ipv4
    def self.parse_data(data)
      ret = 0
      shift = 24
      data.unpack("C*")[0..4].each do |i|
        ret |= i << shift
        shift -= 8
      end

      Ipv4.from_number(Crunchy.from_number(ret), 32)
    end

    def self.from_number(addr, prefix_num)
      prefix = Prefix32.create(prefix_num)
      if (!prefix)
        return nil
      end

      return IPAddress.new({
        ip_bits: IpBits.v4(),
        host_address: addr.clone(),
        prefix: prefix,
        mapped: nil,
        vt_is_private: ->(a) {Ipv4.ipv4_is_private },
        vt_is_loopback: ->(a) {Ipv4.ipv4_is_loopback},
        vt_to_ipv6: ->(a) {Ipv4.to_ipv6}
      })
    end

    def self.create(str)
      tmp = IPAddress.split_at_slash(str)
      ip = tmp[0]
      netmask = tmp[1]
      if (!IPAddress.is_valid_ipv4(ip))
        #puts "-1"
        return nil
      end

      ip_prefix_num = 32
      if (netmask)
        ip_prefix_num = IPAddress.parse_netmask_to_prefix(netmask)
        if (ip_prefix_num.nil?)
          ##puts "-2"
          return nil
        end
      end

      ip_prefix = Prefix32.create(ip_prefix_num)
      if (ip_prefix.nil?)
        #puts "-3"
        return nil
      end

      split_number = IPAddress.split_to_u32(ip)
      if (split_number.nil?)
        #puts "-4"
        return nil
      end

      return IPAddress.new({
        ip_bits: IpBits.v4(),
        host_address: split_number,
        prefix: ip_prefix,
        mapped: nil,
        vt_is_private: -> (a) { Ipv4.ipv4_is_private(a) },
        vt_is_loopback: -> (a) { Ipv4.ipv4_is_loopback(a) },
        vt_to_ipv6: -> (a) { Ipv4.to_ipv6(a) }
      })
    end

    def self.ipv4_is_private(my)
      return [IPAddress.parse("10.0.0.0/8"),
              IPAddress.parse("172.16.0.0/12"),
              IPAddress.parse("192.168.0.0/16")]
        .find{|i|  i.includes(my)} != nil
    end

    def self.ipv4_is_loopback(my)
      return IPAddress.parse("127.0.0.0/8").includes(my)
    end

    def self.to_ipv6(ia)
      return IPAddress.new({
        ip_bits: IpBits.v6(),
        host_address: ia.host_address.clone(),
        prefix: Prefix128.create(ia.prefix.num),
        mapped: nil,
        vt_is_private: ->(a) { Ipv6.ipv6_is_private(a) },
        vt_is_loopback: ->(a) { Ipv6.ipv6_is_loopback(a) },
        vt_to_ipv6: ->(a) { Ipv6.to_ipv6(a) }
      })
    end

    #  Checks whether the ip address belongs to a
    #  RFC 791 CLASS A network, no matter
    #  what the subnet mask is.
    #
    #  Example:
    #
    #    ip = IPAddress("10.0.0.1/24")
    #
    #    ip.a?
    #      # => true
    #
    def self.is_class_a(my)
      # console.log("is_class_a:", my.to_string(), Crunchy.from_string("80000000", 16), my.is_ipv4());
      return my.is_ipv4() && my.host_address.lt(Crunchy.from_string("80000000", 16))
    end

    #  Checks whether the ip address belongs to a
    #  RFC 791 CLASS B network, no matter
    #  what the subnet mask is.
    #
    #  Example:
    #
    #    ip = IPAddress("172.16.10.1/24")
    #
    #    ip.b?
    #      # => true
    #
    def self.is_class_b(my)
      return my.is_ipv4() &&
        Crunchy.from_string("80000000", 16).lte(my.host_address) &&
        my.host_address.lt(Crunchy.from_string("c0000000", 16))
    end

    #  Checks whether the ip address belongs to a
    #  RFC 791 CLASS C network, no matter
    #  what the subnet mask is.
    #
    #  Example:
    #
    #    ip = IPAddress("192.168.1.1/30")
    #
    #    ip.c?
    #      # => true
    #
    def self.is_class_c(my)
      return my.is_ipv4() &&
        Crunchy.from_string("c0000000", 16).lte(my.host_address) &&
        my.host_address.lt(Crunchy.from_string("e0000000", 16))
    end

    #  Creates a new IPv4 address object by parsing the
    #  address in a classful way.
    #
    #  Classful addresses have a fixed netmask based on the
    #  class they belong to:
    #
    #  * Class A, from 0.0.0.0 to 127.255.255.255
    #  * Class B, from 128.0.0.0 to 191.255.255.255
    #  * Class C, D and E, from 192.0.0.0 to 255.255.255.254
    #
    #  Example:
    #
    #    ip = IPAddress::IPv4.parse_classful "10.0.0.1"
    #
    #    ip.netmask
    #      # => "255.0.0.0"
    #    ip.a?
    #      # => true
    #
    #  Note that classes C, D and E will all have a default
    #  prefix of /24 or 255.255.255.0
    #
    def self.parse_classful(ip_si)
      if (!IPAddress.is_valid_ipv4(ip_si))
        return nil
      end

      o_ip = IPAddress.parse(ip_si)
      if (o_ip == nil)
        return o_ip
      end

      ip = o_ip
      if (Ipv4.is_class_a(ip))
        ip.prefix = Prefix32.create(8)
      elsif (Ipv4.is_class_b(ip))
        ip.prefix = Prefix32.create(16)
      elsif (Ipv4.is_class_c(ip))
        ip.prefix = Prefix32.create(24)
      end

      return ip
    end
  end
end
