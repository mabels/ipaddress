import 'dart:core';

class Last {
  Rle value = null;
  final max_poses = Map<int, List<int>>();
  final ret = List<Rle>();

  void handle_last() {
    if (this.value == null) {
      return;
    }
    var _last = this.value;
    var max_rles = max_poses[_last.part];
    if (max_rles == null) {
      max_rles = List<int>();
      max_poses[_last.part] = max_rles;
    }
    for (int idx in max_rles) {
      final prev = this.ret[idx];
      if (prev.cnt > _last.cnt) {
        // println!(">>>>> last={:?}->{}->prev={:?}", _last, idx, prev);
        _last.max = false;
      } else if (prev.cnt == _last.cnt) {
        // nothing
      } else if (prev.cnt < _last.cnt) {
        // println!("<<<<< last={:?}->{}->prev={:?}", _last, idx, prev);
        //this.ret[idx].max = false;
        prev.max = false;
      }
    }
    //println!("push:{}:{:?}", this.ret.len(), _last);
    max_rles.add(this.ret.length);
    _last.pos = this.ret.length;
    this.ret.add(_last);
  }
}

class Rle {
  int part;
  int pos;
  int cnt;
  bool max;

  Rle(this.part, this.pos, this.cnt, this.max);

  String Inspect() {
    return "<Rle@part:${part},pos:${pos},cnt:${cnt},max:${max}>";
  }

  bool eq(Rle other) {
    return this.part == other.part &&
        this.pos == other.pos &&
        this.cnt == other.cnt &&
        this.max == other.max;
  }

  static List<Rle> code(List<int> parts) {
    var last = Last();
    // println!("code");
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      // println!("part:{}", part);
      if (last.value != null && last.value.part == part) {
        last.value.cnt += 1;
      } else {
        last.handle_last();
        last.value = Rle(part, 0, 1, true);
      }
    }
    last.handle_last();
    return last.ret;
  }
}
