require_relative "crunchy"

require_relative "rle"

require_relative "ip_version"

class IPAddress
  class IpBits
    attr_reader :version, :vt_as_compressed_string,
      :vt_as_uncompressed_string, :bits, :part_bits,
      :dns_bits, :rev_domain, :part_mod, :host_ofs

    def initialize(version,
      vt_as_compressed_string, vt_as_uncompressed_string,
      bits, part_bits, dns_bits, rev_domain, part_mod, host_ofs)
      @version = version
      @vt_as_compressed_string = vt_as_compressed_string
      @vt_as_uncompressed_string = vt_as_uncompressed_string
      @bits = bits
      @part_bits = part_bits
      @dns_bits = dns_bits
      @rev_domain = rev_domain
      @part_mod = part_mod
      @host_ofs = host_ofs
    end

    def clone
      self
    end

    def parts(bu)
      vec = []
      my = bu.clone
      # part_mod = Crunchy.one().shl(self.part_bits)
      i = 0
      while i < (bits / part_bits)
        vec.push(my.mod(@part_mod).num)
        my = my.shr(part_bits)
        i += 1
      end

      vec.reverse
    end

    def as_compressed_string(bu)
      vt_as_compressed_string.call(self, bu)
    end

    def as_uncompressed_string(bu)
      vt_as_uncompressed_string.call(self, bu)
    end

    def dns_part_format(i)
      case version
      when IpVersion::V4
        "#{i}"
      when IpVersion::V6
        "#{i.to_s(16)}"
      end
    end

    def self.v4
      @@V4 ||= IpBits.new(
        IpVersion::V4,
        ->(a, b) { IpBits.ipv4_as_compressed(a, b) },
        ->(a, b) { IpBits.ipv4_as_compressed(a, b) },
        32,
        8,
        8,
        "in-addr.arpa",
        Crunchy.from_number(1 << 8),
        Crunchy.one
      )
    end

    def self.v6
      @@V6 ||= IpBits.new(
        IpVersion::V6,
        ->(a, b) { IpBits.ipv6_as_compressed(a, b) },
        ->(a, b) { IpBits.ipv6_as_uncompressed(a, b) },
        128,
        16,
        4,
        "ip6.arpa",
        Crunchy.from_number(1 << 16),
        Crunchy.zero
      )
    end

    def self.ipv4_as_compressed(ip_bits, host_address)
      ret = ""
      sep = ""
      ip_bits.parts(host_address).each do |part|
        ret += sep
        ret += "#{part}"
        sep = "."
      end

      ret
    end

    def self.ipv6_as_compressed(ip_bits, host_address)
      ret = ""
      colon = ""
      done = false
      rles = Rle.code(ip_bits.parts(host_address))
      rles.each_with_index do |rle, idx|
        _ = 0
        while _ < rle.cnt
          if done || !(rle.part == 0 && rle.max) || (rles.length == idx + 1 && rle.cnt == 1 && rle.part == 0 && rle.max)
            # puts "-------#{rle.part.class.name}"
            ret += "#{colon}#{rle.part.to_s(16)}"
            colon = ":"
          elsif rle.part == 0 && rle.max
            ret += "::"
            colon = ""
            done = true
            break
          end

          _ += 1
        end
      end

      ret
    end

    def self.ipv6_as_uncompressed(ip_bits, host_address)
      ret = ""
      sep = ""
      ip_bits.parts(host_address).each do |part|
        ret += sep
        ret += (0x10000 + part).to_s(16)[1..-1]
        sep = ":"
      end

      ret
    end
  end
end
