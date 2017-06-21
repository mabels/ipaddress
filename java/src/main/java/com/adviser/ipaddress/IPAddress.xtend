package com.adviser.ipaddress

import java.math.BigInteger
import java.util.Collections
import java.util.Vector
import java.util.List
import java.util.regex.Pattern
import java.util.Arrays

class IPAddress {
    public final IpBits ip_bits
    public final BigInteger host_address
    public final Prefix prefix
    public final IPAddress mapped
    public interface VtBool {
       def boolean run(IPAddress ipa);
    }
    public final VtBool vt_is_private
    public final VtBool vt_is_loopback
    public interface VtIPAddress {
        def IPAddress run(IPAddress ipa);
    }
    public final VtIPAddress vt_to_ipv6

    override def String toString() {
        return '''IPAddress:«this.to_string()»@«this.hashCode»'''
    }
    static final Pattern RE_MAPPED = Pattern.compile(":.+\\.");
    static final Pattern RE_IPV4 = Pattern.compile("\\.");
    static final Pattern RE_IPV6 = Pattern.compile(":");

    new(IpBits ip_bits, BigInteger host_address, Prefix prefix,
        IPAddress mapped, VtBool is_private, VtBool is_loopback,
        VtIPAddress to_ipv6) {
        this.ip_bits = ip_bits
        this.host_address = host_address
        this.prefix = prefix
        this.mapped = mapped
        this.vt_is_private = is_private
        this.vt_is_loopback = is_loopback
        this.vt_to_ipv6 = to_ipv6
    }
        
    override def IPAddress clone() {
      if (mapped === null) {
        this.setMapped(null)
      } else {
        this.setMapped(this.mapped.clone())
      }
    }
    
    public def IPAddress from(BigInteger addr, Prefix prefix) {
      var IPAddress map = null
      if (map !== null) {
        map = this.mapped.clone()
      }
      setMapped(addr, map, prefix.clone())
    }
    
    public def setMapped(IPAddress mapped) {
      return setMapped(this.host_address, mapped, this.prefix.clone())
    }

    public def setMapped(BigInteger hostAddr, IPAddress mapped, Prefix prefix) {
        return new IPAddress(
            this.ip_bits,
            BigInteger.ZERO.add(hostAddr),
            prefix,
            mapped,
            this.vt_is_private,
            this.vt_is_loopback,
            this.vt_to_ipv6)
    }
    
    public override def boolean equals(Object oth) {
      return compare(oth as IPAddress) == 0
    }

    public def int compare(IPAddress oth)  {
            if (this.ip_bits.version != oth.ip_bits.version) {
                if (this.ip_bits.version == IpVersion.V6) {
                    return 1
                }
                return -1
            }
            //let adr_diff = this.host_address - oth.host_address;
            val comp = this.host_address.compareTo(oth.host_address) 
            if (comp < 0) {
                return -1
            } else if (comp > 0){
                return 1
            }
            return this.prefix.compare(oth.prefix);
    }

    public def boolean equal(IPAddress other) {
        return this.ip_bits.version == other.ip_bits.version &&
            this.prefix.equal(other.prefix) &&
            this.host_address.equals(other.host_address) &&
            ((this.mapped === null && this.mapped === other.mapped) || this.mapped.equal(other.mapped))
    }
    
    public def boolean lt(IPAddress ipa) {
      return this.compare(ipa) < 0
    }

    public def boolean gt(IPAddress ipa) {
      return this.compare(ipa) > 0
    }


    public static def List<IPAddress> sort(List<IPAddress> ipas) {
      val ret = new Vector<IPAddress>(ipas)
      Collections.sort(ret, [a, b| return a.compare(b) ])
      return ret
    }

    /// Parse the argument string to create a new
    /// IPv4, IPv6 or Mapped IP object
    ///
    ///   ip  = IPAddress.parse "172.16.10.1/24"
    ///  ip6 = IPAddress.parse "2001:db8::8:800:200c:417a/64"
    ///  ip_mapped = IPAddress.parse "::ffff:172.16.10.1/128"
    ///
    /// All the object created will be instances of the
    /// correct class:
    ///
    ///  ip.class
    ///   //=> IPAddress::IPv4
    /// ip6.class
    ///   //=> IPAddress::IPv6
    /// ip_mapped.class
    ///   //=> IPAddress::IPv6::Mapped
    ///
    public static def Result<IPAddress> parse(String str) {
        if (RE_MAPPED.matcher(str).find()) {
            // println!("mapped:{}", &str);
            return Ipv6Mapped.create(str);
        } else {
            if (RE_IPV4.matcher(str).find()) {
                // println!("ipv4:{}", &str);
                return IpV4.create(str);
            } else if (RE_IPV6.matcher(str).find()) {
                // println!("ipv6:{}", &str);
                return IpV6.create(str);
            }
        }
        return Result.Err('''Unknown IP Address <<str>>''');
    }

    static class AddrNetmask {
        public final String addr;
        public final String netmask;
        new(String addr, String netmask) {
            this.addr = addr
            this.netmask = netmask
        }
    }

    public static def AddrNetmask split_at_slash(String str) {
        val slash = str.trim().split("/");
        var addr = ""
        if (slash.length >= 1) {
            addr = slash.get(0).trim();
        }
        if (slash.length >= 2) {
            return new AddrNetmask(addr, slash.get(1).trim());
        } else {
            return new AddrNetmask(addr, null);
        }
    }



    /// True if the object is an IPv4 address
    ///
    ///   ip = IPAddress("192.168.10.100/24")
    ///
    ///   ip.ipv4?
    ///     //-> true
    ///
    public def boolean is_ipv4() {
        return this.ip_bits.version == IpVersion.V4
    }

    /// True if the object is an IPv6 address
    ///
    ///   ip = IPAddress("192.168.10.100/24")
    ///
    ///   ip.ipv6?
    ///     //-> false
    ///
    public def boolean is_ipv6() {
      return this.ip_bits.version == IpVersion.V6
    }

    /// Checks if the given string is a valid IP address,
    /// either IPv4 or IPv6
    ///
    /// Example:
    ///
    ///  IPAddress::valid? "2002::1"
    ///    //=> true
    ///
    ///  IPAddress::valid? "10.0.0.256"
    ///    //=> false
    ///
    public static def boolean is_valid(String addr) {
        return IPAddress.is_valid_ipv4(addr) || IPAddress.is_valid_ipv6(addr);
    }

    /// Checks if the given string is a valid IPv4 address
    ///
    /// Example:
    ///
    ///   IPAddress::valid_ipv4? "2002::1"
    ///     //=> false
    ///
    ///   IPAddress::valid_ipv4? "172.16.10.1"
    ///     //=> true
    ///
    public static def Result<Integer> parse_ipv4_part(String i, String addr) {
        try {
            val part = new Integer(i)
            if (part.intValue() >= 256) {
                return Result.Err('''IP items has to lower than 256. <<addr>>''');
            }
            return Result.Ok(part.intValue());
        } catch (NumberFormatException e) {
            return Result.Err('''IP must contain numbers <<addr>>''');
        }
    }

    public static def Result<Long> split_to_u32(String addr)  {
        var ip = 0L;
        var shift = 24;
        var split_addr = addr.split("\\."); //.collect::<Vec<&str>>();
        if (split_addr.length() > 4) {
            return Result.Err('''IP has not the right format:<<addr>>''');
        }
        val split_addr_len = split_addr.length();
        if (split_addr_len < 4) {
            val part = IPAddress.parse_ipv4_part(split_addr.get(split_addr_len-1), addr);
            if (part.isErr()) {
                return Result.Err(part.unwrapErr());
            }
            ip = part.unwrap()
            split_addr = Arrays.copyOf(split_addr, split_addr_len-1)
        }
        for (i : split_addr) {
            val part = IPAddress.parse_ipv4_part(i, addr);
            if (part.isErr()) {
                return Result.Err(part.unwrapErr());
            }
            // println!("{}-{}", part_num, shift);
            ip = ip.bitwiseOr(part.unwrap().longValue() << shift);
            shift -= 8;
        }
        return Result.Ok(ip);
    }
    
    public static def boolean is_valid_ipv4(String addr) {
        return IPAddress.split_to_u32(addr).isOk();
    }


    /// Checks if the given string is a valid IPv6 address
    ///
    /// Example:
    ///
    ///   IPAddress::valid_ipv6? "2002::1"
    ///     //=> true
    ///
    ///   IPAddress::valid_ipv6? "2002::DEAD::BEEF"
    ///     // => false
    ///
    static class SplitOnColon {
        public BigInteger ip
        public int size
        new(BigInteger ip, int size) {
            this.ip = ip
            this.size = size
        }
    }
    public static def Result<SplitOnColon> split_on_colon(String addr)  {
        val parts = addr.trim().split(":")
        var ip = BigInteger.ZERO
        if (parts.length() == 1 && parts.get(0).isEmpty()) {
            return Result.Ok(new SplitOnColon(ip, 0));
        }
        val parts_len = parts.length();
        var shift = ((parts_len - 1) * 16)
        for (i : parts) {
            //println!("{}={}", addr, i);
            val part = IPAddress.parseInt(i, 16)
            if (part === null) {
                return Result.Err('''IP must contain hex numbers <<addr>>-><<i>>''');
            }
            val part_num = part.intValue();
            if (part_num >= 65536) {
                return Result.Err('''IP items has to lower than 65536. <<addr>>''');
            }
            ip = ip.add(BigInteger.valueOf(part_num).shiftLeft(shift));
            shift -= 16;
        }
        return Result.Ok(new SplitOnColon(ip, parts_len));
    }

    public static def Result<BigInteger> split_to_num(String addr) {
        var pre_post = addr.trim().split("::")
        if (pre_post.length === 0 && addr.contains("::")) {
          pre_post = Arrays.copyOf(pre_post, pre_post.length + 1)
          pre_post.set(pre_post.length-1, "")
        }
        if (pre_post.length === 1 && addr.contains("::")) {
          pre_post = Arrays.copyOf(pre_post, pre_post.length + 1)
          pre_post.set(pre_post.length-1, "")
        }
        if (pre_post.length() > 2) {
            return Result.Err('''IPv6 only allow one :: <<addr>>''');
        }
        if (pre_post.length() == 2) {
            //println!("{}=::={}", pre_post[0], pre_post[1]);
            val pre = IPAddress.split_on_colon(pre_post.get(0))
            if (pre.isErr()) {
                return Result.Err(pre.unwrapErr());
            }
            val post = IPAddress.split_on_colon(pre_post.get(1));
            if (post.isErr()) {
                return Result.Err(post.unwrapErr());
            }
            // println!("pre:{} post:{}", pre_parts, post_parts);
            return Result.Ok((pre.unwrap().ip.shiftLeft(128 - (pre.unwrap().size * 16))).add(post.unwrap().ip));
        }
        //println!("split_to_num:no double:{}", addr);
        val ret = IPAddress.split_on_colon(addr);
        if (ret.isErr() || ret.unwrap().size != 128/16) {
            return Result.Err('''incomplete IPv6''');
        }
        return Result.Ok(ret.unwrap().ip);
    }
    
    public static def boolean is_valid_ipv6(String addr) {
        return IPAddress.split_to_num(addr).isOk();
    }


    /// private helper for summarize
    /// assumes that networks is output from reduce_networks
    /// means it should be sorted lowers first and uniq
    ///

    public static def int pos_to_idx(int pos, int len) {
        val ilen = len //as isize;
        // let ret = pos % ilen;
        val rem = ((pos % ilen) + ilen) % ilen;
        // println!("pos_to_idx:{}:{}=>{}:{}", pos, len, ret, rem);
        return rem;
    }
    
    public static def List<IPAddress> aggregate(List<IPAddress> networks) {
        if (networks.length() == 0) {
            return new Vector<IPAddress>();
        }
        if (networks.length() == 1) {
            return new Vector<IPAddress>(#[networks.get(0).network()]);
        }
        val stack = IPAddress.sort(networks.map[i| i.network()])

        // for i in 0..networks.len() {
        //     println!("{}==={}", &networks[i].to_string_uncompressed(),
        //         &stack[i].to_string_uncompressed());
        // }
        var pos = 0;
        while (true) {
            if (pos < 0) {
                pos = 0
            }
            val stack_len = stack.length(); // borrow checker
            // println!("loop:{}:{}", pos, stack_len);
            // if stack_len == 1 {
            //     println!("exit 1");
            //     break;
            // }
            if (pos >= stack_len) {
                // println!("exit first:{}:{}", stack_len, pos);
                return stack//.map[i| return i.network()];
            }
            val first = IPAddress.pos_to_idx(pos, stack_len);
            pos = pos + 1;
            if (pos >= stack_len) {
                // println!("exit second:{}:{}", stack_len, pos);
                return stack//.map[i| return i.network()];
            }
            val second = IPAddress.pos_to_idx(pos, stack_len);
            pos = pos + 1;
            //let mut firstUnwrap = first.unwrap();
            if (stack.get(first).includes(stack.get(second))) {
                pos = pos - 2;
                // println!("remove:1:{}:{}:{}=>{}", first, second, stack_len, pos + 1);
                stack.remove(IPAddress.pos_to_idx(pos + 1, stack_len));
            } else {
                val ipFirst = stack.get(first)
                stack.set(first, ipFirst.change_prefix(ipFirst.prefix.sub(1).unwrap()).unwrap());
                // println!("complex:{}:{}:{}:{}:P1:{}:P2:{}", pos, stack_len,
                // first, second,
                // stack[first].to_string(), stack[second].to_string());
                if ((stack.get(first).prefix.num+1) == stack.get(second).prefix.num &&
                   stack.get(first).includes(stack.get(second))) {
                    pos = pos - 2;
                    val idx = IPAddress.pos_to_idx(pos, stack_len);
                    stack.set(idx, stack.get(first).clone()); // kaputt
                    stack.remove(IPAddress.pos_to_idx(pos + 1, stack_len));
                    // println!("remove-2:{}:{}", pos + 1, stack_len);
                    pos = pos - 1; // backtrack
                } else {
                    val myFirst = stack.get(first)
                    stack.set(first, myFirst.change_prefix(myFirst.prefix.add(1).unwrap()).unwrap()); //reset prefix
                    // println!("easy:{}:{}=>{}", pos, stack_len, stack[first].to_string());
                    pos = pos - 1; // do it with second as first
                }
            }
        }
        // println!("agg={}:{}", pos, stack.len());
        //;
    }

    public def int[] parts() {
        return this.ip_bits.parts(this.host_address);
    }

    public def String[] parts_hex_str() {
        val parts = this.parts()
        var String[] ret = newArrayOfSize(parts.length)
        for (var i = 0; i < parts.length; i++) {
            ret.set(i, String.format("%04x", parts.get(i)));
        }
        return ret;
    }

    ///  Returns the IP address in in-addr.arpa format
    ///  for DNS Domain definition entries like SOA Records
    ///
    ///    ip = IPAddress("172.17.100.50/15")
    ///
    ///    ip.dns_rev_domains
    ///      // => ["16.172.in-addr.arpa","17.172.in-addr.arpa"]
    ///
    public def String[] dns_rev_domains() {
        val dns_networks = this.dns_networks()
        var String[] ret = newArrayOfSize(dns_networks.length)
        for (var i = 0; i < dns_networks.length; i++) {
            // println!("dns_rev_domains:{}:{}", this.to_string(), net.to_string());
            ret.set(i, dns_networks.get(i).dns_reverse());
        }
        return ret;
    }


    public def String dns_reverse() {
        val ret = new StringBuffer()
        var dot = "";
        val dns_parts = this.dns_parts();
        for (var i  = ((this.prefix.host_prefix()+(this.ip_bits.dns_bits-1))/this.ip_bits.dns_bits); i < dns_parts.length(); i++) {
            ret.append(dot);
            ret.append(this.ip_bits.dns_part_format(dns_parts.get(i)));
            dot = ".";
        }
        ret.append(dot);
        ret.append(this.ip_bits.rev_domain);
        return ret.toString();
    }


    public def int[] dns_parts() {
        val len = this.ip_bits.bits/this.ip_bits.dns_bits
        var ret = newIntArrayOfSize(len)
        var num = BigInteger.ZERO.add(this.host_address);
        val mask = BigInteger.ONE.shiftLeft(this.ip_bits.dns_bits);
        for (var _ = 0; _ < len; _++) {
            var part = num.mod(mask)
            num = num.shiftRight(this.ip_bits.dns_bits);
            ret.set(_, part.intValue());
        }
        return ret;
    }

    public def List<IPAddress> dns_networks() {
        // +this.ip_bits.dns_bits-1
         val next_bit_mask = this.ip_bits.bits -
            (((this.prefix.host_prefix())/this.ip_bits.dns_bits)*this.ip_bits.dns_bits);
         if (next_bit_mask <= 0) {
             return #[this.network()];
         }
        //  println!("dns_networks:{}:{}", this.to_string(), next_bit_mask);
         // dns_bits
         val step_bit_net = BigInteger.ONE.shiftLeft(this.ip_bits.bits-next_bit_mask);
         if (step_bit_net.equals(BigInteger.ZERO)) {
             return #[this.network()];
         }
         var ret = new Vector<IPAddress>();
         var step = this.network().host_address;
         val prefix = this.prefix.from(next_bit_mask).unwrap();
         while (step.compareTo(this.broadcast().host_address) <= 0) {
           ret.add(this.from(step, prefix));
           step = step.add(step_bit_net);
         }
         return ret;
      }


    /// Summarization (or aggregation) is the process when two or more
    /// networks are taken together to check if a supernet, including all
    /// and only these networks, exists. If it exists then this supernet
    /// is called the summarized (or aggregated) network.
    ///
    /// It is very important to understand that summarization can only
    /// occur if there are no holes in the aggregated network, or, in other
    /// words, if the given networks fill completely the address space
    /// of the supernet. So the two rules are:
    ///
    /// 1) The aggregate network must contain +all+ the IP addresses of the
    ///    original networks;
    /// 2) The aggregate network must contain +only+ the IP addresses of the
    ///    original networks;
    ///
    /// A few examples will help clarify the above. Let's consider for
    /// instance the following two networks:
    ///
    ///   ip1 = IPAddress("172.16.10.0/24")
    ///   ip2 = IPAddress("172.16.11.0/24")
    ///
    /// These two networks can be expressed using only one IP address
    /// network if we change the prefix. Let Ruby do the work:
    ///
    ///   IPAddress::IPv4::summarize(ip1,ip2).to_s
    ///     ///  "172.16.10.0/23"
    ///
    /// We note how the network "172.16.10.0/23" includes all the addresses
    /// specified in the above networks, and (more important) includes
    /// ONLY those addresses.
    ///
    /// If we summarized +ip1+ and +ip2+ with the following network:
    ///
    ///   "172.16.0.0/16"
    ///
    /// we would have satisfied rule /// 1 above, but not rule /// 2. So "172.16.0.0/16"
    /// is not an aggregate network for +ip1+ and +ip2+.
    ///
    /// If it's not possible to compute a single aggregated network for all the
    /// original networks, the method returns an array with all the aggregate
    /// networks found. For example, the following four networks can be
    /// aggregated in a single /22:
    ///
    ///   ip1 = IPAddress("10.0.0.1/24")
    ///   ip2 = IPAddress("10.0.1.1/24")
    ///   ip3 = IPAddress("10.0.2.1/24")
    ///   ip4 = IPAddress("10.0.3.1/24")
    ///
    ///   IPAddress::IPv4::summarize(ip1,ip2,ip3,ip4).to_string
    ///     ///  "10.0.0.0/22",
    ///
    /// But the following networks can't be summarized in a single network:
    ///
    ///   ip1 = IPAddress("10.0.1.1/24")
    ///   ip2 = IPAddress("10.0.2.1/24")
    ///   ip3 = IPAddress("10.0.3.1/24")
    ///   ip4 = IPAddress("10.0.4.1/24")
    ///
    ///   IPAddress::IPv4::summarize(ip1,ip2,ip3,ip4).map{|i| i.to_string}
    ///     ///  ["10.0.1.0/24","10.0.2.0/23","10.0.4.0/24"]
    ///
    ///
    ///  Summarization (or aggregation) is the process when two or more
    ///  networks are taken together to check if a supernet, including all
    ///  and only these networks, exists. If it exists then this supernet
    ///  is called the summarized (or aggregated) network.
    ///
    ///  It is very important to understand that summarization can only
    ///  occur if there are no holes in the aggregated network, or, in other
    ///  words, if the given networks fill completely the address space
    ///  of the supernet. So the two rules are:
    ///
    ///  1) The aggregate network must contain +all+ the IP addresses of the
    ///     original networks;
    ///  2) The aggregate network must contain +only+ the IP addresses of the
    ///     original networks;
    ///
    ///  A few examples will help clarify the above. Let's consider for
    ///  instance the following two networks:
    ///
    ///    ip1 = IPAddress("2000:0::4/32")
    ///    ip2 = IPAddress("2000:1::6/32")
    ///
    ///  These two networks can be expressed using only one IP address
    ///  network if we change the prefix. Let Ruby do the work:
    ///
    ///    IPAddress::IPv6::summarize(ip1,ip2).to_s
    ///      ///  "2000:0::/31"
    ///
    ///  We note how the network "2000:0::/31" includes all the addresses
    ///  specified in the above networks, and (more important) includes
    ///  ONLY those addresses.
    ///
    ///  If we summarized +ip1+ and +ip2+ with the following network:
    ///
    ///    "2000::/16"
    ///
    ///  we would have satisfied rule /// 1 above, but not rule /// 2. So "2000::/16"
    ///  is not an aggregate network for +ip1+ and +ip2+.
    ///
    ///  If it's not possible to compute a single aggregated network for all the
    ///  original networks, the method returns an array with all the aggregate
    ///  networks found. For example, the following four networks can be
    ///  aggregated in a single /22:
    ///
    ///    ip1 = IPAddress("2000:0::/32")
    ///    ip2 = IPAddress("2000:1::/32")
    ///    ip3 = IPAddress("2000:2::/32")
    ///    ip4 = IPAddress("2000:3::/32")
    ///
    ///    IPAddress::IPv6::summarize(ip1,ip2,ip3,ip4).to_string
    ///      ///  ""2000:3::/30",
    ///
    ///  But the following networks can't be summarized in a single network:
    ///
    ///    ip1 = IPAddress("2000:1::/32")
    ///    ip2 = IPAddress("2000:2::/32")
    ///    ip3 = IPAddress("2000:3::/32")
    ///    ip4 = IPAddress("2000:4::/32")
    ///
    ///    IPAddress::IPv4::summarize(ip1,ip2,ip3,ip4).map{|i| i.to_string}
    ///      ///  ["2000:1::/32","2000:2::/31","2000:4::/32"]
    ///
    
    public static def List<IPAddress> summarize(List<IPAddress> networks) {
        return IPAddress.aggregate(networks);
    }
    
    public static def Result<List<IPAddress>> summarize_str(List<String> netstr) {
        val vec = IPAddress.to_ipaddress_vec(netstr);
        if (vec.isErr()) {
            return vec;
        }
        return Result.Ok(IPAddress.aggregate(vec.unwrap()));
    }

    
    public def boolean ip_same_kind(IPAddress oth)  {
        return this.ip_bits.version == oth.ip_bits.version
    }

    ///  Returns true if the address is an unspecified address
    ///
    ///  See IPAddress::IPv6::Unspecified for more information
    ///
    
    public def boolean is_unspecified() {
        return this.host_address.equals(BigInteger.ZERO);
    }

    ///  Returns true if the address is a loopback address
    ///
    ///  See IPAddress::IPv6::Loopback for more information
    ///
    
    public def boolean is_loopback() {
        return this.vt_is_loopback.run(this);
    }


    ///  Returns true if the address is a mapped address
    ///
    ///  See IPAddress::IPv6::Mapped for more information
    ///
    
    public def boolean is_mapped() {
        val ffff = BigInteger.valueOf(0xffff) //.ONE.shiftLeft(16).sub(BigInteger.ONE)
        return (this.mapped !== null && (this.host_address.shiftRight(32).equals(ffff)))
    }


    ///  Returns the prefix portion of the IPv4 object
    ///  as a IPAddress::Prefix32 object
    ///
    ///    ip = IPAddress("172.16.100.4/22")
    ///
    ///    ip.prefix
    ///      ///  22
    ///
    ///    ip.prefix.class
    ///      ///  IPAddress::Prefix32
    ///
    
    public def Prefix prefix() {
        return this.prefix;
    }



    /// Checks if the argument is a valid IPv4 netmask
    /// expressed in dotted decimal format.
    ///
    ///   IPAddress.valid_ipv4_netmask? "255.255.0.0"
    ///     ///  true
    ///
    
    public static def boolean is_valid_netmask(String addr) {
        return IPAddress.parse_netmask_to_prefix(addr).isOk();
    }

    public static def Result<Integer> netmask_to_prefix(BigInteger nm, int bits) {
        var prefix = 0;
        var addr = BigInteger.ZERO.add(nm);
        var in_host_part = true;
        val two = BigInteger.valueOf(2)
        for (var _ = 0; _ < bits; _++) {
            val bit = addr.mod(two).intValue()
            if (in_host_part && bit == 0) {
                prefix = prefix + 1;
            } else if (in_host_part && bit == 1) {
                in_host_part = false;
            } else if (!in_host_part && bit == 0) {
                return Result.Err('''this is not a net mask <<nm>>''');
            }
            addr = addr.shiftRight(1);
        }
        return Result.Ok(bits-prefix);
    }


    public static def Result<Integer> parse_netmask_to_prefix(String my_str) {
        val is_number = IPAddress.parseInt(my_str, 10);
        if (is_number !== null) {
            return Result.Ok(is_number.intValue());
        }
        val my = IPAddress.parse(my_str);
        if (my.isErr()) {
            return Result.Err('''illegal netmask <<my.unwrap_err()>>''');
        }
        val my_ip = my.unwrap();
        return IPAddress.netmask_to_prefix(my_ip.host_address, my_ip.ip_bits.bits);
    }


    ///  Set a new prefix number for the object
    ///
    ///  This is useful if you want to change the prefix
    ///  to an object created with IPv4::parse_u32 or
    ///  if the object was created using the classful
    ///  mask.
    ///
    ///    ip = IPAddress("172.16.100.4")
    ///
    ///    puts ip
    ///      ///  172.16.100.4/16
    ///
    ///    ip.prefix = 22
    ///
    ///    puts ip
    ///      ///  172.16.100.4/22
    ///
    public def Result<IPAddress> change_prefix(Prefix prefix) {
        return Result.Ok(this.from(this.host_address, prefix));
    }
    
    public def Result<IPAddress> change_prefix(int num) {
        val prefix =  this.prefix.from(num);
        if (prefix.isErr()) {
            return Result.Err(prefix.unwrapErr());
        }
        return Result.Ok(this.from(this.host_address, prefix.unwrap()));
    }

    public def Result<IPAddress> change_netmask(String my_str) {
        val nm = IPAddress.parse_netmask_to_prefix(my_str);
        if (nm.isErr()) {
            return Result.Err(nm.unwrapErr());
        }
        return this.change_prefix(nm.unwrap());
    }



    ///  Returns a string with the IP address in canonical
    ///  form.
    ///
    ///    ip = IPAddress("172.16.100.4/22")
    ///
    ///    ip.to_string
    ///      ///  "172.16.100.4/22"
    ///
    public def String to_string() {
        var ret = new StringBuffer()
        ret.append(this.to_s());
        ret.append("/");
        ret.append(this.prefix.to_s());
        return ret.toString();
    }

    public def String to_s() {
        return this.ip_bits.as_compressed_string(this.host_address);
    }

    public def String to_string_uncompressed() {
        var ret = new StringBuffer()
        ret.append(this.to_s_uncompressed());
        ret.append("/");
        ret.append(this.prefix.to_s());
        return ret.toString();
    }
    
    public def String to_s_uncompressed() {
        return this.ip_bits.as_uncompressed_string(this.host_address);
    }

    
    public def String to_s_mapped() {
        if (this.is_mapped()) {
            return String.format("%s%s", "::ffff:", this.mapped.to_s());
        }
        return this.to_s();
    }
    
    public def String to_string_mapped() {
        if (this.is_mapped()) {
            val mapped = this.mapped;
            return String.format("%s/%d", this.to_s_mapped(), mapped.prefix.num);
        }
        return this.to_string();
    }



    ///  Returns the address portion of an IP in binary format,
    ///  as a string containing a sequence of 0 and 1
    ///
    ///    ip = IPAddress("127.0.0.1")
    ///
    ///    ip.bits
    ///      ///  "01111111000000000000000000000001"
    ///
    
    public def String bits() {
        val num = this.host_address.toString(2);
        var ret = new StringBuffer()
        for (var _ = num.length(); _ < this.ip_bits.bits; _++) {
            ret.append("0");
        }
        ret.append(num);
        return ret.toString();
    }
    
    public def String to_hex() {
        return this.host_address.toString(16);
    }

    public def IPAddress netmask() {
        this.from(this.prefix.netmask(), this.prefix)
    }

    ///  Returns the broadcast address for the given IP.
    ///
    ///    ip = IPAddress("172.16.10.64/24")
    ///
    ///    ip.broadcast.to_s
    ///      ///  "172.16.10.255"
    ///
    
    public def IPAddress broadcast() {
      val bcast = this.network().host_address.add(this.size()).subtract(BigInteger.ONE)
      return this.from(bcast, this.prefix);
        // IPv4::parse_u32(this.broadcast_u32, this.prefix)
    }

    ///  Checks if the IP address is actually a network
    ///
    ///    ip = IPAddress("172.16.10.64/24")
    ///
    ///    ip.network?
    ///      ///  false
    ///
    ///    ip = IPAddress("172.16.10.64/26")
    ///
    ///    ip.network?
    ///      ///  true
    ///
    
    public def boolean is_network() {
        return this.prefix.num != this.ip_bits.bits &&
            this.host_address.equals(this.network().host_address);
    }

    ///  Returns a new IPv4 object with the network number
    ///  for the given IP.
    ///
    ///    ip = IPAddress("172.16.10.64/24")
    ///
    ///    ip.network.to_s
    ///      ///  "172.16.10.0"
    ///
    
    public def IPAddress network() {
        return this.from(IPAddress.to_network(this.host_address, this.prefix.host_prefix()), this.prefix);
    }
    
    public static def BigInteger to_network(BigInteger adr, int host_prefix) {
        return adr.shiftRight(host_prefix).shiftLeft(host_prefix);
    }

    public def BigInteger sub(IPAddress other) {
        if (this.host_address.compareTo(other.host_address) >= 0) {
            return this.host_address.subtract(other.host_address);
        }
        return other.host_address.subtract(this.host_address);
    }

    public def List<IPAddress> add(IPAddress other) {
        return IPAddress.aggregate(#[this, other]);
    }

    public def List<String> to_s_vec(List<IPAddress> vec) {
        return vec.map[i| return i.to_s()];
    }

    public static def List<String> to_string_vec(List<IPAddress> vec) {
        return vec.map[i| return i.to_string()];
    }

    public static def Result<List<IPAddress> > to_ipaddress_vec(List<String> vec) {
        var ret = new Vector<IPAddress>()
        for (ipstr : vec) {
            val ipa = IPAddress.parse(ipstr);
            if (ipa.isErr()) {
                return Result.Err(ipa.unwrapErr());
            }
            ret.add(ipa.unwrap());
        }
        return Result.Ok(ret);
    }

    ///  Returns a new IPv4 object with the
    ///  first host IP address in the range.
    ///
    ///  Example: given the 192.168.100.0/24 network, the first
    ///  host IP address is 192.168.100.1.
    ///
    ///    ip = IPAddress("192.168.100.0/24")
    ///
    ///    ip.first.to_s
    ///      ///  "192.168.100.1"
    ///
    ///  The object IP doesn't need to be a network: the method
    ///  automatically gets the network number from it
    ///
    ///    ip = IPAddress("192.168.100.50/24")
    ///
    ///    ip.first.to_s
    ///      ///  "192.168.100.1"
    ///
    public def IPAddress first() {
        return this.from(this.network().host_address.add(this.ip_bits.host_ofs), this.prefix);
    }

    ///  Like its sibling method IPv4/// first, this method
    ///  returns a new IPv4 object with the
    ///  last host IP address in the range.
    ///
    ///  Example: given the 192.168.100.0/24 network, the last
    ///  host IP address is 192.168.100.254
    ///
    ///    ip = IPAddress("192.168.100.0/24")
    ///
    ///    ip.last.to_s
    ///      ///  "192.168.100.254"
    ///
    ///  The object IP doesn't need to be a network: the method
    ///  automatically gets the network number from it
    ///
    ///    ip = IPAddress("192.168.100.50/24")
    ///
    ///    ip.last.to_s
    ///      ///  "192.168.100.254"
    ///
    
    public def IPAddress last() {
        return this.from(this.broadcast().host_address.subtract(this.ip_bits.host_ofs), this.prefix);
    }

    ///  Iterates over all the hosts IP addresses for the given
    ///  network (or IP address).
    ///
    ///    ip = IPAddress("10.0.0.1/29")
    ///
    ///    ip.each_host do |i|
    ///      p i.to_s
    ///    end
    ///      ///  "10.0.0.1"
    ///      ///  "10.0.0.2"
    ///      ///  "10.0.0.3"
    ///      ///  "10.0.0.4"
    ///      ///  "10.0.0.5"
    ///      ///  "10.0.0.6"
    ///

    interface Each {
        def void Run(IPAddress ipa)
    }
    
    public def each_host(Each func) {
        var i = this.first().host_address;
        while (i.compareTo(this.last().host_address) <= 0) {
            func.Run(this.from(i, this.prefix));
            i = i.add(BigInteger.ONE);
        }
    }

    ///  Iterates over all the IP addresses for the given
    ///  network (or IP address).
    ///
    ///  The object yielded is a new IPv4 object created
    ///  from the iteration.
    ///
    ///    ip = IPAddress("10.0.0.1/29")
    ///
    ///    ip.each do |i|
    ///      p i.address
    ///    end
    ///      ///  "10.0.0.0"
    ///      ///  "10.0.0.1"
    ///      ///  "10.0.0.2"
    ///      ///  "10.0.0.3"
    ///      ///  "10.0.0.4"
    ///      ///  "10.0.0.5"
    ///      ///  "10.0.0.6"
    ///      ///  "10.0.0.7"
    ///
    
    public def each(Each func) {
        var i = this.network().host_address;
        while (i.compareTo(this.broadcast().host_address) <= 0) {
            func.Run(this.from(i, this.prefix));
            i = i.add(BigInteger.ONE);
        }
    }

    ///  Spaceship operator to compare IPv4 objects
    ///
    ///  Comparing IPv4 addresses is useful to ordinate
    ///  them into lists that match our intuitive
    ///  perception of ordered IP addresses.
    ///
    ///  The first comparison criteria is the u32 value.
    ///  For example, 10.100.100.1 will be considered
    ///  to be less than 172.16.0.1, because, in a ordered list,
    ///  we expect 10.100.100.1 to come before 172.16.0.1.
    ///
    ///  The second criteria, in case two IPv4 objects
    ///  have identical addresses, is the prefix. An higher
    ///  prefix will be considered greater than a lower
    ///  prefix. This is because we expect to see
    ///  10.100.100.0/24 come before 10.100.100.0/25.
    ///
    ///  Example:
    ///
    ///    ip1 = IPAddress "10.100.100.1/8"
    ///    ip2 = IPAddress "172.16.0.1/16"
    ///    ip3 = IPAddress "10.100.100.1/16"
    ///
    ///    ip1 < ip2
    ///      ///  true
    ///    ip1 > ip3
    ///      ///  false
    ///
    ///    [ip1,ip2,ip3].sort.map{|i| i.to_string}
    ///      ///  ["10.100.100.1/8","10.100.100.1/16","172.16.0.1/16"]
    ///
    ///  Returns the number of IP addresses included
    ///  in the network. It also counts the network
    ///  address and the broadcast address.
    ///
    ///    ip = IPAddress("10.0.0.1/29")
    ///
    ///    ip.size
    ///      ///  8
    ///
    
    public def BigInteger size() {
        return BigInteger.ONE.shiftLeft(this.prefix.host_prefix());
    }
    
    public def boolean is_same_kind(IPAddress oth) {
        return this.is_ipv4() == oth.is_ipv4() &&
        this.is_ipv6() == oth.is_ipv6();
    }

    ///  Checks whether a subnet includes the given IP address.
    ///
    ///  Accepts an IPAddress::IPv4 object.
    ///
    ///    ip = IPAddress("192.168.10.100/24")
    ///
    ///    addr = IPAddress("192.168.10.102/24")
    ///
    ///    ip.include? addr
    ///      ///  true
    ///
    ///    ip.include? IPAddress("172.16.0.48/16")
    ///      ///  false
    ///
    
    public def boolean includes(IPAddress oth) {
        val ret = this.is_same_kind(oth) &&
            this.prefix.num <= oth.prefix.num &&
            this.network().host_address.equals(IPAddress.to_network(oth.host_address, this.prefix.host_prefix()));
        // println!("includes:{}=={}=>{}", this.to_string(), oth.to_string(), ret);
        return ret
    }

    ///  Checks whether a subnet includes all the
    ///  given IPv4 objects.
    ///
    ///    ip = IPAddress("192.168.10.100/24")
    ///
    ///    addr1 = IPAddress("192.168.10.102/24")
    ///    addr2 = IPAddress("192.168.10.103/24")
    ///
    ///    ip.include_all?(addr1,addr2)
    ///      ///  true
    ///
    
    public def boolean includes_all(List<IPAddress> oths) {
        return oths.findFirst[oth| return !this.includes(oth) ] === null
    }
    
    ///  Checks if an IPv4 address objects belongs
    ///  to a private network RFC1918
    ///
    ///  Example:
    ///
    ///    ip = IPAddress "10.1.1.1/24"
    ///    ip.private?
    ///      ///  true
    ///
    
    public def boolean is_private() {
        return this.vt_is_private.run(this);
    }

    ///  Splits a network into different subnets
    ///
    ///  If the IP Address is a network, it can be divided into
    ///  multiple networks. If +self+ is not a network, this
    ///  method will calculate the network from the IP and then
    ///  subnet it.
    ///
    ///  If +subnets+ is an power of two number, the resulting
    ///  networks will be divided evenly from the supernet.
    ///
    ///    network = IPAddress("172.16.10.0/24")
    ///
    ///    network / 4   ///  implies map{|i| i.to_string}
    ///      ///  ["172.16.10.0/26",
    ///           "172.16.10.64/26",
    ///           "172.16.10.128/26",
    ///           "172.16.10.192/26"]
    ///
    ///  If +num+ is any other number, the supernet will be
    ///  divided into some networks with a even number of hosts and
    ///  other networks with the remaining addresses.
    ///
    ///    network = IPAddress("172.16.10.0/24")
    ///
    ///    network / 3   ///  implies map{|i| i.to_string}
    ///      ///  ["172.16.10.0/26",
    ///           "172.16.10.64/26",
    ///           "172.16.10.128/25"]
    ///
    ///  Returns an array of IPv4 objects
    ///
    
    public static def List<IPAddress> sum_first_found(List<IPAddress> arr)  {
        var dup = new Vector<IPAddress>(arr);
        if (dup.length() < 2) {
            return dup;
        }
        for (var i = dup.length()-2; i >= 0; i--) {
            val a = IPAddress.summarize(#[dup.get(i), dup.get(i + 1)]);
            // println!("dup:{}:{}:{}", dup.len(), i, a.len());
            if (a.length() == 1) {
                dup.set(i,  a.get(0))
                dup.remove(i+1);
                return dup
            }
        }
        return dup;
    }
    
    public def Result<List<IPAddress>> split(int subnets) {
        if (subnets == 0 || (1 << this.prefix.host_prefix()) <= subnets) {
            return Result.Err('''Value <<subnets>> out of range''');
        }
        val networks = this.subnet(this.newprefix(subnets).unwrap().num);
        if (networks.isErr()) {
            return networks;
        }
        var net = networks.unwrap();
        while (net.length() != subnets) {
            net = IPAddress.sum_first_found(net);
        }
        return Result.Ok(net);
    }

    ///  Returns a new IPv4 object from the supernetting
    ///  of the instance network.
    ///
    ///  Supernetting is similar to subnetting, except
    ///  that you getting as a result a network with a
    ///  smaller prefix (bigger host space). For example,
    ///  given the network
    ///
    ///    ip = IPAddress("172.16.10.0/24")
    ///
    ///  you can supernet it with a new /23 prefix
    ///
    ///    ip.supernet(23).to_string
    ///      ///  "172.16.10.0/23"
    ///
    ///  However if you supernet it with a /22 prefix, the
    ///  network address will change:
    ///
    ///    ip.supernet(22).to_string
    ///      ///  "172.16.8.0/22"
    ///
    ///  If +new_prefix+ is less than 1, returns 0.0.0.0/0
    ///
    
    public def Result<IPAddress> supernet(int new_prefix)  {
        if (new_prefix >= this.prefix.num) {
            return Result.Err('''New prefix must be smaller than existing prefix: <<new_prefix>> >= <<this.prefix.num)>>''')
        }
        // let mut new_ip = this.host_address.clone();
        // for _ in new_prefix..this.prefix.num {
        //     new_ip = new_ip << 1;
        // }
        return Result.Ok(this.from(this.host_address, this.prefix.from(new_prefix).unwrap()).network());
    }

    ///  This method implements the subnetting function
    ///  similar to the one described in RFC3531.
    ///
    ///  By specifying a new prefix, the method calculates
    ///  the network number for the given IPv4 object
    ///  and calculates the subnets associated to the new
    ///  prefix.
    ///
    ///  For example, given the following network:
    ///
    ///    ip = IPAddress "172.16.10.0/24"
    ///
    ///  we can calculate the subnets with a /26 prefix
    ///
    ///    ip.subnets(26).map(&:to_string)
    ///      ///  ["172.16.10.0/26", "172.16.10.64/26",
    ///           "172.16.10.128/26", "172.16.10.192/26"]
    ///
    ///  The resulting number of subnets will of course always be
    ///  a power of two.
    ///

    
    public def Result<List<IPAddress>> subnet(int subprefix) {
        if (subprefix < this.prefix.num || this.ip_bits.bits < subprefix) {
            return Result.Err('''New prefix must be between prefix<<this.prefix.num>> <<subprefix>> and <<this.ip_bits.bits>>''')
        }
        var ret = new Vector<IPAddress>();
        var net = this.network();
        var prefix = net.prefix.from(subprefix).unwrap();
        var host_address = net.host_address
        for (var _ = 0; _ < (1 << (subprefix - this.prefix.num)); _++) {
            net = net.from(host_address, prefix);
            ret.add(net);
            val size = net.size();
            host_address = host_address.add(size);
        }
        return Result.Ok(ret);
    }



    ///  Return the ip address in a format compatible
    ///  with the IPv6 Mapped IPv4 addresses
    ///
    ///  Example:
    ///
    ///    ip = IPAddress("172.16.10.1/24")
    ///
    ///    ip.to_ipv6
    ///      ///  "ac10:0a01"
    ///
    
    public def IPAddress to_ipv6() {
        return this.vt_to_ipv6.run(this);
    }


    //  private methods
    //
    
    public def Result<Prefix> newprefix(int num) {
        for (var i = num; i < this.ip_bits.bits; i++) {
            var a = Math.floor(Math.log(i)/Math.log(2))
            if (a == Math.log(i)/Math.log(2)) {
                return this.prefix.add(a as int);
            }
        }
        return Result.Err('''newprefix not found <<num>>,<<this.ip_bits.bits>>''');
    }

    public static def Integer parseInt(String s, int radix) {
        try {
            return Integer.valueOf(s, radix);
        } catch (NumberFormatException n) {
            return null;
        }
    }
  


}
