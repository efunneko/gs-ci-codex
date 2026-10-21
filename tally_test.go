package tally

import "testing"

func TestWords(t *testing.T) {
	for s, want := range map[string]int{"": 0, "one": 1, " two  words ": 2} {
		if got := Words(s); got != want {
			t.Errorf("Words(%q) = %d, want %d", s, got, want)
		}
	}
}
