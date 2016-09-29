
require_relative 'ipaddress/prefix'
require_relative 'ipaddress/ip_bits'
require_relative 'ipaddress/ip_version'
require_relative 'ipaddress/ipv4'
require_relative 'ipaddress/ipv6'
require_relative 'ipaddress/ipv6_mapped'
require_relative 'ipaddress/ipv6_unspec'
require_relative 'ipaddress/ipv6_loopback'

require_relative 'ipaddress/crunchy'
require_relative 'ipaddress/result_crunchy_parts'


class IPAddress

  include Comparable

  attr_reader :ip_bits, :host_address, :prefix
  attr_reader :mapped, :vt_is_private, :vt_is_loopback, :vt_to_ipv6
  attr_writer :prefix, :mapped, :host_address

  def initialize(obj)
    @ip_bits = obj[:ip_bits]
    @host_address = obj[:host_address]
    @prefix = obj[:prefix]
    @mapped = obj[:mapped]
    @vt_is_private = obj[:vt_is_private]
    @vt_is_loopback = obj[:vt_is_loopback]
    @vt_to_ipv6 = obj[:vt_to_ipv6]
  end

  def clone()
    mapped = nil
    if (@mapped)
      mapped = @mapped.clone()
    end

    return IPAddress.new({
      ip_bits: @ip_bits.clone(),
      host_address: @host_address.clone(),
      prefix: @prefix.clone(),
      mapped: mapped,
      vt_is_private: @vt_is_private,
      vt_is_loopback: @vt_is_loopback,
      vt_to_ipv6: @vt_to_ipv6
    })
  end

  def lt(oth)
    return cmp(oth) == -1
  end

  def lte(oth)
    return cmp(oth) <= 0
  end

  def gt(oth)
    return cmp(oth) == 1
  end

  def gte(oth)
    return cmp(oth) >= 0
  end

  def <=>(oth)
    cmp(oth)
  end

  def cmp(oth)
    if (@ip_bits.version != oth.ip_bits.version)
      if (@ip_bits.version == IpVersion::V6)
        return 1
      end

      return -1
    end

    hostCmp = @host_address.compare(oth.host_address)
    if (hostCmp != 0)
      return hostCmp
    end

    return @prefix.cmp(oth.prefix)
  end

  def eq(other)
    return @ip_bits.version == other.ip_bits.version &&
      @prefix.eq(other.prefix) &&
      @host_address.eq(other.host_address)
  end

  def ne(other)
    return !eq(other)
  end

  #  Parse the argument string to create a new
  #  IPv4, IPv6 or Mapped IP object
  #
  #    ip  = IPAddress.parse "172.16.10.1/24"
  #    ip6 = IPAddress.parse "2001:db8.8:800:200c:417a/64"
  #    ip_mapped = IPAddress.parse ".ffff:172.16.10.1/128"
  #
  #  All the object created will be instances of the
  #  correct class:
  #
  #   ip.class
  #     # => IPAddress.IPv4
  #   ip6.class
  #     # => IPAddress.IPv6
  #   ip_mapped.class
  #     # => IPAddress.IPv6.Mapped
  #
  RE_MAPPED = /:.+\./
  RE_IPV4 = /\./
  RE_IPV6 = /:/
  def self.parse(str)
    if (RE_MAPPED.match(str))
      #  console.log("mapped:", str)
      return Ipv6Mapped.create(str)
    else
      if (RE_IPV4.match(str))
        # puts("ipv4:", str)
        return Ipv4.create(str)
      elsif (RE_IPV6.match(str))
        #  console.log("ipv6:", str)
        return Ipv6.create(str)
      end
    end

    return nil
  end

  def self.split_at_slash(str)
    slash = str.strip().split("/")
    addr = ""
    if (slash[0])
      addr += slash[0].strip()
    end

    if (slash[1])
      return [addr, slash[1].strip()]
    else
      return [addr, nil]
    end
  end

  def from(addr, prefix)
    mapped = nil
    if (@mapped)
      mapped = @mapped.clone()
    end

    return IPAddress.new({
      ip_bits: @ip_bits,
      host_address: addr.clone(),
      prefix: prefix.clone(),
      mapped: mapped,
      vt_is_private: @vt_is_private,
      vt_is_loopback: @vt_is_loopback,
      vt_to_ipv6: @vt_to_ipv6
    })
  end

  #  True if the object is an IPv4 address
  #
  #    ip = IPAddress("192.168.10.100/24")
  #
  #    ip.ipv4?
  #      # -> true
  #
  def ipv4?
    is_ipv4
  end

  def is_ipv4()
    return @ip_bits.version == IpVersion::V4
  end

  #  True if the object is an IPv6 address
  #
  #    ip = IPAddress("192.168.10.100/24")
  #
  #    ip.ipv6?
  #      # -> false
  #
  def ipv6?
    is_ipv6
  end

  def is_ipv6()
    return @ip_bits.version == IpVersion::V6
  end

  #  Checks if the given string is a valid IP address,
  #  either IPv4 or IPv6
  #
  #  Example:
  #
  #    IPAddress.valid? "2002.1"
  #      # => true
  #
  #    IPAddress.valid? "10.0.0.256"
  #      # => false
  #
  def self.is_valid(addr)
    return IPAddress.is_valid_ipv4(addr) || IPAddress.is_valid_ipv6(addr)
  end

  def self.valid?(addr)
    is_valid(addr)
  end

  RE_DIGIT = /^\d+$/
  def self.parse_dec_str(str)
    if (!RE_DIGIT.match(str))
      # puts "=1 #{str}"
      #  console.log("parse_dec_str:-1:", str)
      return nil
    end

    part = str.to_i
    return part
  end

  RE_HEX_DIGIT = /^[0-9a-fA-F]+$/
  def self.parse_hex_str(str)
    if (!RE_HEX_DIGIT.match(str))
      return nil
    end

    part = str.to_i(16)
    return part
  end

  #  Checks if the given string is a valid IPv4 address
  #
  #  Example:
  #
  #    IPAddress.valid_ipv4? "2002.1"
  #      # => false
  #
  #    IPAddress.valid_ipv4? "172.16.10.1"
  #      # => true
  #
  def self.parse_ipv4_part(i)
    part = IPAddress.parse_dec_str(i)
    # console.log("i=", i, part)
    if (part === nil || part >= 256)
      return nil
    end

    return part
  end

  def self.split_to_u32(addr)
    ip = Crunchy.zero()
    shift = 24
    split_addr = addr.split(".")
    if (split_addr.length > 4)
      # puts "+1"
      return nil
    end

    split_addr_len = split_addr.length
    if (split_addr_len < 4)
      part = IPAddress.parse_ipv4_part(split_addr[split_addr_len - 1])
      if (part === nil)
        # puts "+2"
        return nil
      end

      ip = Crunchy.from_number(part)
      split_addr = split_addr.slice(0, split_addr_len - 1)
    end

    split_addr.each do |i|
      part = IPAddress.parse_ipv4_part(i)
      #  console.log("u32-", addr, i, part)
      if (part === nil)
        # puts "+3"
        return nil
      end

      # println!("{}-{}", part_num, shift)
      ip = ip.add(Crunchy.from_number(part).shl(shift))
      shift -= 8
    end

    return ip
  end

  def self.is_valid_ipv4(addr)
    return !IPAddress.split_to_u32(addr).nil?
  end

  #  Checks if the given string is a valid IPv6 address
  #
  #  Example:
  #
  #    IPAddress.valid_ipv6? "2002.1"
  #      # => true
  #
  #    IPAddress.valid_ipv6? "2002.DEAD.BEEF"
  #      # => false
  #
  def self.split_on_colon(addr)
    parts = addr.strip().split(":")
    ip = Crunchy.zero()
    if (parts.length == 1 && parts[0].length == 0)
      return ResultCrunchyParts.new(ip, 0)
    end

    parts_len = parts.length
    shift = ((parts_len - 1) * 16)
    parts.each do |i|
      # println!("{}={}", addr, i)
      part = IPAddress.parse_hex_str(i)
      if (part === nil || part >= 65536)
        return nil
      end

      ip = ip.add(Crunchy.from_number(part).shl(shift))
      shift -= 16
    end

    return ResultCrunchyParts.new(ip, parts_len)
  end

  def self.split_to_num(addr)
    # ip = 0
    addr = addr.strip()
    pre_post = addr.split("::")
    if pre_post.length == 0 && addr.include?("::")
      pre_post << ""
    end

    if pre_post.length == 1 && addr.include?("::")
      pre_post << ""
    end

    #puts ">>>>split #{addr} #{pre_post}"
    if (pre_post.length > 2)
      return nil
    end

    if (pre_post.length == 2)
      # println!("{}=.={}", pre_post[0], pre_post[1])
      pre = IPAddress.split_on_colon(pre_post[0])
      if (!pre)
        return pre
      end

      post = IPAddress.split_on_colon(pre_post[1])
      if (!post)
        return post
      end

      #  println!("pre:{} post:{}", pre_parts, post_parts)
      return ResultCrunchyParts.new(
        pre.crunchy.shl(128 - (pre.parts * 16)).add(post.crunchy), 128 / 16)
    end

    # println!("split_to_num:no double:{}", addr)
    ret = IPAddress.split_on_colon(addr)
    if (ret == nil || ret.parts != 128 / 16)
      return nil
    end

    return ret
  end

  def self.is_valid_ipv6(addr)
    return IPAddress.split_to_num(addr) != nil
  end

  #  private helper for summarize
  #  assumes that networks is output from reduce_networks
  #  means it should be sorted lowers first and uniq
  #

  def self.pos_to_idx(pos, len)
    ilen = len
    #  ret = pos % ilen
    rem = ((pos % ilen) + ilen) % ilen
    #  println!("pos_to_idx:{}:{}=>{}:{}", pos, len, ret, rem)
    return rem
  end

  def self.aggregate(networks)
    if (networks.length == 0)
      return []
    end

    if (networks.length == 1)
      #  console.log("aggregate:", networks[0], networks[0].network())
      return [networks[0].network()]
    end

    stack = networks.map{|i| i.network()}.sort{|a, b| a.cmp(b) }
    #  console.log(IPAddress.to_string_vec(stack))
    #  for i in 0..networks.length {
    #      println!("{}==={}", &networks[i].to_string_uncompressed(),
    #          &stack[i].to_string_uncompressed())
    #  }
    pos = 0
    while true
      if (pos < 0)
        pos = 0
      end

      stack_len = stack.length #  borrow checker
      #  println!("loop:{}:{}", pos, stack_len)
      #  if stack_len == 1 {
      #      println!("exit 1")
      #      break
      #  }
      if (pos >= stack_len)
        #  println!("exit first:{}:{}", stack_len, pos)
        break
      end

      first = IPAddress.pos_to_idx(pos, stack_len)
      pos = pos + 1
      if (pos >= stack_len)
        #  println!("exit second:{}:{}", stack_len, pos)
        break
      end

      second = IPAddress.pos_to_idx(pos, stack_len)
      pos = pos + 1
      # firstUnwrap = first
      if (stack[first].includes(stack[second]))
        pos = pos - 2
        #  println!("remove:1:{}:{}:{}=>{}", first, second, stack_len, pos + 1)
        pidx = IPAddress.pos_to_idx(pos + 1, stack_len)
        stack.delete_at(pidx)
      else
        stack[first].prefix = stack[first].prefix.sub(1)
        #  println!("complex:{}:{}:{}:{}:P1:{}:P2:{}", pos, stack_len,
        #  first, second,
        #  stack[first].to_string(), stack[second].to_string())
        if ((stack[first].prefix.num + 1) == stack[second].prefix.num &&
            stack[first].includes(stack[second]))
          pos = pos - 2
          idx = IPAddress.pos_to_idx(pos, stack_len)
          stack[idx] = stack[first].clone(); #  kaputt
          pidx = IPAddress.pos_to_idx(pos + 1, stack_len)
          stack.delete_at(pidx)
          #  println!("remove-2:{}:{}", pos + 1, stack_len)
          pos = pos - 1; #  backtrack
        else
          stack[first].prefix = stack[first].prefix.add(1); # reset prefix
          #  println!("easy:{}:{}=>{}", pos, stack_len, stack[first].to_string())
          pos = pos - 1; #  do it with second as first
        end
      end
    end

    #  println!("agg={}:{}", pos, stack.length)
    return stack.slice(0, stack.length)
  end

  def parts()
    return @ip_bits.parts(@host_address)
  end

  def parts_hex_str()
    ret = []
    leading = 1 << @ip_bits.part_bits
    self.parts().each do |i|
      ret.push((leading + i).toString(16).slice(1))
    end

    return ret
  end

  #   Returns the IP address in in-addr.arpa format
  #   for DNS Domain definition entries like SOA Records
  #
  #     ip = IPAddress("172.17.100.50/15")
  #
  #     ip.dns_rev_domains
  #       #  => ["16.172.in-addr.arpa","17.172.in-addr.arpa"]
  #
  def dns_rev_domains()
    ret = []
    dns_networks().each do |net|
      #  console.log("dns_rev_domains:", @to_string(), net.to_string())
      ret.push(net.dns_reverse())
    end

    return ret
  end

  def dns_reverse()
    ret = ""
    dot = ""
    dns_parts = dns_parts()
    i = ((@prefix.host_prefix() + (@ip_bits.dns_bits - 1)) / @ip_bits.dns_bits)
    while  i < dns_parts().length
      #  console.log("dns_r", i);
      ret += dot
      ret += @ip_bits.dns_part_format(dns_parts[i])
      dot = "."
      i += 1
    end

    ret += dot
    ret += @ip_bits.rev_domain
    return ret
  end

  def dns_parts()
    ret = []
    num = @host_address.clone()
    mask = Crunchy.one().shl(@ip_bits.dns_bits)
    (@ip_bits.bits / @ip_bits.dns_bits).times do
      part = num.clone().mod(mask).num
      num = num.shr(@ip_bits.dns_bits)
      ret.push(part)
    end

    return ret
  end

  def dns_networks()
    #  +@ip_bits.dns_bits-1
    next_bit_mask = @ip_bits.bits -
      ((~~((@prefix.host_prefix()) / @ip_bits.dns_bits)) * @ip_bits.dns_bits)
    #  console.log("dns_networks-1", @to_string(), @prefix.host_prefix();j
    #  @ip_bits.dns_bits, next_bit_mask);
    if (next_bit_mask <= 0)
      return [network()]
    end

    #   println!("dns_networks:{}:{}", @to_string(), next_bit_mask)
    #  dns_bits
    step_bit_net = Crunchy.one().shl(@ip_bits.bits - next_bit_mask)
    if (step_bit_net.eq(Crunchy.zero()))
      #  console.log("dns_networks-2", @to_string());
      return [network()]
    end

    ret = []
    step = network().host_address
    prefix = @prefix.from(next_bit_mask)
    while (step.lte(broadcast().host_address))
      #  console.log("dns_networks-3", @to_string(), step.toString(), next_bit_mask, step_bit_net.toString());
      ret.push(from(step, prefix))
      step = step.add(step_bit_net)
    end

    return ret
  end

  #  Summarization (or aggregation) is the process when two or more
  #  networks are taken together to check if a supernet, including all
  #  and only these networks, exists. If it exists then @supernet
  #  is called the summarized (or aggregated) network.
  #
  #  It is very important to understand that summarization can only
  #  occur if there are no holes in the aggregated network, or, in other
  #  words, if the given networks fill completely the address space
  #  of the supernet. So the two rules are:
  #
  #  1) The aggregate network must contain +all+ the IP addresses of the
  #     original networks
  #  2) The aggregate network must contain +only+ the IP addresses of the
  #     original networks
  #
  #  A few examples will help clarify the above. Let's consider for
  #  instance the following two networks:
  #
  #    ip1 = IPAddress("172.16.10.0/24")
  #    ip2 = IPAddress("172.16.11.0/24")
  #
  #  These two networks can be expressed using only one IP address
  #  network if we change the prefix. Let Ruby do the work:
  #
  #    IPAddress.IPv4.summarize(ip1,ip2).to_s
  #      # => "172.16.10.0/23"
  #
  #  We note how the network "172.16.10.0/23" includes all the addresses
  #  specified in the above networks, and (more important) includes
  #  ONLY those addresses.
  #
  #  If we summarized +ip1+ and +ip2+ with the following network:
  #
  #    "172.16.0.0/16"
  #
  #  we would have satisfied rule # 1 above, but not rule # 2. So "172.16.0.0/16"
  #  is not an aggregate network for +ip1+ and +ip2+.
  #
  #  If it's not possible to compute a single aggregated network for all the
  #  original networks, the method returns an array with all the aggregate
  #  networks found. For example, the following four networks can be
  #  aggregated in a single /22:
  #
  #    ip1 = IPAddress("10.0.0.1/24")
  #    ip2 = IPAddress("10.0.1.1/24")
  #    ip3 = IPAddress("10.0.2.1/24")
  #    ip4 = IPAddress("10.0.3.1/24")
  #
  #    IPAddress.IPv4.summarize(ip1,ip2,ip3,ip4).to_string
  #      # => "10.0.0.0/22",
  #
  #  But the following networks can't be summarized in a single network:
  #
  #    ip1 = IPAddress("10.0.1.1/24")
  #    ip2 = IPAddress("10.0.2.1/24")
  #    ip3 = IPAddress("10.0.3.1/24")
  #    ip4 = IPAddress("10.0.4.1/24")
  #
  #    IPAddress.IPv4.summarize(ip1,ip2,ip3,ip4).map{|i| i.to_string}
  #      # => ["10.0.1.0/24","10.0.2.0/23","10.0.4.0/24"]
  #
  #
  #   Summarization (or aggregation) is the process when two or more
  #   networks are taken together to check if a supernet, including all
  #   and only these networks, exists. If it exists then @supernet
  #   is called the summarized (or aggregated) network.
  #
  #   It is very important to understand that summarization can only
  #   occur if there are no holes in the aggregated network, or, in other
  #   words, if the given networks fill completely the address space
  #   of the supernet. So the two rules are:
  #
  #   1) The aggregate network must contain +all+ the IP addresses of the
  #      original networks
  #   2) The aggregate network must contain +only+ the IP addresses of the
  #      original networks
  #
  #   A few examples will help clarify the above. Let's consider for
  #   instance the following two networks:
  #
  #     ip1 = IPAddress("2000:0.4/32")
  #     ip2 = IPAddress("2000:1.6/32")
  #
  #   These two networks can be expressed using only one IP address
  #   network if we change the prefix. Let Ruby do the work:
  #
  #     IPAddress.IPv6.summarize(ip1,ip2).to_s
  #       #  => "2000:0./31"
  #
  #   We note how the network "2000:0./31" includes all the addresses
  #   specified in the above networks, and (more important) includes
  #   ONLY those addresses.
  #
  #   If we summarized +ip1+ and +ip2+ with the following network:
  #
  #     "2000./16"
  #
  #   we would have satisfied rule #  1 above, but not rule #  2. So "2000./16"
  #   is not an aggregate network for +ip1+ and +ip2+.
  #
  #   If it's not possible to compute a single aggregated network for all the
  #   original networks, the method returns an array with all the aggregate
  #   networks found. For example, the following four networks can be
  #   aggregated in a single /22:
  #
  #     ip1 = IPAddress("2000:0./32")
  #     ip2 = IPAddress("2000:1./32")
  #     ip3 = IPAddress("2000:2./32")
  #     ip4 = IPAddress("2000:3./32")
  #
  #     IPAddress.IPv6.summarize(ip1,ip2,ip3,ip4).to_string
  #       #  => ""2000:3./30",
  #
  #   But the following networks can't be summarized in a single network:
  #
  #     ip1 = IPAddress("2000:1./32")
  #     ip2 = IPAddress("2000:2./32")
  #     ip3 = IPAddress("2000:3./32")
  #     ip4 = IPAddress("2000:4./32")
  #
  #     IPAddress.IPv4.summarize(ip1,ip2,ip3,ip4).map{|i| i.to_string}
  #       #  => ["2000:1./32","2000:2./31","2000:4./32"]
  #
  def self.summarize(*networks)
    return IPAddress.aggregate(networks.flatten)
  end

  def self.summarize_str(*netstr)
    vec = IPAddress.to_ipaddress_vec(netstr.flatten)
    #  console.log(netstr, vec)
    if (!vec)
      return vec
    end

    return IPAddress.aggregate(vec)
  end

  def ip_same_kind(oth)
    return @ip_bits.version == oth.ip_bits.version
  end

  #   Returns true if the address is an unspecified address
  #
  #   See IPAddress.IPv6.Unspecified for more information
  #
  def unspecified?
    is_unspecified
  end

  def is_unspecified()
    return @host_address.eq(Crunchy.zero())
  end

  #   Returns true if the address is a loopback address
  #
  #   See IPAddress.IPv6.Loopback for more information
  #
  def loopback?
    is_loopback
  end

  def is_loopback()
    return (@vt_is_loopback).call(self)
  end

  #   Returns true if the address is a mapped address
  #
  #   See IPAddress.IPv6.Mapped for more information
  #
  def mapped?
    is_mapped
  end

  def is_mapped()
    ret = !@mapped.nil? &&
      @host_address.shr(32).eq(Crunchy.one().shl(16).sub(Crunchy.one()))
    return ret
  end

  #   Returns the prefix portion of the IPv4 object
  #   as a IPAddress.Prefix32 object
  #
  #     ip = IPAddress("172.16.100.4/22")
  #
  #     ip.prefix
  #       #  => 22
  #
  #     ip.prefix.class
  #       #  => IPAddress.Prefix32
  #
  #  def prefix(): Prefix {
  #      return @prefix
  #  }


  #  Checks if the argument is a valid IPv4 netmask
  #  expressed in dotted decimal format.
  #
  #    IPAddress.valid_ipv4_netmask? "255.255.0.0"
  #      # => true
  #
  def self.is_valid_netmask(addr)
    return !IPAddress.parse_netmask_to_prefix(addr).nil?
  end

  def self.valid_netmask?(addr)
    is_valid_netmask(addr)
  end

  def self.netmask_to_prefix(nm, bits)
    prefix = 0
    addr = nm.clone()
    in_host_part = true
    #  two = Crunchy.two()
    _ = 0
    while _ < bits
      bit = addr.mds(2)
      #puts "#{nm.toString(16)} #{bit} #{_} #{in_host_part}"
      #  console.log(">>>", bits, bit, addr, nm)
      if (in_host_part && bit == 0)
        prefix = prefix + 1
      elsif (in_host_part && bit == 1)
        in_host_part = false
      elsif (!in_host_part && bit == 0)
        return nil
      end

      addr = addr.shr(1)
      _ += 1
    end

    return bits - prefix
  end

  def self.parse_netmask_to_prefix(netmask)
    #  console.log("--1", netmask)
    is_number = IPAddress.parse_dec_str(netmask)
    if (!is_number.nil?)
      #  console.log("--2", netmask, is_number)
      return is_number
    end

    my = IPAddress.parse(netmask)
    #  console.log("--3", netmask, my)
    if (!my)
      #  console.log("--4", netmask, my)
      return nil
    end

    #  console.log("--5", netmask, my)
    my_ip = my
    return IPAddress.netmask_to_prefix(my_ip.host_address, my_ip.ip_bits.bits)
  end

  #   Set a new prefix number for the object
  #
  #   This is useful if you want to change the prefix
  #   to an object created with IPv4.parse_u32 or
  #   if the object was created using the classful
  #   mask.
  #
  #     ip = IPAddress("172.16.100.4")
  #
  #     puts ip
  #       #  => 172.16.100.4/16
  #
  #     ip.prefix = 22
  #
  #     puts ip
  #       #  => 172.16.100.4/22
  #
  def change_prefix(num)
    prefix = @prefix.from(num)
    if (!prefix)
      return nil
    end

    return from(@host_address, prefix)
  end

  def change_netmask(str)
    nm = IPAddress.parse_netmask_to_prefix(str)
    if (!nm)
      return nil
    end

    return change_prefix(nm)
  end

  #   Returns a string with the IP address in canonical
  #   form.
  #
  #     ip = IPAddress("172.16.100.4/22")
  #
  #     ip.to_string
  #       #  => "172.16.100.4/22"
  #
  def to_string()
    ret = ""
    ret += to_s()
    ret += "/"
    ret += @prefix.to_s()
    return ret
  end

  def to_s()
    return @ip_bits.as_compressed_string(@host_address)
  end

  def to_string_uncompressed()
    ret = ""
    ret += to_s_uncompressed()
    ret += "/"
    ret += @prefix.to_s()
    return ret
  end

  def to_s_uncompressed()
    return @ip_bits.as_uncompressed_string(@host_address)
  end

  def to_s_mapped()
    if (is_mapped())
      return "::ffff:#{@mapped.to_s()}"
    end

    return to_s()
  end

  def to_string_mapped()
    if (is_mapped())
      mapped = @mapped.clone()
      return "#{to_s_mapped()}/#{mapped.prefix.num}"
    end

    return to_string()
  end

  #   Returns the address portion of an IP in binary format,
  #   as a string containing a sequence of 0 and 1
  #
  #     ip = IPAddress("127.0.0.1")
  #
  #     ip.bits
  #       #  => "01111111000000000000000000000001"
  #
  def bits()
    num = @host_address.toString(2)
    ret = ""
    _ = num.length
    while  _ < @ip_bits.bits
      ret += "0"
      _ += 1
    end

    ret += num
    return ret
  end

  def to_hex()
    return @host_address.toString(16)
  end

  def netmask()
    return from(@prefix.netmask(), @prefix)
  end

  #   Returns the broadcast address for the given IP.
  #
  #     ip = IPAddress("172.16.10.64/24")
  #
  #     ip.broadcast.to_s
  #       #  => "172.16.10.255"
  #
  def broadcast()
    return from(network().host_address.add(size().sub(Crunchy.one())), @prefix)
    #  IPv4.parse_u32(@broadcast_u32, @prefix)
  end

  #   Checks if the IP address is actually a network
  #
  #     ip = IPAddress("172.16.10.64/24")
  #
  #     ip.network?
  #       #  => false
  #
  #     ip = IPAddress("172.16.10.64/26")
  #
  #     ip.network?
  #       #  => true
  #
  def network?
    is_network
  end

  def is_network()
    return @prefix.num != @ip_bits.bits &&
      @host_address.eq(network().host_address)
  end

  #   Returns a new IPv4 object with the network number
  #   for the given IP.
  #
  #     ip = IPAddress("172.16.10.64/24")
  #
  #     ip.network.to_s
  #       #  => "172.16.10.0"
  #
  def network()
    return from(IPAddress.to_network(@host_address, @prefix.host_prefix()), @prefix)
  end

  def self.to_network(adr, host_prefix)
    return adr.shr(host_prefix).shl(host_prefix)
  end

  def sub(other)
    if (@host_address.gt(other.host_address))
      return @host_address.clone().sub(other.host_address)
    end

    return other.host_address.clone().sub(@host_address)
  end

  def add_num(num)
    return from(@host_address.add(num), @prefix)
  end

  def add(other)
    return IPAddress.aggregate([self, other])
  end

  def self.to_s_vec(vec)
    ret = []
    vec.each do |i|
      ret.push(i.to_s())
    end

    return ret
  end

  def self.to_string_vec(vec)
    ret = []
    vec.each do |i|
      ret.push(i.to_string())
    end

    return ret
  end

  def self.to_ipaddress_vec(vec)
    ret = []
    vec.each do |ipstr|
      ipa = IPAddress.parse(ipstr)
      if (!ipa)
        # puts "#{ipstr} failed"
        return nil
      end

      ret.push(ipa)
    end

    return ret
  end

  #   Returns a new IPv4 object with the
  #   first host IP address in the range.
  #
  #   Example: given the 192.168.100.0/24 network, the first
  #   host IP address is 192.168.100.1.
  #
  #     ip = IPAddress("192.168.100.0/24")
  #
  #     ip.first.to_s
  #       #  => "192.168.100.1"
  #
  #   The object IP doesn't need to be a network: the method
  #   automatically gets the network number from it
  #
  #     ip = IPAddress("192.168.100.50/24")
  #
  #     ip.first.to_s
  #       #  => "192.168.100.1"
  #
  def first()
    return from(network().host_address.add(@ip_bits.host_ofs), @prefix)
  end

  #   Like its sibling method IPv4#  first, @method
  #   returns a new IPv4 object with the
  #   last host IP address in the range.
  #
  #   Example: given the 192.168.100.0/24 network, the last
  #   host IP address is 192.168.100.254
  #
  #     ip = IPAddress("192.168.100.0/24")
  #
  #     ip.last.to_s
  #       #  => "192.168.100.254"
  #
  #   The object IP doesn't need to be a network: the method
  #   automatically gets the network number from it
  #
  #     ip = IPAddress("192.168.100.50/24")
  #
  #     ip.last.to_s
  #       #  => "192.168.100.254"
  #
  def last()
    return from(broadcast().host_address.sub(@ip_bits.host_ofs), @prefix)
  end

  #   Iterates over all the hosts IP addresses for the given
  #   network (or IP address).
  #
  #     ip = IPAddress("10.0.0.1/29")
  #
  #     ip.each_host do |i|
  #       p i.to_s
  #     end

  #       #  => "10.0.0.1"
  #       #  => "10.0.0.2"
  #       #  => "10.0.0.3"
  #       #  => "10.0.0.4"
  #       #  => "10.0.0.5"
  #       #  => "10.0.0.6"
  #
  def each_host(&func)
    i = first().host_address
    while (i.lte(last().host_address))
      func.call(from(i, @prefix))
      i = i.add(Crunchy.one())
    end
  end

  def inc()
    ret = clone()
    ret.host_address = ret.host_address.add(Crunchy.one())
    if (ret.lte(last()))
      return ret
    end

    return nil
  end

  def dec()
    ret = clone()
    ret.host_address = ret.host_address.sub(Crunchy.one())
    if (ret.gte(first()))
      return ret
    end

    return nil
  end

  #   Iterates over all the IP addresses for the given
  #   network (or IP address).
  #
  #   The object yielded is a new IPv4 object created
  #   from the iteration.
  #
  #     ip = IPAddress("10.0.0.1/29")
  #
  #     ip.each do |i|
  #       p i.address
  #     end

  #       #  => "10.0.0.0"
  #       #  => "10.0.0.1"
  #       #  => "10.0.0.2"
  #       #  => "10.0.0.3"
  #       #  => "10.0.0.4"
  #       #  => "10.0.0.5"
  #       #  => "10.0.0.6"
  #       #  => "10.0.0.7"
  #
  def each(&func)
    i = network().host_address
    while (i.num <= broadcast().host_address.num)
      func.call(from(i, @prefix))
      i = i.add(Crunchy.one())
    end
  end

  #   Spaceship operator to compare IPv4 objects
  #
  #   Comparing IPv4 addresses is useful to ordinate
  #   them into lists that match our intuitive
  #   perception of ordered IP addresses.
  #
  #   The first comparison criteria is the u32 value.
  #   For example, 10.100.100.1 will be considered
  #   to be less than 172.16.0.1, because, in a ordered list,
  #   we expect 10.100.100.1 to come before 172.16.0.1.
  #
  #   The second criteria, in case two IPv4 objects
  #   have identical addresses, is the prefix. An higher
  #   prefix will be considered greater than a lower
  #   prefix. This is because we expect to see
  #   10.100.100.0/24 come before 10.100.100.0/25.
  #
  #   Example:
  #
  #     ip1 = IPAddress "10.100.100.1/8"
  #     ip2 = IPAddress "172.16.0.1/16"
  #     ip3 = IPAddress "10.100.100.1/16"
  #
  #     ip1 < ip2
  #       #  => true
  #     ip1 > ip3
  #       #  => false
  #
  #     [ip1,ip2,ip3].sort.map{|i| i.to_string}
  #       #  => ["10.100.100.1/8","10.100.100.1/16","172.16.0.1/16"]
  #

  #   Returns the number of IP addresses included
  #   in the network. It also counts the network
  #   address and the broadcast address.
  #
  #     ip = IPAddress("10.0.0.1/29")
  #
  #     ip.size
  #       #  => 8
  #
  def size()
    return Crunchy.one().shl(@prefix.host_prefix())
  end

  def is_same_kind(oth)
    return is_ipv4() == oth.is_ipv4() &&
      is_ipv6() == oth.is_ipv6()
  end

  #   Checks whether a subnet includes the given IP address.
  #
  #   Accepts an IPAddress.IPv4 object.
  #
  #     ip = IPAddress("192.168.10.100/24")
  #
  #     addr = IPAddress("192.168.10.102/24")
  #
  #     ip.include? addr
  #       #  => true
  #
  #     ip.include? IPAddress("172.16.0.48/16")
  #       #  => false
  #
  def include?(oth)
    includes(oth)
  end

  def includes(oth)
    ret = is_same_kind(oth) &&
      @prefix.num <= oth.prefix.num &&
      network().host_address.eq(IPAddress.to_network(oth.host_address, @prefix.host_prefix()))
    #  println!("includes:{}=={}=>{}", @to_string(), oth.to_string(), ret)
    return ret
  end

  #   Checks whether a subnet includes all the
  #   given IPv4 objects.
  #
  #     ip = IPAddress("192.168.10.100/24")
  #
  #     addr1 = IPAddress("192.168.10.102/24")
  #     addr2 = IPAddress("192.168.10.103/24")
  #
  #     ip.include_all?(addr1,addr2)
  #       #  => true
  #
  def include_all?(*oths)
    includes_all(oths)
  end

  def includes_all(*oths)
    oths.flatten.each do |oth|
      if (!includes(oth))
        return false
      end
    end

    return true
  end

  #   Checks if an IPv4 address objects belongs
  #   to a private network RFC1918
  #
  #   Example:
  #
  #     ip = IPAddress "10.1.1.1/24"
  #     ip.private?
  #       #  => true
  #
  def private?
    is_private
  end

  def is_private()
    return @vt_is_private.call(self)
  end

  #   Splits a network into different subnets
  #
  #   If the IP Address is a network, it can be divided into
  #   multiple networks. If +self+ is not a network, this
  #   method will calculate the network from the IP and then
  #   subnet it.
  #
  #   If +subnets+ is an power of two number, the resulting
  #   networks will be divided evenly from the supernet.
  #
  #     network = IPAddress("172.16.10.0/24")
  #
  #     network / 4   #   implies map{|i| i.to_string}
  #       #  => ["172.16.10.0/26",
  #            "172.16.10.64/26",
  #            "172.16.10.128/26",
  #            "172.16.10.192/26"]
  #
  #   If +num+ is any other number, the supernet will be
  #   divided into some networks with a even number of hosts and
  #   other networks with the remaining addresses.
  #
  #     network = IPAddress("172.16.10.0/24")
  #
  #     network / 3   #   implies map{|i| i.to_string}
  #       #  => ["172.16.10.0/26",
  #            "172.16.10.64/26",
  #            "172.16.10.128/25"]
  #
  #   Returns an array of IPv4 objects
  #
  def sum_first_found(arr)
    dup = arr.clone()
    if (dup.length < 2)
      return dup
    end

    i = dup.length - 2
    while i >= 0
      #  console.log("sum_first_found:", dup[i], dup[i + 1])
      a = IPAddress.summarize([dup[i], dup[i + 1]])
      #  println!("dup:{}:{}:{}", dup.length, i, a.length)
      if (a.length == 1)
        dup[i] = a[0]
        dup.delete_at(i + 1)
        break
      end

      i -= 1
    end

    return dup
  end

  def split(subnets)
    if (subnets == 0 || (1 << @prefix.host_prefix()) <= subnets)
      return nil
    end

    networks = subnet(newprefix(subnets).num)
    if (!networks)
      return networks
    end

    net = networks
    while (net.length != subnets)
      net = sum_first_found(net)
    end

    return net
  end

  #  alias_method :/, :split

  #   Returns a new IPv4 object from the supernetting
  #   of the instance network.
  #
  #   Supernetting is similar to subnetting, except
  #   that you getting as a result a network with a
  #   smaller prefix (bigger host space). For example,
  #   given the network
  #
  #     ip = IPAddress("172.16.10.0/24")
  #
  #   you can supernet it with a new /23 prefix
  #
  #     ip.supernet(23).to_string
  #       #  => "172.16.10.0/23"
  #
  #   However if you supernet it with a /22 prefix, the
  #   network address will change:
  #
  #     ip.supernet(22).to_string
  #       #  => "172.16.8.0/22"
  #
  #   If +new_prefix+ is less than 1, returns 0.0.0.0/0
  #
  def supernet(new_prefix)
    if (new_prefix >= @prefix.num)
      return nil
    end

    if new_prefix < 0
      new_prefix = 0
    end

    #  new_ip = @host_address.clone()
    #  for _ in new_prefix..@prefix.num {
    #      new_ip = new_ip << 1
    #  }
    return from(@host_address, @prefix.from(new_prefix)).network()
  end

  #   This method implements the subnetting function
  #   similar to the one described in RFC3531.
  #
  #   By specifying a new prefix, the method calculates
  #   the network number for the given IPv4 object
  #   and calculates the subnets associated to the new
  #   prefix.
  #
  #   For example, given the following network:
  #
  #     ip = IPAddress "172.16.10.0/24"
  #
  #   we can calculate the subnets with a /26 prefix
  #
  #     ip.subnets(26).map(:to_string)
  #       #  => ["172.16.10.0/26", "172.16.10.64/26",
  #            "172.16.10.128/26", "172.16.10.192/26"]
  #
  #   The resulting number of subnets will of course always be
  #   a power of two.
  #
  def subnet(subprefix)
    if (subprefix < @prefix.num || @ip_bits.bits < subprefix)
      return nil
    end

    ret = []
    net = network()
    net.prefix = net.prefix.from(subprefix)
    (1 << (subprefix - @prefix.num)).times do
      ret.push(net.clone())
      net = net.from(net.host_address, net.prefix)
      size = net.size()
      net.host_address = net.host_address.add(size)
    end

    return ret
  end

  #   Return the ip address in a format compatible
  #   with the IPv6 Mapped IPv4 addresses
  #
  #   Example:
  #
  #     ip = IPAddress("172.16.10.1/24")
  #
  #     ip.to_ipv6
  #       #  => "ac10:0a01"
  #
  def to_ipv6()
    return @vt_to_ipv6.call(self)
  end

  def newprefix(num)
    i = num
    while i < @ip_bits.bits
      a = Math.log2(i).to_i
      if (a == Math.log2(i))
        return @prefix.add(a)
      end

      i += 1
    end

    return nil
  end

  def data
    vec = []
    my = host_address
    part_mod = Crunchy.one().shl(8)
    i = 0
    while i < self.ip_bits.bits
      vec.push(my.mod(part_mod).num)
      my = my.shr(8)
      i = i + 8
    end

    return vec.reverse().pack("c*")
  end
end
