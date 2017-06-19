package ipaddress

//
// type IPAddress interface {
//   Parse(str *string) data.ResultIPAddress
//   Is_valid(addr *string) bool
//   Is_valid_netmask(addr *string) bool
//   Is_valid_ipv4(addr *string) bool
//   Is_valid_ipv6(addr *string) bool
// }

// package data

import "math/big"

type IPAddress struct {
	Ip_bits        *IpBits
	Host_address   big.Int
	Prefix         Prefix
	Mapped         *IPAddress
	Vt_is_private  func(*IPAddress) bool
	Vt_is_loopback func(*IPAddress) bool
	Vt_to_ipv6     func(*IPAddress) *IPAddress
	// Vt_parse_netmask           func(*string) (*uint8, *string)
	// Vt_aggregate               func(*[]IPAddress) []IPAddress
	// Vt_sum_first_found
}

type ResultIPAddress interface {
	IsOk() bool
	IsErr() bool
	Unwrap() *IPAddress
	UnwrapErr() *string
}

type ResultIPAddresses interface {
	IsOk() bool
	IsErr() bool
	Unwrap() *[]*IPAddress
	UnwrapErr() *string
}
