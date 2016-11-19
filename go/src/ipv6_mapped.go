
import "ipaddress"

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
func New(str string) (*IPAddress, *string) {
    ip, o_netmask := IPAddress.split_at_slash(str);
    split_colon := ip.split(":");
    if len(split_colon) <= 1 {
        // println!("---1");
        return null, fmt.Sprintf("not mapped format-1: %s", string);
    }
    // if split_colon.get(0).unwrap().len() > 0 {
    //     // println!("---1a");
    //     return Err(format!("not mapped format-2: {}", string));
    // }
    // let mapped: Option<IPAddress> = None;
    netmask := "";
    if o_netmask != null {
        netmask = fmt.Sprintf("/%s", o_netmask);
    }
    ipv4_str := split_colon[len(split_colon)-1]
    if IPAddress::is_valid_ipv4(ipv4_str) {
        ipv4 := IPAddress::parse(fmt.Sprintf("%s%s", ipv4_str, netmask));
        if ipv4 == nil {
            fmt.Sprintf("---2");
            return ipv4;
        }
        //mapped = Some(ipv4.unwrap());
        addr := ipv4;
        ipv6_bits := ip_bits::v6();
        part_mod := ipv6_bits.part_mod;
        up_addr := addr.host_address;
        down_addr := addr.host_address;

        let mut rebuild_ipv6 = String::new();
        colon := "";
        for i in 0..split_colon.len()-1 {
            rebuild_ipv6.push_str(colon);
            rebuild_ipv6.push_str(split_colon[i]);
            colon = ":";
        }
        rebuild_ipv6.push_str(colon);
        rebuild_ipv4 := fmt.Sprintf("{:x}:{:x}/{}",
            up_addr.shr(::ip_bits::v6().part_bits).mod_floor(&part_mod).to_u16().unwrap(),
            down_addr.mod_floor(&part_mod).to_u16().unwrap(),
            ipv6_bits.bits-addr.prefix.host_prefix());
        rebuild_ipv6.push_str(&rebuild_ipv4);
        let r_ipv6 = IPAddress::parse(rebuild_ipv6.clone());
        if r_ipv6.is_err() {
            // println!("---3|{}", &rebuild_ipv6);
            return r_ipv6, nil;
        }
        if r_ipv6.clone().unwrap().is_mapped() {
            return r_ipv6, nil;
        }
        ipv6 := r_ipv6.unwrap();
        p96bit := ipv6.host_address.clone().shr(32);
        if  p96bit != BigUint::zero() {
            // println!("---4|%s", &rebuild_ipv6);
            return nil, fmt.Sprintf("is not a mapped address:%s", rebuild_ipv6);
        }
        {
            r_ipv6 := IPAddress::parse(format!("::ffff:%s", rebuild_ipv4));
            if r_ipv6 == nil {
                // fmt.Sprintf("---3|%s", rebuild_ipv6);
                return r_ipv6, nil;
            }
            return r_ipv6, nil;
        }
    }
    return nil, fmt.Sprintf("unknown mapped format:%s", str);
}
