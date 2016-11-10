package rle

import (
	"fmt"
)

type Rle struct {
	part uint32
	pos  int
	cnt  uint32
	max  bool
}

func (r Rle) String() string {
	return fmt.Sprintf("Rle:part:{%d},pos:{%d},cnt:{%d},max:{%d}",
		r.part, r.pos, r.cnt, r.max)
}

// impl<T: Display + LowerHex> fmt::Debug for Rle<T> {
//     fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
//         write!(f, "<Rle@part:{:x},pos:{},cnt:{},max:{}>",
//             self.part, self.pos, self.cnt, self.max)
//     }
// }

func (self Rle) Equal(other Rle) bool {
  return self.part == other.part && self.pos == other.pos &&
          self.cnt == other.cnt && self.max == other.max;
}

//impl<T: PartialEq> Eq for Rle<T> {}
type Last struct {
	val       *Rle
	max_poses map[uint32][]int
	ret       []Rle
}

func (self *Last) handle_last() {
	if self.val == nil {
    // fmt.Printf("--1\n")
		return
	}
	_last := self.val
	max_rles, ok := self.max_poses[_last.part]
	if !ok {
		max_rles = make([]int, 0)
		self.max_poses[_last.part] = max_rles
    // fmt.Printf("--2 %d\n", _last.part)
	}
  // fmt.Printf("--A %d\n", len(max_rles))
	for _, idx := range max_rles {
		prev := &self.ret[idx]
		if prev.cnt > _last.cnt {
      // fmt.Printf("--3 %d %d\n", prev.part, _last.part)
			_last.max = false
		}
		if prev.cnt == _last.cnt {
      // fmt.Printf("--4\n")
			// nothing
		}
		if prev.cnt < _last.cnt {
      // fmt.Printf("--5 %d %d\n", prev.part, _last.part)
			// println!("<<<<< last={:?}->{}->prev={:?}", _last, idx, prev);
			//self.ret[idx].max = false;
			prev.max = false
		}
	}
	//println!("push:{}:{:?}", self.ret.len(), _last);
	self.max_poses[_last.part] = append(max_rles, len(self.ret))
	_last.pos = len(self.ret)
	self.ret = append(self.ret, *_last)
  // fmt.Printf("--6 -- %s -- %s -- %s --\n", _last, self.ret, self.val)
}

func Code(parts []uint32) []Rle {
	last := Last{nil, make(map[uint32][]int), make([]Rle, 0)}
  // fmt.Println("code");
	// println!("code");
	for i := 0; i < len(parts); i++ {
		part := parts[i]
    // fmt.Printf("code-1 %d %d\n", part, last.val);
		// println!("part:{}", part);
		if last.val != nil && last.val.part == part {
			last.val.cnt += 1
		} else {
			last.handle_last()
			last.val = &Rle{part, 0, 1, true}
		}
	}
	last.handle_last()
  return last.ret
  // vsm := make([]Rle, len(last.ret))
  // for i, v := range last.ret {
  //   vsm[i] = *v
  // }
	// return vsm
}
