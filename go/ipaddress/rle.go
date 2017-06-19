package ipaddress

import "fmt"

type Rle struct {
	Part uint16
	Pos  int
	Cnt  int
	Max  bool
}

func (r *Rle) String() string {
	return fmt.Sprintf("Rle:Part:{%d},Pos:{%d},Cnt:{%d},Max:{%d}",
		r.Part, r.Pos, r.Cnt, r.Max)
}

// impl<T: Display + LowerHex> fmt::Debug for Rle<T> {
//     fn fmt(&self, f: &mut fmt::Formatter)fmt::Result {
//         write!(f, "<Rle@Part:{:x},Pos:{},Cnt:{},Max:{}>",
//             self.Part, self.Pos, self.Cnt, self.Max)
//     }
// }

func (self *Rle) Equal(other Rle) bool {
	return self.Part == other.Part && self.Pos == other.Pos &&
		self.Cnt == other.Cnt && self.Max == other.Max
}

//impl<T: PartialEq> Eq for Rle<T> {}
type Last struct {
	val       *Rle
	Max_Poses map[uint16][]int
	ret       []Rle
}

func (self *Last) handle_last() {
	if self.val == nil {
		// fmt.Printf("--1\n")
		return
	}
	_last := self.val
	Max_rles, ok := self.Max_Poses[_last.Part]
	if !ok {
		Max_rles = make([]int, 0)
		self.Max_Poses[_last.Part] = Max_rles
		// fmt.Printf("--2 %d\n", _last.Part)
	}
	// fmt.Printf("--A %d\n", len(Max_rles))
	for _, idx := range Max_rles {
		prev := &self.ret[idx]
		if prev.Cnt > _last.Cnt {
			// fmt.Printf("--3 %d %d\n", prev.Part, _last.Part)
			_last.Max = false
		}
		if prev.Cnt == _last.Cnt {
			// fmt.Printf("--4\n")
			// nothing
		}
		if prev.Cnt < _last.Cnt {
			// fmt.Printf("--5 %d %d\n", prev.Part, _last.Part)
			// println!("<<<<< last={:?}->{}->prev={:?}", _last, idx, prev);
			//self.ret[idx].Max = false;
			prev.Max = false
		}
	}
	//println!("push:{}:{:?}", self.ret.len(), _last);
	self.Max_Poses[_last.Part] = append(Max_rles, len(self.ret))
	_last.Pos = len(self.ret)
	self.ret = append(self.ret, *_last)
	// fmt.Printf("--6 -- %s -- %s -- %s --\n", _last, self.ret, self.val)
}

func Code(Parts []uint16) []Rle {
	last := Last{nil, make(map[uint16][]int), make([]Rle, 0)}
	// fmt.Println("code");
	// println!("code");
	for i := 0; i < len(Parts); i++ {
		Part := Parts[i]
		// fmt.Printf("code-1 %d %d\n", Part, last.val);
		// println!("Part:{}", Part);
		if last.val != nil && last.val.Part == Part {
			last.val.Cnt += 1
		} else {
			last.handle_last()
			last.val = &Rle{Part, 0, 1, true}
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
