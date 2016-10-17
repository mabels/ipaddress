
#include <cascara/cascara.hpp>
using namespace cascara;

#include "../src/ipaddress.hpp"
#include "../src/prefix128.hpp"
#include "../src/ipv6_loopback.hpp"
#include "../src/crunchy.hpp"

using namespace ipaddress;

typedef struct S_IPv6LoopbackTest {
  IPAddress ip;
  const char * s;
  const char * n;
  const char *string;
  Crunchy one;
} IPv6LoopbackTest;

IPv6LoopbackTest setup() {
  IPv6LoopbackTest ret = {
    Ipv6Loopback::create(),
    "::1",
    "::1/128",
    "0000:0000:0000:0000:0000:0000:0000:0001/128",
    Crunchy::one()
  };
  return ret;
}

int main() {

  describe("ipv6_loopback", []() {
      it("test_attributes", []() {
          auto s = setup();
          assert.equal(128u, s.ip.prefix.num);
          assert.equal(true, s.ip.is_loopback());
          assert.equal(s.s, s.ip.to_s());
          assert.equal(s.n, s.ip.to_string());
          assert.equal(s.string, s.ip.to_string_uncompressed());
          assert.equal(s.one.toString(), s.ip.host_address.toString());
          });
      it("test_method_ipv6", []() {
          assert.equal(true, setup().ip.is_ipv6());
          });
      });
  return exit();
}
