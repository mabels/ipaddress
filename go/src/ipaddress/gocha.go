package ipaddress

import "fmt"
import "log"
import "math/big"

// type gochaFunc func() string

func describe(desc string, fn func()) {
	fmt.Printf("describe:[%s]\n", desc)
	fn()
}

func it(desc string, fn func()) {
	fmt.Printf("it:[%s]\n", desc)
	fn()
}

func assert(b bool) {
	if (!b) {
		log.Fatal("assert failed")
	}
}

func assert_bool(a bool, b bool) {
	if (a != b) {
		log.Fatal(fmt.Sprintf("[%s] != [%s]", a, b))
	}
}

func assert_string(a string, b string) {
	if (a != b) {
		log.Fatal(fmt.Sprintf("[%s] != [%s]", a, b))
	}
}

func assert_ipaddress(a *IPAddress, b *IPAddress) {
	if (!a.Eq(b)) {
		log.Fatal(fmt.Sprintf("[%s] != [%s]", a, b))
	}
}

func assert_int(a int, b int) {
	if (a != b) {
		log.Fatal(fmt.Sprintf("[%d] != [%d]", a, b))
	}
}

func assert_uint(a uint, b uint) {
	if (a != b) {
		log.Fatal(fmt.Sprintf("[%d] != [%d]", a, b))
	}
}

func assert_bigint(a big.Int, b big.Int) {
	if (a.Cmp(&b) != 0) {
		log.Fatal(fmt.Sprintf("[%s] != [%s]", a.String(), b.String()))
	}
}

func assert_uint8(a uint8, b uint8) {
	if (a != b) {
		log.Fatal(fmt.Sprintf("[%d] != [%d]", a, b))
	}
}

func assert_uint16(a uint16, b uint16) {
	if (a != b) {
		log.Fatal(fmt.Sprintf("[%d] != [%d]", a, b))
	}
}

func assert_uint64(a uint64, b uint64) {
	if (a != b) {
		log.Fatal(fmt.Sprintf("[%d] != [%d]", a, b))
	}
}

func assert_string_array(a []string, b []string) {
	if (len(a) != len(b)) {
		log.Fatal(fmt.Sprintf("len [%d] != [%d]", len(a), len(b)))
	}
	for i := 0; i < len(a); i++ {
		if (a[i] != b[i]) {
			log.Fatal(fmt.Sprintf("%d:[%s] != [%s]", i, a[i], b[i]))
		}
	}
}

func assert_uint16_array(a []uint16, b []uint16) {
	if (len(a) != len(b)) {
		log.Fatal(fmt.Sprintf("len [%d] != [%d]", len(a), len(b)))
	}
	for i := 0; i < len(a); i++ {
		if (a[i] != b[i]) {
			log.Fatal(fmt.Sprintf("%d:[%d] != [%d]", i, a[i], b[i]))
		}
	}
}
