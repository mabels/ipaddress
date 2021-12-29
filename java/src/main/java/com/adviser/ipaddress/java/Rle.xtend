package com.adviser.ipaddress.java

import java.util.Vector;
import java.util.HashMap;

class Rle {
    public long part
    public int pos
    public int cnt
    public boolean max

    new(long part, int pos, int cnt, boolean max) {
        this.part = part
        this.pos = pos
        this.cnt = cnt
        this.max = max
    }

    def Inspect() {
        return '''<Rle@part:{:x},pos:{},cnt:{},max:{}> self.part, self.pos, self.cnt, self.max)'''
    }

    override boolean equals(Object other) {
      return eq(other as Rle)
    }
    def boolean eq(Rle other) {
        return this.part == other.part && this.pos == other.pos &&
                this.cnt == other.cnt && this.max == other.max;
    }

    static class Last {
        public Rle value;
        public HashMap<Long, Vector<Integer>> max_poses = new HashMap<Long, Vector<Integer>>();
        public Vector<Rle> ret = new Vector<Rle>();

        def void handle_last() {
            if (this.value === null) {
                return
            }
            var _last = this.value;
            
            var max_rles = max_poses.get(Long.valueOf(_last.part))
            if (max_rles === null) {
                max_rles = new Vector<Integer>()
                max_poses.put(_last.part, max_rles);
            }

            for (idx : max_rles) {
                val prev = this.ret.get(idx);
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
            max_rles.add(this.ret.length());
            _last.pos = this.ret.length();
            this.ret.add(_last);
        }
    }

    static def Vector<Rle> code(int[] parts) {
        var last = new Last();
        // println!("code");
        for (var i = 0; i < parts.length(); i++) {
            val part = parts.get(i);
            // println!("part:{}", part);
            if (last.value !== null && last.value.part == part) {
                last.value.cnt += 1;
            } else {
                last.handle_last();
                last.value = new Rle(part, 0, 1, true)
            }
        }
        last.handle_last();
        return last.ret;
    }
}
