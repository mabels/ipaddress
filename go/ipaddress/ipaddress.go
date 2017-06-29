package ipaddress

import "math/big"

type IPAddress struct {
	Ip_bits        *IpBits
	Host_address   big.Int
	Prefix         Prefix
	Mapped         *IPAddress
	Vt_is_private  func(*IPAddress) bool
	Vt_is_loopback func(*IPAddress) bool
	Vt_to_ipv6     func(*IPAddress) *IPAddress
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
