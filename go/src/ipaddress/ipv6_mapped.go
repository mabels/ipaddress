package ipaddress

import "fmt"
import "strings"
import "bytes"
import "math/big"

import "../ip_bits"

// import "ipaddress"

//  Ac
///  It is usually identified as a IPv4 mapped IPv6 address, a particular
///  IPv6 address which aids the transition from IPv4 to IPv6. The
///  structure of the address is
///
///    ::ffff:w.y.x.z
///
///  where w.x.y.z is a normal IPv4 address. For example, the following is
///  a mapped IPv6 address:
///
///    ::ffff:192.168.100.1
///
///  IPAddress is very powerful in handling mapped IPv6 addresses, as the
///  IPv4 portion is stored internally as a normal IPv4 object. Let's have
///  a look at some examples. To create a new mapped address, just use the
///  class builder itself
///
///    ip6 = IPAddress::IPv6::Mapped.new "::ffff:172.16.10.1/128"
///
///  or just use the wrapper method
///
///    ip6 = IPAddress "::ffff:172.16.10.1/128"
///
///  Let's check it's really a mapped address:
///
///    ip6.mapped?
///      ///  true
///
///    ip6.to_string
///      ///  "::FFFF:172.16.10.1/128"
///
///  Now with the +ipv4+ attribute, we can easily access the IPv4 portion
///  of the mapped IPv6 address:
///
///    ip6.ipv4.address
///      ///  "172.16.10.1"
///
///  Internally, the IPv4 address is stored as two 16 bits
///  groups. Therefore all the usual methods for an IPv6 address are
///  working perfectly fine:
///
///    ip6.to_hex
///      ///  "00000000000000000000ffffac100a01"
///
///    ip6.address
///      ///  "0000:0000:0000:0000:0000:ffff:ac10:0a01"
///
///  A mapped IPv6 can also be created just by specify the address in the
///  following format:
///
///    ip6 = IPAddress "::172.16.10.1"
///
///  That is, two colons and the IPv4 address. However, as by RFC, the ffff
///  group will be automatically added at the beginning
///
///    ip6.to_string
///      => "::ffff:172.16.10.1/128"
///
///  making it a mapped IPv6 compatible address.
///
///
///  Creates a new IPv6 IPv4-mapped address
///
///    ip6 = IPAddress::IPv6::Mapped.new "::ffff:172.16.10.1/128"
///
///    ipv6.ipv4.class
///      ///  IPAddress::IPv4
///
///  An IPv6 IPv4-mapped address can also be created using the
///  IPv6 only format of the address:
///
///    ip6 = IPAddress::IPv6::Mapped.new "::0d01:4403"
///
///    ip6.to_string
///      ///  "::ffff:13.1.68.3"
///
func Ipv6MappedNew(str string) ResultIPAddress {
    ip, o_netmask := Split_at_slash(str);
    split_colon := strings.Split(ip, ":");
    if len(split_colon) <= 1 {
        // fmt.Printf("---1");
        tmp := fmt.Sprintf("not mapped format-1: %s", str);
        fmt.Printf("Ipv6MappedNew-1:%s\n", tmp)
        return &Error{&tmp}
    }
    // if split_colon.get(0).Unwrap().len() > 0 {
    //     // fmt.Printf("---1a");
    //     return Err(format!("not mapped format-2: {}", string));
    // }
    // let mapped: Option<IPAddress> = None;
    netmask := "";
    if o_netmask != nil {
        netmask = fmt.Sprintf("/%s", o_netmask);
    }
    ipv4_str := split_colon[len(split_colon)-1]
    if Is_valid_ipv4(ipv4_str) {
        ipv4_str = fmt.Sprintf("%s%s", ipv4_str, netmask)
        ipv4 := Parse(ipv4_str);
        if ipv4.IsErr()  {
            // fmt.Printf("Ipv6MappedNew-2:%s\n")
            return ipv4;
        }
        //mapped = Some(ipv4.Unwrap());
        addr := ipv4.Unwrap();
        ipv6_bits := ip_bits.V6();
        part_mod := ipv6_bits.Part_mod;
        up_addr := *big.NewInt(0).Set(&addr.Host_address);
        down_addr := *big.NewInt(0).Set(&addr.Host_address);

        var rebuild_ipv6 bytes.Buffer
        colon := "";
        for i := 0 ; i < len(split_colon)-1; i++ {
            rebuild_ipv6.WriteString(colon);
            rebuild_ipv6.WriteString(split_colon[i]);
            colon = ":";
        }
        rebuild_ipv6.WriteString(colon);
        // fmt.Printf("1-UP:%s\n", up_addr.String())
        shr := up_addr.Rsh(&up_addr, uint(ip_bits.V6().Part_bits))
        // fmt.Printf("UP:%s:SHR:%s\n", up_addr.String(), shr.String())
        // fmt.Printf("DOWN:%s\n", down_addr.String())
        rebuild_ipv4 := fmt.Sprintf("%x:%x/%d",
            shr.Rem(shr, &part_mod).Uint64(),
            down_addr.Rem(&down_addr, &part_mod).Uint64(),
            ipv6_bits.Bits-addr.Prefix.Host_prefix());
        rebuild_ipv6.WriteString(rebuild_ipv4);
        rebuild_ipv6_str := rebuild_ipv6.String()
        r_ipv6 := Parse(rebuild_ipv6_str);
        if r_ipv6.IsErr() {
            // fmt.Printf("---3|{}", &rebuild_ipv6);
            // fmt.Printf("Ipv6MappedNew-3\n")
            return r_ipv6
        }
        if r_ipv6.Unwrap().Is_mapped() {
            // fmt.Printf("Ipv6MappedNew-4\n")
            return r_ipv6
        }
        ipv6 := r_ipv6.Unwrap();
        p96bit := big.NewInt(0).Rsh(&ipv6.Host_address, 32);
        if big.NewInt(0).Cmp(p96bit) != 0 {
            // fmt.Printf("---4|%s", &rebuild_ipv6);
            tmp := fmt.Sprintf("is not a mapped address:%s", rebuild_ipv6);
            // fmt.Printf("Ipv6MappedNew-5:%s:%s\n", tmp, p96bit.String())
            return &Error{&tmp}
        }
        {
            ipv6_ipv4_str := fmt.Sprintf("::ffff:%s", rebuild_ipv4)
            r_ipv6 := Parse(ipv6_ipv4_str);
            // fmt.Printf("Ipv6MappedNew-6:[%s]\n",ipv6_ipv4_str)
            return r_ipv6
        }
    }
    tmp := fmt.Sprintf("unknown mapped format:[%s]", str)
    // fmt.Printf("Ipv6MappedNew-7:%s\n", str)
    return &Error{&tmp}
}
