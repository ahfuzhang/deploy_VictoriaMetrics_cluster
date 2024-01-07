package stringsutil

import "unsafe"

// b2s converts byte slice to a string without memory allocation.
// See https://groups.google.com/forum/#!msg/Golang-Nuts/ENgbUzYvCuU/90yGx7GUAgAJ .
func B2s(b []byte) string {
	return unsafe.String(unsafe.SliceData(b), len(b))
}

// s2b converts string to a byte slice without memory allocation.
func S2b(s string) []byte {
	return unsafe.Slice(unsafe.StringData(s), len(s))
}
