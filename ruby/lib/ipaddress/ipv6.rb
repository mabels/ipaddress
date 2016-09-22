
require_relative 'prefix'
require_relative 'ip_bits'
require_relative '../ipaddress'
require_relative 'ipv4'
require_relative 'prefix128'
require_relative 'crunchy'


class IPAddress
  class Ipv6
    #  =Name
    #
    #  IPAddress::IPv6 - IP version 6 address manipulation library
    #
    #  =Synopsis
    #
    #     require 'ipaddress'
    #
    #  =Description
    #
    #  Class IPAddress::IPv6 is used to handle IPv6 type addresses.
    #
    #  == IPv6 addresses
    #
    #  IPv6 addresses are 128 bits long, in contrast with IPv4 addresses
    #  which are only 32 bits long. An IPv6 address is generally written as
    #  eight groups of four hexadecimal digits, each group representing 16
    #  bits or two octect. For example, the following is a valid IPv6
    #  address:
    #
    #    2001:0db8:0000:0000:0008:0800:200c:417a
    #
    #  Letters in an IPv6 address are usually written downcase, as per
    #  RFC. You can create a new IPv6 object using uppercase letters, but
    #  they will be converted.
    #
    #  === Compression
    #
    #  Since IPv6 addresses are very long to write, there are some
    #  semplifications and compressions that you can use to shorten them.
    #
    #  * Leading zeroes: all the leading zeroes within a group can be
    #    omitted: "0008" would become "8"
    #
    #  * A string of consecutive zeroes can be replaced by the string
    #    "::". This can be only applied once.
    #
    #  Using compression, the IPv6 address written above can be shorten into
    #  the following, equivalent, address
    #
    #    2001:db8::8:800:200c:417a
    #
    #  This short version is often used in human representation.
    #
    #  === Network Mask
    #
    #  As we used to do with IPv4 addresses, an IPv6 address can be written
    #  using the prefix notation to specify the subnet mask:
    #
    #    2001:db8::8:800:200c:417a/64
    #
    #  The /64 part means that the first 64 bits of the address are
    #  representing the network portion, and the last 64 bits are the host
    #  portion.
    #
    #
    def self.parse_data(data)
      ret = 0
      shift = 120
      data.unpack("C*")[0..16].each do |i|
        ret |= i << shift
        shift -= 8
      end

      Ipv6.from_number(Crunchy.from_number(ret), 128)
    end

    def self.from_str(str, radix, prefix)
      num = Crunchy.from_string(str, radix)
      if (!num)
        return nil
      end

      return Ipv6.from_int(num, prefix)
    end

    def self.enhance_if_mapped(ip)
      # console.log("------A")
      # println!("real mapped {:x} {:x}", &ip.host_address, ip.host_address.clone().shr(32))
      if (ip.is_mapped())
        # console.log("------B")
        return ip
      end

      # console.log("------C", ip)
      ipv6_top_96bit = ip.host_address.shr(32)
      # console.log("------D", ip)
      if (ipv6_top_96bit.eq(Crunchy.from_number(0xffff)))
        # console.log("------E")
        num = ip.host_address.mod(Crunchy.one().shl(32))
        # console.log("------F")
        if (num.eq(Crunchy.zero()))
          return ip
        end

        #println!("ip:{},{:x}", ip.to_string(), num)
        ipv4_bits = IpBits.v4()
        if (ipv4_bits.bits < ip.prefix.host_prefix())
          #println!("enhance_if_mapped-2:{}:{}", ip.to_string(), ip.prefix.host_prefix())
          return nil
        end

        # console.log("------G")
        mapped = Ipv4.from_number(num, ipv4_bits.bits - ip.prefix.host_prefix())
        # console.log("------H")
        if (!mapped)
          # println!("enhance_if_mapped-3")
          return mapped
        end

        # println!("real mapped!!!!!={}", mapped.clone().to_string())
        ip.mapped = mapped
      end

      return ip
    end

    def self.from_number(adr, prefix_num)
      prefix = Prefix128.create(prefix_num)
      if (prefix.nil?)
        return nil
      end

      ret = Ipv6.enhance_if_mapped(IPAddress.new({
        ip_bits: IpBits.v6(),
        host_address: adr.clone(),
        prefix: prefix,
        mapped: nil,
        vt_is_private: ->(a) {Ipv6.ipv6_is_private(a) },
        vt_is_loopback: ->(a) {Ipv6.ipv6_is_loopback(a) },
        vt_to_ipv6: ->(a) {Ipv6.to_ipv6(a) },
      }))
      #console.log("from_int:", adr, prefix, ret)
      return ret
    end

    #  Creates a new IPv6 address object.
    #
    #  An IPv6 address can be expressed in any of the following forms:
    #
    #  * "2001:0db8:0000:0000:0008:0800:200C:417A": IPv6 address with no compression
    #  * "2001:db8:0:0:8:800:200C:417A": IPv6 address with leading zeros compression
    #  * "2001:db8::8:800:200C:417A": IPv6 address with full compression
    #
    #  In all these 3 cases, a new IPv6 address object will be created, using the default
    #  subnet mask /128
    #
    #  You can also specify the subnet mask as with IPv4 addresses:
    #
    #    ip6 = IPAddress "2001:db8::8:800:200c:417a/64"
    #
    def self.create(str)
      # console.log("1>>>>>>>>>", str)
      ip, o_netmask = IPAddress.split_at_slash(str)
      # console.log("2>>>>>>>>>", str)
      # puts "IPAddress.create #{ip}"
      if (IPAddress.is_valid_ipv6(ip))
        # console.log("3>>>>>>>>>", str)
        o_num = IPAddress.split_to_num(ip)
        if (o_num.nil?)
          # console.log("ipv6_create-1", str)
          # puts "IPAddress.split_to_num #{ip}"
          return nil
        end

        # console.log("4>>>>>>>>>", str)
        netmask = 128
        if (!o_netmask.nil?)
          netmask = IPAddress.parse_dec_str(o_netmask)
          if (netmask.nil?)
            # console.log("ipv6_create-2", str)
            return nil
          end
        end

        # console.log("5>>>>>>>>>", str)
        prefix = Prefix128.create(netmask)
        if (prefix.nil?)
          # console.log("ipv6_create-3", str)
          return nil
        end

        #console.log("6>>>>>>>>>", str, prefix.num, o_netmask, netmask)
        return Ipv6.enhance_if_mapped(IPAddress.new({
          ip_bits: IpBits.v6(),
          host_address: o_num.crunchy,
          prefix: prefix,
          mapped: nil,
          vt_is_private: -> (a) { Ipv6.ipv6_is_private(a) },
          vt_is_loopback: -> (a) { Ipv6.ipv6_is_loopback(a) },
          vt_to_ipv6: -> (a) { Ipv6.to_ipv6(a) }
        }))
      else
        # console.log("ipv6_create-4", str)
        return nil
      end
    end #  pub fn initialize

    def self.to_ipv6(ia)
      return ia.clone()
    end

    def self.ipv6_is_loopback(my)
      # console.log("*************", my.host_address, Crunchy.one())
      return my.host_address.eq(Crunchy.one())
    end

    def self.ipv6_is_private(my)
      return IPAddress.parse("fd00::/8").includes(my)
    end
  end
end
