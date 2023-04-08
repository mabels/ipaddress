package com.adviser.ipaddress.kotlin


class Rle(val part: Int, var pos: Int, var cnt: Int, var max: Boolean) {

    fun inspect(): String {
        return "<Rle@part:{:x},pos:{},cnt:{},max:{}> self.part, self.pos, self.cnt, self.max)"
    }

    final override fun equals(other: Any?): Boolean {
        if (other is Rle) {
            return eq(other)
        }
        return false
    }

    fun eq(other: Rle): Boolean {
        return this.part == other.part && this.pos == other.pos &&
                this.cnt == other.cnt && this.max == other.max
    }

    class Last {
        var value: Rle? = null
        val max_poses = HashMap<Int, MutableList<Int>>()
        val ret = mutableListOf<Rle>()

        fun handle_last() {
            if (this.value == null) {
                return
            }
            val _last = this.value!!

            var max_rles = max_poses.get(_last.part)
            if (max_rles === null) {
                max_rles = mutableListOf()
                max_poses.put(_last.part, max_rles)
            }

            for (idx in max_rles) {
                val prev = this.ret.get(idx)
                if (prev.cnt > _last.cnt) {
                    // println!(">>>>> last={:?}->{}->prev={:?}", _last, idx, prev)
                    _last.max = false
                } else if (prev.cnt == _last.cnt) {
                    // nothing
                } else /* if (prev.cnt < _last.cnt) */ {
                    // println!("<<<<< last={:?}->{}->prev={:?}", _last, idx, prev)
                    //this.ret[idx].max = false
                    prev.max = false
                }
            }
            //println!("push:{}:{:?}", this.ret.len(), _last)
            max_rles.add(this.ret.size)
            _last.pos = this.ret.size
            this.ret.add(_last)
        }
    }

    companion object {
        fun code(parts: IntArray): List<Rle> {
            val last = Last()
            // println!("code")
            for (i in 0 until parts.size) {
                val part = parts.get(i)
                // println!("part:{}", part)
                if (last.value?.part == part) {
                    last.value!!.cnt += 1
                } else {
                    last.handle_last()
                    last.value = Rle(part, 0, 1, true)
                }
            }
            last.handle_last()
            return last.ret
        }
    }
}
