import IPAddress from "../src/ipaddress.js";
// import Prefix128 from '../src/prefix128';
// import Ipv6Unspec from '../src/ipv6_unspec';
import Ipv6Mapped from "../src/ipv6_mapped.js";
import Crunchy from "../src/crunchy.js";

interface IPv6MappedTestParams {
  ip: IPAddress;
  s: string;
  sstr: string;
  string: string;
  u128: Crunchy;
  address: string;
}

class IPv6MappedTest {
  ip: IPAddress;
  s: string;
  sstr: string;
  string: string;
  u128: Crunchy;
  address: string;
  valid_mapped: [string, Crunchy][] = [];
  valid_mapped_ipv6: [string, Crunchy][] = [];
  valid_mapped_ipv6_conversion: [string, string][] = [];
  constructor(obj: IPv6MappedTestParams) {
    this.ip = obj.ip;
    this.s = obj.s;
    this.sstr = obj.sstr;
    this.string = obj.string;
    this.u128 = obj.u128;
    this.address = obj.address;
  }
}

describe("ipv6_mapped", () => {
  function setup(): IPv6MappedTest {
    const ipv6 = new IPv6MappedTest({
      ip: Ipv6Mapped.create("::172.16.10.1"),
      s: "::ffff:172.16.10.1",
      sstr: "::ffff:172.16.10.1/32",
      string: "0000:0000:0000:0000:0000:ffff:ac10:0a01/128",
      u128: Crunchy.parse("281473568475649"),
      address: "::ffff:ac10:a01/128",
    });
    ipv6.valid_mapped.push(["::13.1.68.3", Crunchy.parse("281470899930115")]);
    ipv6.valid_mapped.push([
      "0:0:0:0:0:ffff:129.144.52.38",
      Crunchy.parse("281472855454758"),
    ]);
    ipv6.valid_mapped.push([
      "::ffff:129.144.52.38",
      Crunchy.parse("281472855454758"),
    ]);
    ipv6.valid_mapped_ipv6.push([
      "::ffff:13.1.68.3",
      Crunchy.parse("281470899930115"),
    ]);
    ipv6.valid_mapped_ipv6.push([
      "0:0:0:0:0:ffff:8190:3426",
      Crunchy.parse("281472855454758"),
    ]);
    ipv6.valid_mapped_ipv6.push([
      "::ffff:8190:3426",
      Crunchy.parse("281472855454758"),
    ]);
    ipv6.valid_mapped_ipv6_conversion.push(["::ffff:13.1.68.3", "13.1.68.3"]);
    ipv6.valid_mapped_ipv6_conversion.push([
      "0:0:0:0:0:ffff:8190:3426",
      "129.144.52.38",
    ]);
    ipv6.valid_mapped_ipv6_conversion.push([
      "::ffff:8190:3426",
      "129.144.52.38",
    ]);
    return ipv6;
  }

  it("test_initialize", () => {
    const s = setup();
    assert.isOk(IPAddress.parse("::172.16.10.1"));
    for (const i of s.valid_mapped) {
      const ip = i[0];
      const u128 = i[1];
      // println("-{}--{}", ip, u128);
      if (!IPAddress.parse(ip)) {
        // console.log(IPAddress.parse(ip));
      }
      assert.isOk(IPAddress.parse(ip));
      assert.equal(
        u128.toString(),
        IPAddress.parse(ip).host_address.toString(),
      );
    }
    for (const i of s.valid_mapped_ipv6) {
      const ip = i[0];
      const u128 = i[1];
      // println("===={}=={:x}", ip, u128);
      assert.isOk(IPAddress.parse(ip));
      assert.equal(
        u128.toString(),
        IPAddress.parse(ip).host_address.toString(),
      );
    }
  });
  it("test_mapped_from_ipv6_conversion", () => {
    for (const i of setup().valid_mapped_ipv6_conversion) {
      const ip6 = i[0];
      const ip4 = i[1];
      assert.equal(ip4, IPAddress.parse(ip6).mapped.to_s());
    }
  });
  it("test_attributes", () => {
    const s = setup();
    assert.equal(s.address, s.ip.to_string());
    assert.equal(128, s.ip.prefix.num);
    assert.equal(s.s, s.ip.to_s_mapped());
    assert.equal(s.sstr, s.ip.to_string_mapped());
    assert.equal(s.string, s.ip.to_string_uncompressed());
    assert.equal(s.u128.toString(), s.ip.host_address.toString());
  });
  it("test_method_ipv6", () => {
    assert.isOk(setup().ip.is_ipv6());
  });
  it("test_mapped", () => {
    assert.isOk(setup().ip.is_mapped());
  });
});
