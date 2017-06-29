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
		return
	}
	_last := self.val
	Max_rles, ok := self.Max_Poses[_last.Part]
	if !ok {
		Max_rles = make([]int, 0)
		self.Max_Poses[_last.Part] = Max_rles
	}
	for _, idx := range Max_rles {
		prev := &self.ret[idx]
		if prev.Cnt > _last.Cnt {
			_last.Max = false
		}
		if prev.Cnt == _last.Cnt {
			// nothing
		}
		if prev.Cnt < _last.Cnt {
			prev.Max = false
		}
	}
	self.Max_Poses[_last.Part] = append(Max_rles, len(self.ret))
	_last.Pos = len(self.ret)
	self.ret = append(self.ret, *_last)
}

func Code(Parts []uint16) []Rle {
	last := Last{nil, make(map[uint16][]int), make([]Rle, 0)}
	for i := 0; i < len(Parts); i++ {
		Part := Parts[i]
		if last.val != nil && last.val.Part == Part {
			last.val.Cnt += 1
		} else {
			last.handle_last()
			last.val = &Rle{Part, 0, 1, true}
		}
	}
	last.handle_last()
	return last.ret
}
