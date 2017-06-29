
import BigInt 
//import Prefix32 from './prefix32';
//import IPAddress from './ipaddress';
//import IpBits from './ip_bits';
//import Prefix128 from './prefix128';
//import Ipv6 from './ipv6';

class Ipv4 {
    class func from_int(_ addr: BigUInt, _ prefix_num: UInt8)-> IPAddress? {
        let prefix = Prefix32.create(prefix_num);
        if (prefix == nil) {
            return nil;
        }
        return IPAddress(
            ip_bits: IpBits.v4(),
            host_address: addr,
            prefix: prefix!,
            mapped: nil,
            vt_is_private: Ipv4.ipv4_is_private,
            vt_is_loopback: Ipv4.ipv4_is_loopback,
            vt_to_ipv6: Ipv4.to_ipv6
        );
    }

    class func create(_ str: String)-> IPAddress? {
        // console.log("create:v4:", str);
        // let enable = str == "0.0.0.0/0";
        let (ip, netmask) = IPAddress.split_at_slash(str);
        if (!IPAddress.is_valid_ipv4(ip)) {
            // enable && console.log("xx1");
            return nil;
        }
        var ip_prefix_num = UInt8(32);
        if (netmask != nil) {
            //  netmask is defined
            let tmp = IPAddress.parse_netmask_to_prefix(netmask!);
            if (tmp == nil) {
                // enable && console.log("xx2");
                return nil;
            }
            ip_prefix_num = tmp!
            //if ip_prefix.ip_bits.version
        }
        let ip_prefix = Prefix32.create(ip_prefix_num);
        if (ip_prefix == nil) {
            // enable && console.log("xx3");
            return nil;
        }
        let split_number = IPAddress.split_to_u32(ip);
        if (split_number == nil) {
            // enable && console.log("xx4");
            return nil;
        }
        // console.log(">>>>>>>", ip, ip_prefix);
        return IPAddress(
            ip_bits: IpBits.v4(),
            host_address: split_number!,
            prefix: ip_prefix!,
            mapped: nil,
            vt_is_private: Ipv4.ipv4_is_private,
            vt_is_loopback: Ipv4.ipv4_is_loopback,
            vt_to_ipv6: Ipv4.to_ipv6
        );
    }

    class func ipv4_is_private(_ my: IPAddress) -> Bool {
        return [IPAddress.parse("10.0.0.0/8")!,
            IPAddress.parse("169.254.0.0/16")!,
            IPAddress.parse("172.16.0.0/12")!,
            IPAddress.parse("192.168.0.0/16")!]
            .index(where: { $0.includes(my) }) != nil
    }

    class func ipv4_is_loopback(_ my: IPAddress) -> Bool {
        return IPAddress.parse("127.0.0.0/8")!.includes(my);
    }

    class func to_ipv6(_ ia: IPAddress) -> IPAddress {
        return IPAddress(
            ip_bits: IpBits.v6(),
            host_address: ia.host_address,
            prefix: Prefix128.create(ia.prefix.num)!,
            mapped: nil,
            vt_is_private: Ipv6.ipv6_is_private,
            vt_is_loopback: Ipv6.ipv6_is_loopback,
            vt_to_ipv6: Ipv6.to_ipv6
        );
    }

    //  Checks whether the ip address belongs to a
    //  RFC 791 CLASS A network, no matter
    //  what the subnet mask is.
    //
    //  Example:
    //
    //    ip = IPAddress("10.0.0.1/24")
    //
    //    ip.a?
    //      // => true
    //
    class func is_class_a(_ my: IPAddress) -> Bool {
        // console.log("is_class_a:", my.to_string(), BigUInt(0x80000000), my.is_ipv4()); 
        return my.is_ipv4() && my.host_address < BigUInt(0x80000000);
    }

    //  Checks whether the ip address belongs to a
    //  RFC 791 CLASS B network, no matter
    //  what the subnet mask is.
    //
    //  Example:
    //
    //    ip = IPAddress("172.16.10.1/24")
    //
    //    ip.b?
    //      // => true
    //
    class func is_class_b(_ my: IPAddress) -> Bool {
        return my.is_ipv4() &&
            BigUInt(0x80000000) <= (my.host_address) &&
            my.host_address < BigUInt(0xc0000000);
    }

    //  Checks whether the ip address belongs to a
    //  RFC 791 CLASS C network, no matter
    //  what the subnet mask is.
    //
    //  Example:
    //
    //    ip = IPAddress("192.168.1.1/30")
    //
    //    ip.c?
    //      // => true
    //
    class func is_class_c(_ my: IPAddress) -> Bool {
        return my.is_ipv4() &&
            BigUInt(0xc0000000) <= my.host_address &&
            my.host_address < BigUInt(0xe0000000);
    }


    //  Creates a new IPv4 address object by parsing the
    //  address in a classful way.
    //
    //  Classful addresses have a fixed netmask based on the
    //  class they belong to:
    //
    //  * Class A, from 0.0.0.0 to 127.255.255.255
    //  * Class B, from 128.0.0.0 to 191.255.255.255
    //  * Class C, D and E, from 192.0.0.0 to 255.255.255.254
    //
    //  Example:
    //
    //    ip = IPAddress::IPv4.parse_classful "10.0.0.1"
    //
    //    ip.netmask
    //      // => "255.0.0.0"
    //    ip.a?
    //      // => true
    //
    //  Note that classes C, D and E will all have a default
    //  prefix of /24 or 255.255.255.0
    //
    class func parse_classful(_ ip_si: String) -> IPAddress? {
        if (!IPAddress.is_valid_ipv4(ip_si)) {
            return nil;
        }
        let o_ip = IPAddress.parse(ip_si);
        if (o_ip == nil) {
            return o_ip;
        }
        let ip = o_ip!;
        if (Ipv4.is_class_a(ip)) {
            ip.prefix = Prefix32.create(8)!;
        } else if (Ipv4.is_class_b(ip)) {
            ip.prefix = Prefix32.create(16)!;
        } else if (Ipv4.is_class_c(ip)) {
            ip.prefix = Prefix32.create(24)!;
        }
        return ip;
    }
}

