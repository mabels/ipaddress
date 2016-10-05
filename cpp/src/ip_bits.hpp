#ifndef __IP_BITS__
#define __IP_BITS__

#include "crunchy.hpp"
#include "rle.hpp"
#include "ip_version.hpp"

#include <string>
#include <functional>
#include <vector>

namespace ipaddress {


class IpBits {
public:
  typedef std::function<std::string(const IpBits *source, const Crunchy &num)> ToString;
  const IpVersion version;
  const ToString vt_as_compressed_string;
  const ToString vt_as_uncompressed_string;
  const size_t bits;
  const size_t part_bits;
  const size_t dns_bits;
  const char *rev_domain;
  const size_t part_mod;
  const Crunchy host_ofs; // ipv4=1, ipv6=0

private:
  IpBits(IpVersion version,
    ToString vt_as_compressed_string, ToString vt_as_uncompressed_string,
    size_t bits, size_t part_bits, size_t dns_bits, const char *rev_domain,
    size_t part_mod, const Crunchy &host_ofs) : version(version),
    vt_as_compressed_string(vt_as_compressed_string),
    vt_as_uncompressed_string(vt_as_uncompressed_string),
    bits(bits), part_bits(part_bits), dns_bits(dns_bits),
    rev_domain(rev_domain), part_mod(part_mod), host_ofs(host_ofs) {
  }
public:

    const IpBits* clone() const {
      return this;
        // IpBits my;
        // my.version = this->version;
        // my.vt_as_compressed_string = this->vt_as_compressed_string;
        // my.vt_as_uncompressed_string = this->vt_as_uncompressed_string;
        // my.bits = this->bits;
        // my.part_bits = this->part_bits;
        // my.dns_bits = this->dns_bits;
        // my.rev_domain = this->rev_domain;
        // my.part_mod = this->part_mod;
        // my.host_ofs = this->host_ofs.clone();
        // return my;
    }
    std::vector<size_t> parts(const Crunchy &bu) const {
        std::vector<size_t> vec;
        auto my = bu.clone();
        // auto part_mod = Crunchy::one().shl(this->part_bits);// - Crunchy::one();
        for (size_t i = 0; i < (this->bits / this->part_bits); ++i) {
            // console.log("parts-1:", my, part_mod, my.mod(part_mod), my.mod(part_mod).toString());
            vec.push_back(my.mds(this->part_mod));
            my = my.shr(this->part_bits);
        }
        std::reverse(vec.begin(),vec.end());
        // console.log("parts:", vec);
        return vec;
    }

    std::string as_compressed_string(const Crunchy &bu) const {
        return (this->vt_as_compressed_string)(this, bu);
    }
    std::string as_uncompressed_string(const Crunchy &bu) const {
        return (this->vt_as_uncompressed_string)(this, bu);
    }

    std::string dns_part_format(size_t i) const {
      std::stringstream s2;
      if (this->version ==  IpVersion::V6) {
        s2 << std::hex;
      }
      s2 << i;
      return s2.str();
    }

    static const IpBits *v4();
    static const IpBits *v6();

};

std::ostream& operator<<(std::ostream &o, const IpBits &ip_bits);
}

#endif
