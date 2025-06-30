class Last {
  val?: Rle;
  max_poses: number[][] = [];
  ret: Rle[] = [];

  public handle_last() {
    if (this.val == null) {
      return;
    }
    const _last = this.val;
    let max_rles = this.max_poses[_last.part];
    if (max_rles == null) {
      max_rles = this.max_poses[_last.part] = [];
    }
    // console.log(_last.part, this.max_poses);
    for (const idx in max_rles) {
      const prev = this.ret[max_rles[idx]];
      if (prev.cnt > _last.cnt) {
        // console.log(`>>>>> last=${_last}->${idx}->prev=${prev}`);
        _last.max = false;
      } else if (prev.cnt == _last.cnt) {
        // nothing
      } else if (prev.cnt < _last.cnt) {
        // console.log(`<<<<< last=${_last}->${idx}->prev=${prev}`);
        prev.max = false;
      }
    }
    // println!("push:{}:{:?}", self.ret.len(), _last);
    max_rles.push(this.ret.length);
    _last.pos = this.ret.length;
    this.ret.push(_last);
  }
}

interface RleParams {
  part: number;
  pos: number;
  cnt: number;
  max: boolean;
}

class Rle {
  public part: number;
  public pos: number;
  public cnt: number;
  public max: boolean;

  constructor(obj: RleParams) {
    this.part = obj.part;
    this.pos = obj.pos;
    this.cnt = obj.cnt;
    this.max = obj.max;
  }

  public toString() {
    return `<Rle@part:${this.part},pos:${this.pos},cnt:${this.cnt},max:${this.max}>`;
  }

  public eq(other: Rle): boolean {
    return this.part == other.part && this.pos == other.pos && this.cnt == other.cnt && this.max == other.max;
  }

  public ne(other: Rle): boolean {
    return !this.eq(other);
  }

  public static code(parts: number[]): Rle[] {
    const last = new Last();
    // println!("code");
    for (const part of parts) {
      // const part = parts[i]
      // console.log(`part:${part}`);
      if (last.val && last.val.part == part) {
        last.val.cnt += 1;
      } else {
        last.handle_last();
        last.val = new Rle({ part, pos: 0, cnt: 1, max: true });
      }
    }
    last.handle_last();
    return last.ret;
  }
}

export default Rle;
