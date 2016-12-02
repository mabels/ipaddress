
require_relative 'crunchy'
require_relative 'ip_bits'
require_relative '../ipaddress'

class IPAddress

  class Ipv6Mapped
    #  Ac
    #  It is usually identified as a IPv4 mapped IPv6 address, a particular
    #  IPv6 address which aids the transition from IPv4 to IPv6. The
    #  structure of the address is
    #
    #    ::ffff:w.y.x.z
    #
    #  where w.x.y.z is a normal IPv4 address. For example, the following is
    #  a mapped IPv6 address:
    #
    #    ::ffff:192.168.100.1
    #
    #  IPAddress is very powerful in handling mapped IPv6 addresses, as the
    #  IPv4 portion is stored internally as a normal IPv4 object. Let's have
    #  a look at some examples. To create a new mapped address, just use the
    #  class builder itself
    #
    #    ip6 = IPAddress::IPv6::Mapped.new "::ffff:172.16.10.1/128"
    #
    #  or just use the wrapper method
    #
    #    ip6 = IPAddress "::ffff:172.16.10.1/128"
    #
    #  Let's check it's really a mapped address:
    #
    #    ip6.mapped?
    #      # => true
    #
    #    ip6.to_string
    #      # => "::FFFF:172.16.10.1/128"
    #
    #  Now with the +ipv4+ attribute, we can easily access the IPv4 portion
    #  of the mapped IPv6 address:
    #
    #    ip6.ipv4.address
    #      # => "172.16.10.1"
    #
    #  Internally, the IPv4 address is stored as two 16 bits
    #  groups. Therefore all the usual methods for an IPv6 address are
    #  working perfectly fine:
    #
    #    ip6.to_hex
    #      # => "00000000000000000000ffffac100a01"
    #
    #    ip6.address
    #      # => "0000:0000:0000:0000:0000:ffff:ac10:0a01"
    #
    #  A mapped IPv6 can also be created just by specify the address in the
    #  following format:
    #
    #    ip6 = IPAddress "::172.16.10.1"
    #
    #  That is, two colons and the IPv4 address. However, as by RFC, the ffff
    #  group will be automatically added at the beginning
    #
    #    ip6.to_string
    #      => "::ffff:172.16.10.1/128"
    #
    #  making it a mapped IPv6 compatible address.
    #
    #
    #  Creates a new IPv6 IPv4-mapped address
    #
    #    ip6 = IPAddress::IPv6::Mapped.new "::ffff:172.16.10.1/128"
    #
    #    ipv6.ipv4.class
    #      # => IPAddress::IPv4
    #
    #  An IPv6 IPv4-mapped address can also be created using the
    #  IPv6 only format of the address:
    #
    #    ip6 = IPAddress::IPv6::Mapped.new "::0d01:4403"
    #
    #    ip6.to_string
    #      # => "::ffff:13.1.68.3"
    #
    def self.create(str)
      # console.log("mapped-1")
      i = IPAddress.split_at_slash(str)
      ip = i[0]
      o_netmask = i[1]
      split_colon = ip.split(":")
      if (split_colon.length <= 1)
        # console.log("mapped-2")
        return nil
      end

      # if split_colon.get(0).unwrap().len() > 0 {
      #     # println!("---1a")
      #     return Err(format!("not mapped format-2: {}", &str))
      # }
      # mapped: Option<IPAddress> = None
      netmask = ""
      if (o_netmask != nil)
        netmask = "/#{o_netmask}"
      end

      ipv4_str = split_colon[split_colon.length - 1]
      if (IPAddress.is_valid_ipv4(ipv4_str))
        ipv4 = IPAddress.parse("#{ipv4_str}#{netmask}")
        if (ipv4.nil?)
          # console.log("mapped-3")
          return ipv4
        end

        #mapped = Some(ipv4.unwrap())
        addr = ipv4
        ipv6_bits = IpBits.v6()
        part_mod = ipv6_bits.part_mod #Crunchy.from_number(ipv6_bits.part_mod)
        up_addr = addr.host_address.clone()
        down_addr = addr.host_address.clone()

        rebuild_ipv6 = ""
        colon = ""
        (split_colon.length - 1).times do |i|
          rebuild_ipv6 += colon
          rebuild_ipv6 += split_colon[i]
          colon = ":"
        end

        rebuild_ipv6 += colon
        high_part = up_addr.shr(IpBits.v6().part_bits).mod(part_mod).toString(16)
        low_part = down_addr.mod(part_mod).toString(16)
        bits = ipv6_bits.bits - addr.prefix.host_prefix()
        rebuild_ipv4 = "#{high_part}:#{low_part}/#{bits}"
        rebuild_ipv6 += rebuild_ipv4

        # console.log("-----A", rebuild_ipv6, part_mod)
        r_ipv6 = IPAddress.parse(rebuild_ipv6)
        if (r_ipv6.nil?)
          # println!("---3|{}", &rebuild_ipv6)
          # console.log("mapped-4")
          return r_ipv6
        end

        if (r_ipv6.is_mapped())
          # console.log("mapped-5")
          return r_ipv6
        end

        ipv6 = r_ipv6
        p96bit = ipv6.host_address.shr(32)
        if (!p96bit.eq(Crunchy.zero()))
          # println!("---4|{}", &rebuild_ipv6)
          #console.log("mapped-6",ipv6.host_address, p96bit, Crunchy.zero())
          return nil
        end

        r_ipv6 = IPAddress.parse("::ffff:#{rebuild_ipv4}")
        if (r_ipv6.nil?)
          # println!("---3|{}", &rebuild_ipv6)
          #console.log("mapped-7")
          return nil
        end

        # console.log("mapped-8")
        return r_ipv6
      end

      # console.log("mapped-9")
      return nil
    end
  end
end
