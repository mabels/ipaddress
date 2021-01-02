package com.adviser.ipaddress.kotlin

import java.math.BigInteger
import java.util.regex.Pattern

val RE_MAPPED = Pattern.compile(":.+\\.")!!
val RE_IPV4 = Pattern.compile("\\.")!!
val RE_IPV6 = Pattern.compile(":")!!


typealias VtBool = (ipa: IPAddress) -> Boolean
typealias VtIPAddress = (ipa: IPAddress) -> IPAddress
typealias Each = (ipa: IPAddress) -> Unit

class IPAddress(
        val ip_bits: IpBits,
        val host_address: BigInteger,
        val prefix: Prefix,
        val mapped: IPAddress?,
        private val vt_is_private: VtBool,
        private val vt_is_loopback: VtBool,
        private val vt_to_ipv6: VtIPAddress) {

    override fun toString(): String {
        return "IPAddress:${this.to_string()}@${this.hashCode()}"
    }

    fun clone(): IPAddress {
        return if (mapped === null) {
            this.setMapped(null)
        } else {
            this.setMapped(this.mapped.clone())
        }
    }

    fun from(addr: BigInteger, prefix: Prefix): IPAddress {
        var map: IPAddress? = null
        if (this.mapped != null) {
            map = this.mapped.clone()
        }
        return setMapped(addr, map, prefix.clone())
    }

    fun setMapped(mapped: IPAddress?): IPAddress {
        return setMapped(this.host_address, mapped, this.prefix.clone())
    }

    fun setMapped(hostAddr: BigInteger, mapped: IPAddress?, prefix: Prefix): IPAddress {
        return IPAddress(
                this.ip_bits,
                BigInteger.ZERO.add(hostAddr),
                prefix,
                mapped,
                this.vt_is_private,
                this.vt_is_loopback,
                this.vt_to_ipv6)
    }

    override fun equals(other: Any?): Boolean {
        if (other == null) {
            return false
        }
        if (!(other is IPAddress)) {
            return false
        }
        return this.compare(other) == 0
    }


    override fun hashCode(): Int {
        return super.hashCode()
    }

    fun compare(oth: IPAddress): Int {
        if (this.ip_bits.version != oth.ip_bits.version) {
            if (this.ip_bits.version == IpVersion.V6) {
                return 1
            }
            return -1
        }
        //let adr_diff = this.host_address - oth.host_address
        val comp = this.host_address.compareTo(oth.host_address)
        if (comp < 0) {
            return -1
        } else if (comp > 0) {
            return 1
        }
        return this.prefix.compare(oth.prefix)
    }

    fun equal(other: IPAddress?): Boolean {
        if (other == null) {
            return false
        }
        return this.ip_bits.version == other.ip_bits.version &&
                this.prefix.equal(other.prefix) &&
                this.host_address.equals(other.host_address) &&
                ((this.mapped == null && this.mapped == other.mapped) ||
                        (this.mapped != null && this.mapped.equal(other.mapped)))
    }

    fun lt(ipa: IPAddress): Boolean {
        return this.compare(ipa) < 0
    }

    fun gt(ipa: IPAddress): Boolean {
        return this.compare(ipa) > 0
    }

    companion object {
        fun sort(ipas: List<IPAddress>): MutableList<IPAddress> {
            var ret = ipas.toMutableList()
            ret.sortWith(Comparator { a, b -> a.compare(b); })
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
        fun parse(str: String): Result<IPAddress> {
            if (RE_MAPPED.matcher(str).find()) {
                // println!("mapped:{}", &str)
                return Ipv6Mapped.create(str)
            } else {
                if (RE_IPV4.matcher(str).find()) {
                    // println!("ipv4:{}", &str)
                    return IpV4.create(str)
                } else if (RE_IPV6.matcher(str).find()) {
                    // println!("ipv6:{}", &str)
                    return IpV6.create(str)
                }
            }
            return Result.Err("Unknown IP Address ${str}")
        }


        fun split_at_slash(str: String): AddrNetmask {
            val slash = str.trim().split("/")
            var addr = ""
            if (slash.size >= 1) {
                addr = slash.get(0).trim()
            }
            if (slash.size >= 2) {
                return AddrNetmask(addr, slash.get(1).trim())
            } else {
                return AddrNetmask(addr, null)
            }
        }

        class AddrNetmask(val addr: String, val netmask: String?) {
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
        fun is_valid(addr: String): Boolean {
            return is_valid_ipv4(addr) || is_valid_ipv6(addr)
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
        fun parse_ipv4_part(i: String, addr: String): Result<Int> {
            try {
                val part = Integer.valueOf(i)
                if (part.toInt() >= 256) {
                    return Result.Err("IP items has to lower than 256. ${addr}")
                }
                return Result.Ok(part.toInt())
            } catch (e: NumberFormatException) {
                return Result.Err("IP must contain numbers ${addr}")
            }
        }

        fun split_to_u32(addr: String): Result<Long> {
            var ip = 0L
            var shift = 24
            var split_addr = addr.split("."); //.collect::<Vec<&str>>()
            if (split_addr.size > 4) {
                return Result.Err("IP has not the right format:${addr}")
            }
            val split_addr_len = split_addr.size
            if (split_addr_len < 4) {
                val part = parse_ipv4_part(split_addr.get(split_addr_len - 1), addr)
                if (part.isErr()) {
                    return Result.Err(part.unwrapErr())
                }
                ip = part.unwrap().toLong()
                split_addr = split_addr.slice(0 until split_addr_len - 1)
            }
            for (i in split_addr) {
                val part = parse_ipv4_part(i, addr)
                if (part.isErr()) {
                    return Result.Err(part.unwrapErr())
                }
                // println!("{}-{}", part_num, shift)
                ip = ip.or(part.unwrap().toLong().shl(shift))
                shift -= 8
            }
            return Result.Ok(ip)
        }

        fun is_valid_ipv4(addr: String): Boolean {
            return split_to_u32(addr).isOk()
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
        class SplitOnColon(val ip: BigInteger, val size: Int) {
        }

        fun split_on_colon(addr: String): Result<SplitOnColon> {
            val parts = addr.trim().split(":")
            var ip = BigInteger.ZERO
            if (parts.size == 1 && parts.get(0).isEmpty()) {
                return Result.Ok(SplitOnColon(ip, 0))
            }
            val parts_len = parts.size
            var shift = ((parts_len - 1) * 16)
            for (i in parts) {
                //println!("{}={}", addr, i)
                val part = parseInt(i, 16)
                if (part === null) {
                    return Result.Err("IP must contain hex numbers ${addr}-${i}")
                }
                val part_num = part
                if (part_num >= 65536) {
                    return Result.Err("IP items has to lower than 65536. ${addr}")
                }
                ip = ip.add(BigInteger.valueOf(part_num.toLong()).shiftLeft(shift))
                shift -= 16
            }
            return Result.Ok(SplitOnColon(ip, parts_len))
        }

        fun split_to_num(addr: String): Result<BigInteger> {
            var pre_post = addr.trim().split("::").toMutableList()
            if (pre_post.isEmpty() && addr.contains("::")) {
                //pre_post = Arrays.copyOf(pre_post, pre_post.size + 1)
                //pre_post.set(pre_post.size - 1, "")
                pre_post.add("")
            }
            if (pre_post.size == 1 && addr.contains("::")) {
                // pre_post = Arrays.copyOf(pre_post, pre_post.size + 1)
                // pre_post.set(pre_post.size - 1, "")
                pre_post.add("")
            }
            if (pre_post.size > 2) {
                return Result.Err("IPv6 only allow one :: ${addr}")
            }
            if (pre_post.size == 2) {
                //println!("{}=::={}", pre_post[0], pre_post[1])
                val pre = split_on_colon(pre_post.get(0))
                if (pre.isErr()) {
                    return Result.Err(pre.unwrapErr())
                }
                val post = split_on_colon(pre_post.get(1))
                if (post.isErr()) {
                    return Result.Err(post.unwrapErr())
                }
                // println!("pre:{} post:{}", pre_parts, post_parts)
                return Result.Ok((pre.unwrap().ip.shiftLeft(128 - (pre.unwrap().size * 16))).add(post.unwrap().ip))
            }
            //println!("split_to_num:no double:{}", addr)
            val ret = split_on_colon(addr)
            if (ret.isErr() || ret.unwrap().size != 128 / 16) {
                return Result.Err("incomplete IPv6")
            }
            return Result.Ok(ret.unwrap().ip)
        }

        fun is_valid_ipv6(addr: String): Boolean {
            return split_to_num(addr).isOk()
        }


        /// private helper for summarize
        /// assumes that networks is output from reduce_networks
        /// means it should be sorted lowers first and uniq
        ///

        fun pos_to_idx(pos: Int, len: Int): Int {
            val ilen = len //as isize
            // let ret = pos % ilen
            val rem = ((pos % ilen) + ilen) % ilen
            // println!("pos_to_idx:{}:{}=>{}:{}", pos, len, ret, rem)
            return rem
        }

        fun aggregate(networks: List<IPAddress>): List<IPAddress> {
            if (networks.isEmpty()) {
                return emptyList<IPAddress>()
            }
            if (networks.size == 1) {
                return listOf(networks.get(0).network())
            }
            val stack = sort(networks.map { i -> i.network() })

            // for i in 0..networks.len() {
            //     println!("{}==={}", &networks[i].to_string_uncompressed(),
            //         &stack[i].to_string_uncompressed())
            // }
            var pos = 0
            while (true) {
                if (pos < 0) {
                    pos = 0
                }
                val stack_len = stack.size; // borrow checker
                // println!("loop:{}:{}", pos, stack_len)
                // if stack_len == 1 {
                //     println!("exit 1")
                //     break
                // }
                if (pos >= stack_len) {
                    // println!("exit first:{}:{}", stack_len, pos)
                    return stack//.map[i| return i.network()]
                }
                val first = pos_to_idx(pos, stack_len)
                pos = pos + 1
                if (pos >= stack_len) {
                    // println!("exit second:{}:{}", stack_len, pos)
                    return stack//.map[i| return i.network()]
                }
                val second = pos_to_idx(pos, stack_len)
                pos = pos + 1
                //let mut firstUnwrap = first.unwrap()
                if (stack.get(first).includes(stack.get(second))) {
                    pos = pos - 2
                    // println!("remove:1:{}:{}:{}=>{}", first, second, stack_len, pos + 1)
                    stack.removeAt(pos_to_idx(pos + 1, stack_len))
                } else {
                    val ipFirst = stack.get(first)
                    stack.set(first, ipFirst.change_prefix(ipFirst.prefix.sub(1).unwrap()).unwrap())
                    // println!("complex:{}:{}:{}:{}:P1:{}:P2:{}", pos, stack_len,
                    // first, second,
                    // stack[first].to_string(), stack[second].to_string())
                    if ((stack.get(first).prefix.num + 1) == stack.get(second).prefix.num &&
                            stack.get(first).includes(stack.get(second))) {
                        pos = pos - 2
                        val idx = pos_to_idx(pos, stack_len)
                        stack.set(idx, stack.get(first).clone()); // kaputt
                        stack.removeAt(pos_to_idx(pos + 1, stack_len))
                        // println!("remove-2:{}:{}", pos + 1, stack_len)
                        pos = pos - 1; // backtrack
                    } else {
                        val myFirst = stack.get(first)
                        stack.set(first, myFirst.change_prefix(myFirst.prefix.add(1).unwrap()).unwrap()); //reset prefix
                        // println!("easy:{}:{}=>{}", pos, stack_len, stack[first].to_string())
                        pos = pos - 1; // do it with second as first
                    }
                }
            }
            // println!("agg={}:{}", pos, stack.len())
            //

        }

        fun summarize_str(netstr: List<String>): Result<List<IPAddress>> {
            val vec = to_ipaddress_vec(netstr)
            if (vec.isErr()) {
                return vec
            }
            return Result.Ok(aggregate(vec.unwrap()))
        }

        fun parseInt(s: String, radix: Int): Int? {
            try {
                return Integer.valueOf(s, radix)
            } catch (n: NumberFormatException) {
                return null
            }
        }

        fun sum_first_found(arr: List<IPAddress>): List<IPAddress> {
            var dup = arr.toMutableList()
            if (dup.size < 2) {
                return dup
            }
            for (i in (dup.size - 2) downTo 0) {
                val a = summarize(listOf(dup.get(i), dup.get(i + 1)))
                // println!("dup:{}:{}:{}", dup.len(), i, a.len())
                if (a.size == 1) {
                    dup.set(i, a.get(0))
                    dup.removeAt(i + 1)
                    return dup
                }
            }
            return dup
        }

        fun to_string_vec(vec: List<IPAddress>): List<String> {
            return vec.map { i -> i.to_string() }
        }

        fun to_ipaddress_vec(vec: List<String>): Result<List<IPAddress>> {
            var ret = mutableListOf<IPAddress>()
            for (ipstr in vec) {
                val ipa = parse(ipstr)
                if (ipa.isErr()) {
                    return Result.Err(ipa.unwrapErr())
                }
                ret.add(ipa.unwrap())
            }
            return Result.Ok(ret)
        }

        /// Checks if the argument is a valid IPv4 netmask
        /// expressed in dotted decimal format.
        ///
        ///   IPAddress.valid_ipv4_netmask? "255.255.0.0"
        ///     ///  true
        ///

        fun is_valid_netmask(addr: String): Boolean {
            return parse_netmask_to_prefix(addr).isOk()
        }

        fun netmask_to_prefix(nm: BigInteger, bits: Int): Result<Int> {
            var prefix = 0
            var addr = BigInteger.ZERO.add(nm)
            var in_host_part = true
            val two = BigInteger.valueOf(2)
            for (i in 0 until bits) {
                val bit = addr.mod(two).intValueExact()
                if (in_host_part && bit == 0) {
                    prefix = prefix + 1
                } else if (in_host_part && bit == 1) {
                    in_host_part = false
                } else if (!in_host_part && bit == 0) {
                    return Result.Err("this is not a net mask ${nm}")
                }
                addr = addr.shiftRight(1)
            }
            return Result.Ok(bits - prefix)
        }


        fun parse_netmask_to_prefix(my_str: String): Result<Int> {
            val is_number = parseInt(my_str, 10)
            if (is_number !== null) {
                return Result.Ok(is_number)
            }
            val my = parse(my_str)
            if (my.isErr()) {
                return Result.Err("illegal netmask ${my.unwrapErr()}")
            }
            val my_ip = my.unwrap()
            return netmask_to_prefix(my_ip.host_address, my_ip.ip_bits.bits)
        }

        fun to_network(adr: BigInteger, host_prefix: Int): BigInteger {
            return adr.shiftRight(host_prefix).shiftLeft(host_prefix)
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
        ///    original networks
        /// 2) The aggregate network must contain +only+ the IP addresses of the
        ///    original networks
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
        ///     original networks
        ///  2) The aggregate network must contain +only+ the IP addresses of the
        ///     original networks
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

        fun summarize(networks: List<IPAddress>): List<IPAddress> {
            return aggregate(networks)
        }

    }

    /// True if the object is an IPv4 address
    ///
    ///   ip = IPAddress("192.168.10.100/24")
    ///
    ///   ip.ipv4?
    ///     //-> true
    ///
    fun is_ipv4(): Boolean {
        return this.ip_bits.version == IpVersion.V4
    }

    /// True if the object is an IPv6 address
    ///
    ///   ip = IPAddress("192.168.10.100/24")
    ///
    ///   ip.ipv6?
    ///     //-> false
    ///
    fun is_ipv6(): Boolean {
        return this.ip_bits.version == IpVersion.V6
    }

    fun parts(): IntArray {
        return this.ip_bits.parts(this.host_address)
    }

    fun parts_hex_str(): Array<String> {
        val parts = this.parts()
        val ret = arrayListOf<String>()
        for (i in 0 until parts.size) {
            ret.add(String.format("%04x", parts.get(i)))
        }
        return ret.toTypedArray()
    }

    ///  Returns the IP address in in-addr.arpa format
    ///  for DNS Domain definition entries like SOA Records
    ///
    ///    ip = IPAddress("172.17.100.50/15")
    ///
    ///    ip.dns_rev_domains
    ///      // => ["16.172.in-addr.arpa","17.172.in-addr.arpa"]
    ///
    fun dns_rev_domains(): Array<String> {
        val dns_networks = this.dns_networks()
        val ret = arrayListOf<String>()
        for (i in 0 until dns_networks.size) {
            // println!("dns_rev_domains:{}:{}", this.to_string(), net.to_string())
            ret.add(dns_networks.get(i).dns_reverse())
        }
        return ret.toTypedArray()
    }


    fun dns_reverse(): String {
        val ret = StringBuilder()
        var dot = ""
        val dns_parts = this.dns_parts()
        for (i in ((this.prefix.host_prefix() + (this.ip_bits.dns_bits - 1)) / this.ip_bits.dns_bits) until dns_parts.size) {
            ret.append(dot)
            ret.append(this.ip_bits.dns_part_format(dns_parts.get(i)))
            dot = "."
        }
        ret.append(dot)
        ret.append(this.ip_bits.rev_domain)
        return ret.toString()
    }


    fun dns_parts(): IntArray {
        val len = this.ip_bits.bits / this.ip_bits.dns_bits
        var ret = IntArray(len)
        var num = BigInteger.ZERO.add(this.host_address)
        val mask = BigInteger.ONE.shiftLeft(this.ip_bits.dns_bits)
        for (i in 0 until len) {
            var part = num.mod(mask)
            num = num.shiftRight(this.ip_bits.dns_bits)
            ret.set(i, part.intValueExact())
        }
        return ret
    }

    fun dns_networks(): Array<IPAddress> {
        // +this.ip_bits.dns_bits-1
        val next_bit_mask = this.ip_bits.bits -
                (((this.prefix.host_prefix()) / this.ip_bits.dns_bits) * this.ip_bits.dns_bits)
        if (next_bit_mask <= 0) {
            return arrayOf(this.network())
        }
        //  println!("dns_networks:{}:{}", this.to_string(), next_bit_mask)
        // dns_bits
        val step_bit_net = BigInteger.ONE.shiftLeft(this.ip_bits.bits - next_bit_mask)
        if (step_bit_net.equals(BigInteger.ZERO)) {
            return arrayOf(this.network())
        }
        val ret = arrayListOf<IPAddress>()
        var step = this.network().host_address
        val prefix = this.prefix.from(next_bit_mask).unwrap()
        while (step.compareTo(this.broadcast().host_address) <= 0) {
            ret.add(this.from(step, prefix))
            step = step.add(step_bit_net)
        }
        return ret.toTypedArray()
    }


    fun ip_same_kind(oth: IPAddress): Boolean {
        return this.ip_bits.version == oth.ip_bits.version
    }

    ///  Returns true if the address is an unspecified address
    ///
    ///  See IPAddress::IPv6::Unspecified for more information
    ///

    fun is_unspecified(): Boolean {
        return this.host_address.equals(BigInteger.ZERO)
    }

    ///  Returns true if the address is a loopback address
    ///
    ///  See IPAddress::IPv6::Loopback for more information
    ///

    fun is_loopback(): Boolean {
        return this.vt_is_loopback(this)
    }


    ///  Returns true if the address is a mapped address
    ///
    ///  See IPAddress::IPv6::Mapped for more information
    ///

    fun is_mapped(): Boolean {
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

    fun prefix(): Prefix {
        return this.prefix
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
    fun change_prefix(prefix: Prefix): Result<IPAddress> {
        return Result.Ok(this.from(this.host_address, prefix))
    }

    fun change_prefix(num: Int): Result<IPAddress> {
        val prefix = this.prefix.from(num)
        if (prefix.isErr()) {
            return Result.Err(prefix.unwrapErr())
        }
        return Result.Ok(this.from(this.host_address, prefix.unwrap()))
    }

    fun change_netmask(my_str: String): Result<IPAddress> {
        val nm = parse_netmask_to_prefix(my_str)
        if (nm.isErr()) {
            return Result.Err(nm.unwrapErr())
        }
        return this.change_prefix(nm.unwrap())
    }


    ///  Returns a string with the IP address in canonical
    ///  form.
    ///
    ///    ip = IPAddress("172.16.100.4/22")
    ///
    ///    ip.to_string
    ///      ///  "172.16.100.4/22"
    ///
    fun to_string(): String {
        var ret = StringBuilder()
        ret.append(this.to_s())
        ret.append("/")
        ret.append(this.prefix.to_s())
        return ret.toString()
    }

    fun to_s(): String {
        return this.ip_bits.as_compressed_string(this.host_address)
    }

    fun to_string_uncompressed(): String {
        val ret = StringBuilder()
        ret.append(this.to_s_uncompressed())
        ret.append("/")
        ret.append(this.prefix.to_s())
        return ret.toString()
    }

    fun to_s_uncompressed(): String {
        return this.ip_bits.as_uncompressed_string(this.host_address)
    }


    fun to_s_mapped(): String {
        if (this.is_mapped()) {
            return String.format("%s%s", "::ffff:", this.mapped!!.to_s())
        }
        return this.to_s()
    }

    fun to_string_mapped(): String {
        if (this.is_mapped()) {
            val mapped = this.mapped!!
            return String.format("%s/%d", this.to_s_mapped(), mapped.prefix.num)
        }
        return this.to_string()
    }


    ///  Returns the address portion of an IP in binary format,
    ///  as a string containing a sequence of 0 and 1
    ///
    ///    ip = IPAddress("127.0.0.1")
    ///
    ///    ip.bits
    ///      ///  "01111111000000000000000000000001"
    ///

    fun bits(): String {
        val num = this.host_address.toString(2)
        var ret = StringBuilder()
        for (i in num.length until this.ip_bits.bits) {
            ret.append("0")
        }
        ret.append(num)
        return ret.toString()
    }

    fun to_hex(): String {
        return this.host_address.toString(16)
    }

    fun netmask(): IPAddress {
        return this.from(this.prefix.netmask(), this.prefix)
    }

    ///  Returns the broadcast address for the given IP.
    ///
    ///    ip = IPAddress("172.16.10.64/24")
    ///
    ///    ip.broadcast.to_s
    ///      ///  "172.16.10.255"
    ///

    fun broadcast(): IPAddress {
        val bcast = this.network().host_address.add(this.size()).subtract(BigInteger.ONE)
        return this.from(bcast, this.prefix)
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

    fun is_network(): Boolean {
        return this.prefix.num != this.ip_bits.bits &&
                this.host_address.equals(this.network().host_address)
    }

    ///  Returns a new IPv4 object with the network number
    ///  for the given IP.
    ///
    ///    ip = IPAddress("172.16.10.64/24")
    ///
    ///    ip.network.to_s
    ///      ///  "172.16.10.0"
    ///

    fun network(): IPAddress {
        return this.from(to_network(this.host_address, this.prefix.host_prefix()), this.prefix)
    }


    fun sub(other: IPAddress): BigInteger {
        if (this.host_address.compareTo(other.host_address) >= 0) {
            return this.host_address.subtract(other.host_address)
        }
        return other.host_address.subtract(this.host_address)
    }

    fun add(other: IPAddress): List<IPAddress> {
        return aggregate(listOf(this, other))
    }

    fun to_s_vec(vec: List<IPAddress>): List<String> {
        return vec.map { i -> i.to_s() }
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
    fun first(): IPAddress {
        return this.from(this.network().host_address.add(this.ip_bits.host_ofs), this.prefix)
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

    fun last(): IPAddress {
        return this.from(this.broadcast().host_address.subtract(this.ip_bits.host_ofs), this.prefix)
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


    fun each_host(func: Each) {
        var i = this.first().host_address
        while (i.compareTo(this.last().host_address) <= 0) {
            func(this.from(i, this.prefix))
            i = i.add(BigInteger.ONE)
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

    fun each(func: Each) {
        var i = this.network().host_address
        while (i.compareTo(this.broadcast().host_address) <= 0) {
            func(this.from(i, this.prefix))
            i = i.add(BigInteger.ONE)
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

    fun size(): BigInteger {
        return BigInteger.ONE.shiftLeft(this.prefix.host_prefix())
    }

    fun is_same_kind(oth: IPAddress): Boolean {
        return this.is_ipv4() == oth.is_ipv4() &&
                this.is_ipv6() == oth.is_ipv6()
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

    fun includes(oth: IPAddress): Boolean {
        val ret = this.is_same_kind(oth) &&
                this.prefix.num <= oth.prefix.num &&
                this.network().host_address.equals(to_network(oth.host_address, this.prefix.host_prefix()))
        // println!("includes:{}=={}=>{}", this.to_string(), oth.to_string(), ret)
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

    fun includes_all(oths: Array<IPAddress>): Boolean {
        return oths.find { oth: IPAddress -> !this.includes(oth) } == null
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

    fun is_private(): Boolean {
        return this.vt_is_private(this)
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


    fun split(subnets: Int): Result<List<IPAddress>> {
        if (subnets == 0 || (1.shl(this.prefix.host_prefix())) <= subnets) {
            return Result.Err("Value ${subnets} out of range")
        }
        val networks = this.subnet(this.newprefix(subnets).unwrap().num)
        if (networks.isErr()) {
            return networks
        }
        var net = networks.unwrap()
        while (net.size != subnets) {
            net = sum_first_found(net)
        }
        return Result.Ok(net)
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

    fun supernet(new_prefix: Int): Result<IPAddress> {
        if (new_prefix >= this.prefix.num) {
            return Result.Err("New prefix must be smaller than existing prefix: ${new_prefix} >= ${this.prefix.num}")
        }
        // let mut new_ip = this.host_address.clone()
        // for _ in new_prefix..this.prefix.num {
        //     new_ip = new_ip << 1
        // }
        return Result.Ok(this.from(this.host_address, this.prefix.from(new_prefix).unwrap()).network())
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


    fun subnet(subprefix: Int): Result<List<IPAddress>> {
        if (subprefix < this.prefix.num || this.ip_bits.bits < subprefix) {
            return Result.Err("New prefix must be between prefix${this.prefix.num} ${subprefix} and ${this.ip_bits.bits}")
        }
        val ret = arrayListOf<IPAddress>()
        var net = this.network()
        val prefix = net.prefix.from(subprefix).unwrap()
        var host_address = net.host_address
        for (i in 0 until (1.shl(subprefix - this.prefix.num))) {
            net = net.from(host_address, prefix)
            ret.add(net)
            val size = net.size()
            host_address = host_address.add(size)
        }
        return Result.Ok(ret)
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

    fun to_ipv6(): IPAddress {
        return this.vt_to_ipv6(this)
    }


    //  private methods
    //

    fun newprefix(num: Int): Result<Prefix> {
        for (i in num until this.ip_bits.bits) {
            var a = Math.floor(Math.log(i.toDouble()) / Math.log(2.0))
            if (a == Math.log(i.toDouble()) / Math.log(2.0)) {
                return this.prefix.add(a.toInt())
            }
        }
        return Result.Err("newprefix not found ${num},${this.ip_bits.bits}")
    }


}
