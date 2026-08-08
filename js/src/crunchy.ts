/**
 * Arbitrary-precision integer used throughout ip address math.
 *
 * Historically this was always the hand-rolled 28-bit-limb
 * implementation below (CrunchyWith32Bit), ported from
 * Crunch - Arbitrary-precision integer arithmetic library
 * Copyright (C) 2014 Nenad Vukicevic crunch.secureroom.net/license
 *
 * Native BigInt is now available in every runtime this library
 * targets, so there are two implementations of CrunchyBase -
 * CrunchyWithBigInt (native BigInt, used whenever available) and
 * CrunchyWith32Bit (the original limb-array implementation, kept for
 * environments without BigInt support). Which one backs `Crunchy` is
 * decided once, at module load, by feature-detecting BigInt.
 *
 * `Crunchy` is a value (not a class), so `new Crunchy()` is not
 * possible - use `Crunchy.create()` (or any of the other factories:
 * `Crunchy.zero()`, `Crunchy.parse()`, ...).
 */

export interface CrunchyBase {
  clone(): CrunchyBase;
  compare(y: CrunchyBase): number;
  eq(oth: CrunchyBase): boolean;
  lt(oth: CrunchyBase): boolean;
  lte(oth: CrunchyBase): boolean;
  gt(oth: CrunchyBase): boolean;
  gte(oth: CrunchyBase): boolean;
  add(y: CrunchyBase): CrunchyBase;
  sub(y: CrunchyBase): CrunchyBase;
  shl(s: number): CrunchyBase;
  shr(s: number): CrunchyBase;
  mod(y: CrunchyBase): CrunchyBase;
  toString(radix?: number): string;

  // Factories. Every value carries these too (not just the `Crunchy`
  // singleton), since they're plain instance methods - but in
  // practice they're only ever called on the singleton.
  //  create() with no argument returns zero; given a number it acts
  //  like from_number(), given a string it acts like parse().
  create(value?: number | string): CrunchyBase;
  zero(): CrunchyBase;
  one(): CrunchyBase;
  two(): CrunchyBase;
  parse(val: string): CrunchyBase;
  from_number(val: number): CrunchyBase;
  from_string(val: string, radix?: number): CrunchyBase | null;
  from_string_or_throw(val: string, radix?: number): CrunchyBase;
}

/**
 * Native BigInt-backed implementation. Used whenever the runtime
 * supports BigInt (i.e. essentially always: Node 10.4+, every
 * evergreen browser, Deno).
 */
export class CrunchyWithBigInt implements CrunchyBase {
  public readonly value: bigint;

  // Only ever constructed from within this class (its own methods, or
  // the bootstrap() below used once to seed the module-level
  // singleton) - real values always arrive as number|string, through
  // from_number()/from_string()/parse(), never as a raw bigint.
  private constructor(value: bigint) {
    this.value = value;
  }

  public static bootstrap(): CrunchyWithBigInt {
    return new CrunchyWithBigInt(0n);
  }

  private static valueOf(y: CrunchyBase): bigint {
    if (!(y instanceof CrunchyWithBigInt)) {
      throw new Error("CrunchyWithBigInt operation received a non-CrunchyWithBigInt operand");
    }
    return y.value;
  }

  public clone(): CrunchyBase {
    return new CrunchyWithBigInt(this.value);
  }

  public compare(y: CrunchyBase): number {
    const yv = CrunchyWithBigInt.valueOf(y);
    if (this.value < yv) return -1;
    if (this.value > yv) return 1;
    return 0;
  }

  public eq(oth: CrunchyBase): boolean {
    return this.compare(oth) == 0;
  }

  public lt(oth: CrunchyBase): boolean {
    return this.compare(oth) < 0;
  }

  public lte(oth: CrunchyBase): boolean {
    return this.compare(oth) <= 0;
  }

  public gt(oth: CrunchyBase): boolean {
    return this.compare(oth) > 0;
  }

  public gte(oth: CrunchyBase): boolean {
    return this.compare(oth) >= 0;
  }

  public add(y: CrunchyBase): CrunchyBase {
    return new CrunchyWithBigInt(this.value + CrunchyWithBigInt.valueOf(y));
  }

  public sub(y: CrunchyBase): CrunchyBase {
    return new CrunchyWithBigInt(this.value - CrunchyWithBigInt.valueOf(y));
  }

  //  shl/shr shift the magnitude only and leave the sign untouched,
  //  matching CrunchyWith32Bit (native BigInt `>>` on a negative value
  //  performs an arithmetic/floor shift instead).
  public shl(s: number): CrunchyBase {
    const neg = this.value < 0n;
    const abs = neg ? -this.value : this.value;
    const shifted = abs << BigInt(s);
    return new CrunchyWithBigInt(neg ? -shifted : shifted);
  }

  public shr(s: number): CrunchyBase {
    const neg = this.value < 0n;
    const abs = neg ? -this.value : this.value;
    const shifted = abs >> BigInt(s);
    return new CrunchyWithBigInt(neg ? -shifted : shifted);
  }

  //  Floored modulo: result always has the same sign as `y` (or is
  //  zero), which matches the only path CrunchyWith32Bit.mod() is
  //  actually exercised with (non-negative operands).
  public mod(y: CrunchyBase): CrunchyBase {
    const yv = CrunchyWithBigInt.valueOf(y);
    let r = this.value % yv;
    if (r !== 0n && r < 0n !== yv < 0n) {
      r += yv;
    }
    return new CrunchyWithBigInt(r);
  }

  //  Never emits a sign, matching CrunchyWith32Bit.toString(), which
  //  only ever produces magnitude digits.
  public toString(radix = 10): string {
    const abs = this.value < 0n ? -this.value : this.value;
    return abs.toString(radix);
  }

  public create(value?: number | string): CrunchyBase {
    if (value === undefined) {
      return this.zero();
    }
    return typeof value === "number" ? this.from_number(value) : this.parse(value);
  }

  public zero(): CrunchyBase {
    return new CrunchyWithBigInt(0n);
  }

  public one(): CrunchyBase {
    return new CrunchyWithBigInt(1n);
  }

  public two(): CrunchyBase {
    return new CrunchyWithBigInt(2n);
  }

  public parse(val: string): CrunchyBase {
    const ret = this.from_string(val, 10);
    if (ret === null) {
      throw new Error(`invalid decimal number: ${val}`);
    }
    return ret;
  }

  public from_number(val: number): CrunchyBase {
    return new CrunchyWithBigInt(BigInt(Math.trunc(val)));
  }

  public from_string(val: string, radix = 10): CrunchyBase | null {
    let s = val;
    let neg = false;
    if (s.startsWith("-")) {
      neg = true;
      s = s.slice(1);
    }
    let result = 0n;
    const bigRadix = BigInt(radix);
    for (const ch of s) {
      const digit = parseInt(ch, radix);
      if (isNaN(digit)) {
        return null;
      }
      result = result * bigRadix + BigInt(digit);
    }
    return new CrunchyWithBigInt(neg ? -result : result);
  }

  public from_string_or_throw(val: string, radix = 10): CrunchyBase {
    const ret = this.from_string(val, radix);
    if (ret === null) {
      throw new Error(`invalid number: ${val} (radix ${radix})`);
    }
    return ret;
  }
}

/**
 * @module Crunch
 * Radix: 28 bits
 * Endianness: Big
 *
 * @param {boolean} rawIn   - expect 28-bit arrays
 * @param {boolean} rawOut  - return 28-bit arrays
 */
export class CrunchyWith32Bit implements CrunchyBase {
  num: number[] = [];
  negative = false;

  static zeroes: number[] = ((n: number): number[] => {
    return new Array(n).fill(0);
  })(60);

  public clone(): CrunchyWith32Bit {
    const ret = new CrunchyWith32Bit();
    ret.num = this.num.slice();
    ret.negative = this.negative;
    return ret;
  }

  public static removeLeadingZeros(inn: number[]): number[] {
    const out = inn.slice();
    while (out[0] === 0 && out.length > 1) {
      out.shift();
    }
    return out; // .transformOut();
  }

  public static from_14bit(a: number[]): CrunchyWith32Bit {
    const ret = new CrunchyWith32Bit();
    ret.num = a;
    return ret;
  }

  public static from_8bit(a: number[]): CrunchyWith32Bit {
    let x = [0, 0, 0, 0, 0, 0].slice((a.length - 1) % 7);
    const z = new CrunchyWith32Bit();

    if (a[0] < 0) {
      a[0] *= -1;
      z.negative = true;
    } else {
      z.negative = false;
    }
    x = x.concat(a);
    for (let i = 0; i < x.length; i += 7) {
      z.num.push(
        x[i] * 1048576 + x[i + 1] * 4096 + x[i + 2] * 16 + (x[i + 3] >> 4),
        (x[i + 3] & 15) * 16777216 + x[i + 4] * 65536 + x[i + 5] * 256 + x[i + 6],
      );
    }
    z.num = CrunchyWith32Bit.removeLeadingZeros(z.num);
    return z;
  }

  private static _zero = CrunchyWith32Bit.from_8bit([0]);
  private static _one = CrunchyWith32Bit.from_8bit([1]);
  private static _two = CrunchyWith32Bit.from_8bit([2]);

  public create(value?: number | string): CrunchyBase {
    if (value === undefined) {
      return this.zero();
    }
    return typeof value === "number" ? this.from_number(value) : this.parse(value);
  }

  public zero(): CrunchyBase {
    return CrunchyWith32Bit._zero;
  }

  public one(): CrunchyBase {
    return CrunchyWith32Bit._one;
  }

  public two(): CrunchyBase {
    return CrunchyWith32Bit._two;
  }

  public parse(val: string): CrunchyWith32Bit {
    const ret = this.from_string(val, 10);
    if (ret === null) {
      throw new Error(`invalid decimal number: ${val}`);
    }
    return ret;
  }

  public from_number(val: number): CrunchyWith32Bit {
    return this.parse("" + val);
  }

  //  Same as from_string(), but for literals that are known to be valid
  //  numbers (e.g. hardcoded hex constants), so the caller doesn't need
  //  to deal with a nullable result it can never actually observe.
  public from_string_or_throw(val: string, radix = 10): CrunchyWith32Bit {
    const ret = this.from_string(val, radix);
    if (ret === null) {
      throw new Error(`invalid number: ${val} (radix ${radix})`);
    }
    return ret;
  }

  public from_string(val: string, radix = 10): CrunchyWith32Bit | null {
    const x = val.split("");
    let p = CrunchyWith32Bit._one;
    let a = CrunchyWith32Bit._zero;
    const b = CrunchyWith32Bit.from_8bit([radix]);
    let n = false;

    if (x[0] === "-") {
      n = true;
      x.shift();
    }
    while (x.length > 0) {
      const popped = x.pop();
      if (popped === undefined) {
        break;
      }
      const c = parseInt(popped, radix);
      if (isNaN(c)) {
        console.error("from_string:", val);
        return null;
      }
      a = a.add(p.mul(CrunchyWith32Bit.from_8bit([c])));
      p = p.mul(b);
    }
    a.negative = n;
    return a;
  }

  public to_8bit(): number[] {
    const x = [0].slice((this.num.length - 1) % 2).concat(this.num);
    let z: number[] = [];

    for (let i = 0; i < x.length;) {
      const u = x[i++];
      const v = x[i++];

      z.push(u >> 20, (u >> 12) & 255, (u >> 4) & 255, ((u << 4) | (v >> 24)) & 255, (v >> 16) & 255, (v >> 8) & 255, v & 255);
    }
    z = CrunchyWith32Bit.removeLeadingZeros(z);

    if (this.negative) {
      z[0] *= -1;
    }
    return z;
  }

  public compare(y: CrunchyBase): number {
    const yy = y as CrunchyWith32Bit;
    const xl = this.num.length;
    const yl = yy.num.length; // zero front pad problem

    if (xl < yl) {
      return -1;
    } else if (xl > yl) {
      return 1;
    }

    for (let i = 0; i < xl; i++) {
      if (this.num[i] < yy.num[i]) return -1;
      if (this.num[i] > yy.num[i]) return 1;
    }

    return 0;
  }

  public eq(oth: CrunchyBase): boolean {
    return this.compare(oth) == 0;
  }

  public lt(oth: CrunchyBase): boolean {
    return this.compare(oth) < 0;
  }

  public lte(oth: CrunchyBase): boolean {
    return this.compare(oth) <= 0;
  }

  public gt(oth: CrunchyBase): boolean {
    return this.compare(oth) > 0;
  }

  public gte(oth: CrunchyBase): boolean {
    return this.compare(oth) >= 0;
  }

  public add(y: CrunchyBase): CrunchyWith32Bit {
    const yy = y as CrunchyWith32Bit;
    let z: CrunchyWith32Bit;
    if (this.negative) {
      if (yy.negative) {
        z = this.unsigned_add(yy);
        z.negative = true;
      } else {
        z = yy.unsigned_sub(this, false).cut();
      }
    } else {
      z = yy.negative ? this.unsigned_sub(yy, false).cut() : this.unsigned_add(yy);
    }
    return z;
  }

  public unsigned_add(_y: CrunchyWith32Bit): CrunchyWith32Bit {
    const n = this.num.length;
    const t = _y.num.length;
    let i = Math.max(n, t);
    let c = 0;
    const z = CrunchyWith32Bit.zeroes.slice(0, i);
    let x = this.num;
    let y = _y.num;
    if (n < t) {
      x = CrunchyWith32Bit.zeroes.slice(0, t - n).concat(this.num);
    } else if (n > t) {
      y = CrunchyWith32Bit.zeroes.slice(0, n - t).concat(y);
    }
    for (i -= 1; i >= 0; i--) {
      z[i] = x[i] + y[i] + c;

      if (z[i] > 268435455) {
        c = 1;
        z[i] -= 268435456;
      } else {
        c = 0;
      }
    }

    if (c === 1) {
      z.unshift(c);
    }
    const ret = new CrunchyWith32Bit();
    ret.num = z;
    return ret;
  }

  public sub(y: CrunchyBase): CrunchyWith32Bit {
    const yy = y as CrunchyWith32Bit;
    let z: CrunchyWith32Bit;
    if (this.negative) {
      if (yy.negative) {
        z = yy.unsigned_sub(this, false).cut();
      } else {
        z = this.unsigned_add(yy);
        z.negative = true;
      }
    } else {
      z = yy.negative ? this.unsigned_add(yy) : this.unsigned_sub(yy, false).cut();
    }
    return z;
  }

  public unsigned_sub(_y: CrunchyWith32Bit, internal = false): CrunchyWith32Bit {
    const n = this.num.length;
    const t = _y.num.length;
    let i = Math.max(n, t);
    let c = 0;
    const z = CrunchyWith32Bit.zeroes.slice(0, i);
    let x = this.num;
    let y = _y.num;
    if (n < t) {
      x = CrunchyWith32Bit.zeroes.slice(0, t - n).concat(x);
    } else if (n > t) {
      y = CrunchyWith32Bit.zeroes.slice(0, n - t).concat(y);
    }
    for (i -= 1; i >= 0; i--) {
      z[i] = x[i] - y[i] - c;

      if (z[i] < 0) {
        c = 1;
        z[i] += 268435456;
      } else {
        c = 0;
      }
    }

    let cry = new CrunchyWith32Bit();
    cry.num = z;
    if (c === 1 && !internal) {
      const zero = new CrunchyWith32Bit();
      zero.num = CrunchyWith32Bit.zeroes.slice(0, z.length);
      cry = zero.unsigned_sub(cry, true);
      cry.negative = true;
    }
    return cry;
  }

  public lsh(s: number): CrunchyWith32Bit {
    const ss = s % 28;
    const ls = Math.floor(s / 28);
    let l = this.num.length;
    const z: CrunchyWith32Bit = this.clone();
    let t = 0;

    if (ss) {
      z.num = [];
      while (l--) {
        z.num[l] = ((this.num[l] << ss) + t) & 268435455;
        t = this.num[l] >>> (28 - ss);
      }

      if (t !== 0) {
        z.num.unshift(t);
      }

      z.negative = this.negative;
    }
    if (ls) {
      z.num = z.num.concat(CrunchyWith32Bit.zeroes.slice(0, ls));
    }
    return z;
  }

  public rsh(s: number): CrunchyWith32Bit {
    const ss = s % 28;
    const ls = Math.floor(s / 28);
    let l = this.num.length - ls;
    const z = this.clone();
    z.num = this.num.slice(0, l);
    if (ss) {
      while (--l >= 0) {
        z.num[l] = ((z.num[l] >> ss) | (z.num[l - 1] << (28 - ss))) & 268435455;
      }

      z.num[l] = z.num[l] >> ss;

      if (z.num[0] === 0) {
        z.num.shift();
      }
    }
    return z;
  }

  public mul(y: CrunchyBase): CrunchyWith32Bit {
    const yy = y as CrunchyWith32Bit;
    let yl: number;
    let yh: number;
    let c: number;
    const n = this.num.length;
    let i = yy.num.length;
    const z = CrunchyWith32Bit.zeroes.slice(0, n + i);

    while (i--) {
      c = 0;

      yl = yy.num[i] & 16383;
      yh = yy.num[i] >> 14;

      for (let j = n - 1, xl: number, xh: number, t1: number, t2: number; j >= 0; j--) {
        xl = this.num[j] & 16383;
        xh = this.num[j] >> 14;

        t1 = yh * xl + xh * yl;
        t2 = yl * xl + ((t1 & 16383) << 14) + z[j + i + 1] + c;

        z[j + i + 1] = t2 & 268435455;
        c = yh * xh + (t1 >> 14) + (t2 >> 28);
      }

      z[i] = c;
    }

    if (z[0] === 0) {
      z.shift();
    }
    const ret = new CrunchyWith32Bit();
    ret.negative = this.negative !== yy.negative;
    ret.num = z;
    return ret;
  }

  public static msb(x: number): number | undefined {
    if (x !== 0) {
      let z = 0;
      for (let i = 134217728; i > x; z++) {
        i /= 2;
      }
      return z;
    }
  }

  public shr(s: number): CrunchyWith32Bit {
    const my = this.rsh(s);
    return my.cut();
  }

  public shl(s: number): CrunchyWith32Bit {
    return this.lsh(s).cut();
  }

  public cut(): CrunchyWith32Bit {
    const out = this.clone();
    // beasty hack
    if (out.num.length == 0) {
      out.num = [0];
      return out;
    }
    while (out.num[0] === 0 && out.num.length > 1) {
      out.num.shift();
    }
    return out;
  }

  public div(y: CrunchyBase, internal = false): CrunchyWith32Bit | null {
    const yy = y as CrunchyWith32Bit;
    if (yy.num.length === 1 && yy.num[0] === 0) {
      return null;
    }
    let u: CrunchyWith32Bit;
    let v: CrunchyWith32Bit;
    const s = (CrunchyWith32Bit.msb(yy.num[0]) ?? 0) - 1;
    if (s > 0) {
      u = this.lsh(s);
      v = yy.lsh(s);
    } else {
      u = this.clone();
      v = yy.clone();
    }
    const d = u.num.length - v.num.length;
    const q = [0];
    let k = CrunchyWith32Bit.from_14bit(v.num.concat(CrunchyWith32Bit.zeroes.slice(0, d)));
    const yt = v.num[0] * 268435456 + v.num[1];

    // only cmp as last resort
    while (u.num[0] > k.num[0] || (u.num[0] === k.num[0] && u.compare(k) > -1)) {
      q[0]++;
      u = u.unsigned_sub(k, false);
    }

    for (let i = 1; i <= d; i++) {
      q[i] = u.num[i - 1] === v.num[0] ? 268435455 : ~~((u.num[i - 1] * 268435456 + u.num[i]) / v.num[0]);

      const xt = u.num[i - 1] * 72057594037927936 + u.num[i] * 268435456 + u.num[i + 1];
      while (q[i] * yt > xt) {
        // condition check can fail due to precision problem at 28-bit
        q[i]--;
      }

      k = v.mul(CrunchyWith32Bit.from_14bit([q[i]]));
      k.num = k.num.concat(CrunchyWith32Bit.zeroes.slice(0, d - i)); // concat after multiply, save cycles
      u = u.unsigned_sub(k, false);

      if (u.negative) {
        u = CrunchyWith32Bit.from_14bit(v.num.concat(CrunchyWith32Bit.zeroes.slice(0, d - i))).unsigned_sub(u, false);
        q[i]--;
      }
    }
    let z: CrunchyWith32Bit;
    if (internal) {
      z = s > 0 ? u.cut().rsh(s) : u.cut();
    } else {
      z = CrunchyWith32Bit.from_14bit(CrunchyWith32Bit.removeLeadingZeros(q));
      z.negative = this.negative !== yy.negative;
    }

    return z;
  }

  //  Same as div(), but for divisors that are known to be non-zero, so the
  //  caller doesn't need to deal with a nullable result it can never
  //  actually observe.
  public div_or_throw(y: CrunchyBase, internal = false): CrunchyWith32Bit {
    const ret = this.div(y, internal);
    if (ret === null) {
      throw new Error("division by zero");
    }
    return ret;
  }

  public mod(y: CrunchyBase): CrunchyWith32Bit {
    // For negative x, cmp doesn't work and result of div is negative
    // so take result away from the modulus to get the correct result
    const yy = y as CrunchyWith32Bit;
    if (this.negative) {
      return yy.sub(this.div_or_throw(yy, true));
    }
    switch (this.compare(yy)) {
      case -1:
        return this;
      case 0:
        return CrunchyWith32Bit.from_8bit([0]);
      default:
        return this.div_or_throw(yy, true);
    }
  }

  public mds(n: number): number {
    let z = 0;
    for (let i = 0, l = this.num.length; i < l; i++) {
      z = ((this.num[i] >> 14) + (z << 14)) % n;
      z = ((this.num[i] & 16383) + (z << 14)) % n;
    }
    return z;
  }

  public toString(radix = 10): string {
    const a: string[] = [];
    let i = 0;
    let x = this.clone();
    const cradix = CrunchyWith32Bit.from_8bit([radix]);
    const zero = CrunchyWith32Bit._zero;
    do {
      const digit = x.mds(radix);
      x = x.div_or_throw(cradix);
      a[i++] = "0123456789abcdef"[digit];
    } while (!x.eq(zero));
    return a.reverse().join("");
  }
}

// Feature detection, computed once at module load.
export const hasBigInt: boolean = typeof BigInt !== "undefined";

const crunchySingleton: CrunchyBase = hasBigInt ? CrunchyWithBigInt.bootstrap() : new CrunchyWith32Bit();

export type Crunchy = CrunchyBase;
export const Crunchy: CrunchyBase = crunchySingleton;

export default Crunchy;
