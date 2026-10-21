// Package tally counts words.
package tally

import "strings"

// Words is the number of whitespace-separated words in s.
func Words(s string) int {
	return len(strings.Fields(s))
}
