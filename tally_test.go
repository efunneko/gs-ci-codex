package tally

import "testing"

func TestWords(t *testing.T) {
	for s, want := range map[string]int{"": 0, "one": 1, " two  words ": 2} {
		if got := Words(s); got != want {
			t.Errorf("Words(%q) = %d, want %d", s, got, want)
		}
	}
}

func TestLines(t *testing.T) {
	for s, want := range map[string]int{"": 0, "a": 1, "a\n": 1, "a\nb": 2, "a\nb\n": 2} {
		if got := Lines(s); got != want {
			t.Errorf("Lines(%q) = %d, want %d", s, got, want)
		}
	}
}
