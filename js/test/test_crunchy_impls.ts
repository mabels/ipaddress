// Exercises the shared CrunchyBase public API against both
// implementations, so they're guaranteed to behave identically for
// everything the rest of the codebase actually relies on. Internals
// specific to one implementation (e.g. CrunchyWith32Bit's 8/14-bit
// limb representation) are covered separately in
// test_crunchy_with32bit.ts.
import { CrunchyBase, CrunchyWithBigInt, CrunchyWith32Bit } from "../src/crunchy.js";

const impls: [string, CrunchyBase][] = [
  ["CrunchyWithBigInt", CrunchyWithBigInt.bootstrap()],
  ["CrunchyWith32Bit", new CrunchyWith32Bit()],
];

describe.each(impls)("Crunchy impl: %s", (_name, c) => {
  describe("#compare", () => {
    it("Should confirm equality", () => {
      const x = c.parse("12345678901234567890");
      const y = c.parse("12345678901234567890");
      assert.isTrue(x.eq(y));
    });

    it("Should find first is greater than second", () => {
      const x = c.parse("12345678901234567890");
      const y = c.parse("1234567890");
      assert.isTrue(x.gt(y));
    });

    it("Should find first is less than second", () => {
      const x = c.parse("1234567890");
      const y = c.parse("12345678901234567890");
      assert.isTrue(x.lt(y));
    });
  });

  describe("#add", () => {
    it("Should add numbers", () => {
      const x = c.parse("12345678911234567891");
      const y = c.parse("12345678901234567890");
      assert.equal(x.add(y).toString(), "24691357812469135781");
    });

    it("Should add numbers, first longer than second", () => {
      const x = c.parse("12345678901234567890");
      const y = c.parse("1234567890");
      assert.equal(x.add(y).toString(), "12345678902469135780");
    });

    it("Should add numbers, second longer than first", () => {
      const x = c.parse("1234567890");
      const y = c.parse("12345678901234567890");
      assert.equal(x.add(y).toString(), "12345678902469135780");
    });

    it("Should add zero to number", () => {
      const x = c.parse("12345678901234567890");
      const y = c.zero();
      assert.equal(x.add(y).toString(), "12345678901234567890");
    });

    it("Should add two zeros", () => {
      assert.equal(c.zero().add(c.zero()).toString(), "0");
    });
  });

  describe("#sub", () => {
    it("Should subtract numbers", () => {
      const x = c.parse("12345678901234567890");
      const y = c.parse("1234567890");
      assert.equal(x.sub(y).toString(), "12345678900000000000");
    });

    it("Should subtract two equal numbers expecting zero", () => {
      const x = c.parse("20");
      const y = c.parse("20");
      assert.equal(x.sub(y).toString(), "0");
    });

    it("Should subtract zero", () => {
      const x = c.parse("244137007161");
      assert.equal(x.sub(c.zero()).toString(), "244137007161");
    });
  });

  describe("#leftShift", () => {
    it("Should left shift a number", () => {
      const x = c.from_number(22 * 256 + 11);
      assert.equal(x.shl(5).toString(), "180576");
    });

    it("Should left shift zero", () => {
      assert.equal(c.zero().shl(80).toString(), "0");
    });
  });

  describe("#rightShift", () => {
    it("Should right shift a number", () => {
      const x = c.from_number(22 * 256 + 11);
      assert.equal(x.shr(5).toString(), "176");
    });

    it("Should right shift a number out of existence", () => {
      const x = c.from_number(22 * 256 + 11);
      assert.equal(x.shr(20).toString(), "0");
    });
  });

  describe("#mod", () => {
    it("Should calculate modulo", () => {
      const x = c.parse("123456789012345");
      const y = c.from_number(97);
      assert.equal(x.mod(y).toString(), "12");
    });

    it("Should calculate modulo of number smaller than modulus", () => {
      const x = c.from_number(97);
      const y = c.parse("123456789012345");
      assert.equal(x.mod(y).toString(), "97");
    });

    it("Should calculate modulo of modulus", () => {
      const x = c.from_number(241);
      const y = c.from_number(241);
      assert.equal(x.mod(y).toString(), "0");
    });

    it("Should calculate modulo of zero", () => {
      assert.equal(c.zero().mod(c.from_number(241)).toString(), "0");
    });
  });

  describe("#from_string", () => {
    it("Should parse a decimal string", () => {
      const x = c.from_string("340282366920938463463374607431768211455");
      assert.isOk(x);
      assert.equal(x!.toString(), "340282366920938463463374607431768211455");
    });

    it("Should parse a hex string", () => {
      const x = c.from_string("ff", 16);
      assert.isOk(x);
      assert.equal(x!.toString(16), "ff");
    });

    it("Should reject invalid characters", () => {
      assert.isNull(c.from_string("12a45"));
    });

    it("Should reject invalid hex digits", () => {
      assert.isNull(c.from_string("fg", 16));
    });
  });

  describe("#parse", () => {
    it("Should throw on invalid input", () => {
      assert.throws(() => c.parse("not-a-number"));
    });
  });

  describe("#create", () => {
    it("Should produce a zero value with no argument", () => {
      assert.isTrue(c.create().eq(c.zero()));
    });

    it("Should act like from_number() given a number", () => {
      assert.isTrue(c.create(42).eq(c.from_number(42)));
    });

    it("Should act like parse() given a string", () => {
      assert.isTrue(c.create("12345678901234567890").eq(c.parse("12345678901234567890")));
    });
  });

  describe("#toString", () => {
    it("Should round-trip a large number through a non-decimal radix", () => {
      const x = c.parse("340282366920938463463374607431768211455");
      assert.equal(c.from_string(x.toString(16), 16)!.toString(), x.toString());
    });
  });
});
