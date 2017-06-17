package ipaddress

type ByAddress struct {
  addrs []*IPAddress
}

func (s ByAddress) Len() int      { return len(s.addrs) }
func (s ByAddress) Swap(i, j int) { s.addrs[i], s.addrs[j] = s.addrs[j], s.addrs[i] }

// ByName implements sort.Interface by providing Less and using the Len and
// Swap methods of the embedded Organs value.

func (s ByAddress) Less(i, j int) bool { return s.addrs[i].Cmp(s.addrs[j]) < 0 }
