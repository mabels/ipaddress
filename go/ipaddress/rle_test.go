package ipaddress

import "testing"

func error(t *MyTesting, node string, l []Rle, r []Rle) {
	llen := len(l)
	rlen := len(r)
	len := llen
	if len < rlen {
		len = rlen
	}
	for i := 0; i < len; i++ {
		ldata := "*****"
		cmp := "!"
		if i < llen && i < rlen {
			if l[i].Equal(r[i]) {
				cmp = "="
			}
		}
		if i < llen {
			ldata = l[i].String()
		}
		rdata := "*****"
		if i < rlen {
			rdata = r[i].String()
		}
		t.t.Errorf("%d(%s): %s<-%s->%s\n", i, node, ldata, cmp, rdata)
	}
}

func cmpRle(t *MyTesting, node string, l []Rle, r []Rle) {
	if len(l) != len(r) {
		error(t, node, l, r)
		return
	}
	for i := 0; i < len(l); i++ {
		if !l[i].Equal(r[i]) {
			error(t, node, l, r)
			return
		}
	}
	return
}

func TestRleCode(tx *testing.T) {
	t := &MyTesting{tx}
	// people := []Person{
	//     {"Bob", 31},
	//     {"John", 42},
	//     {"Michael", 17},
	//     {"Jenny", 26},
	// }
	//
	// fmt.Println(people)
	// sort.Sort(ByAge(people))
	// fmt.Println(people)
	//
	// // Output:
	// // [Bob: 31 John: 42 Michael: 17 Jenny: 26]
	// // [Michael: 17 Jenny: 26 Bob: 31 John: 42]

	cmpRle(t, "-1", Code([]uint16{}), []Rle{})
	cmpRle(t, "-2", Code([]uint16{4711}), []Rle{Rle{4711, 0, 1, true}})
	cmpRle(t, "-3", Code([]uint16{4711, 4711}), []Rle{Rle{
		4711,
		0,
		2,
		true,
	}})
	cmpRle(t, "-4", Code([]uint16{4711, 4711, 4811}), []Rle{Rle{
		4711,
		0,
		2,
		true,
	},
		Rle{
			4811,
			1,
			1,
			true,
		}})
	cmpRle(t, "-5", Code([]uint16{4711, 4711, 4811, 4711, 4711}), []Rle{Rle{
		4711,
		0,
		2,
		true,
	},
		Rle{
			4811,
			1,
			1,
			true,
		},
		Rle{
			4711,
			2,
			2,
			true,
		}})
	cmpRle(t, "-6", Code([]uint16{4711, 4711, 4711, 4811, 4711, 4711}),
		[]Rle{Rle{4711, 0, 3, true}, Rle{4811, 1, 1, true}, Rle{4711, 2, 2, false}})
	cmpRle(t, "-7", Code([]uint16{4711, 4711, 4711, 4811, 4711, 4711, 4911, 4911, 4911}),
		[]Rle{Rle{4711, 0, 3, true},
			Rle{4811, 1, 1, true},
			Rle{4711, 2, 2, false},
			Rle{4911, 3, 3, true}})

	cmpRle(t, "--8", Code([]uint16{0x2001, 0x888, 0, 0x6630, 0, 0, 0, 0}),
		[]Rle{Rle{0x2001, 0, 1, true},
			Rle{0x888, 1, 1, true},
			Rle{0, 2, 1, false},
			Rle{0x6630, 3, 1, true},
			Rle{0, 4, 4, true}})
}
