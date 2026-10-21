// Package tally counts words.
package tally

import "strings"

// Words is the number of whitespace-separated words in s.
func Words(s string) int {
	return len(strings.Fields(s))
}

// Lines is the number of lines in s; a final line without a newline counts.
func Lines(s string) int {
	if s == "" {
		return 0
	}
	n := strings.Count(s, "\n")
	if !strings.HasSuffix(s, "\n") {
		n++
	}
	return n
}
