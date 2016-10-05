
#include "ip_bits.hpp"

namespace ipaddress {

static std::string ipv4_as_compressed(const IpBits *ip_bits, const Crunchy &host_address) {
    std::stringstream ret;
    std::string sep;
    for (auto part : ip_bits->parts(host_address)) {
        ret << sep;
        ret << part;
        sep = ".";
    }
    return ret.str();
}

static std::string ipv6_as_compressed(const IpBits *ip_bits, const Crunchy &host_address) {
    //println!("ipv6_as_compressed:{}", host_address);
    std::stringstream ret;
    std::string colon;
    bool done = false;
    ret << std::hex;
    for (auto rle : Rle::code(ip_bits->parts(host_address))) {
//            console.log(rle.toString());
        for (size_t _ = 0; _ < rle.cnt; _++) {
            if (done || !(rle.part == 0 && rle.max)) {
                ret << colon << rle.part;
                colon = ":";
            } else if (rle.part == 0 && rle.max) {
                ret << "::";
                colon = "";
                done = true;
                break;
            }
        }
    }
    return ret.str();
}
static std::string ipv6_as_uncompressed(const IpBits *ip_bits, const Crunchy &host_address) {
    std::string ret;
    const char *sep = "";
    for (auto part : ip_bits->parts(host_address)) {
        ret += sep;
        std::stringstream s2;
        s2 << std::hex << (0x10000 + part);
        ret += s2.str().substr(1);
        sep = ":";
    }
    return ret;
}

static IpBits *v4Ptr = 0;
const IpBits* IpBits::v4() {
  if (v4Ptr) {
    return v4Ptr;
  }
  v4Ptr = new IpBits(
     IpVersion::V4,
     ipv4_as_compressed,
     ipv4_as_compressed,
     32,
     8,
     8,
     "in-addr.arpa",
     1 << 8,
     Crunchy::one());
  return v4Ptr;
}

static IpBits *v6Ptr = 0;
const IpBits* IpBits::v6() {
  if (v6Ptr) {
    return v6Ptr;
  }
  v6Ptr = new IpBits(
      IpVersion::V6,
      ipv6_as_compressed,
      ipv6_as_uncompressed,
      128,
      16,
      4,
      "ip6.arpa",
      1 << 16,
      Crunchy::zero());
  return v6Ptr;
}

}
