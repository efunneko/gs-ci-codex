// Command tally prints the word and line counts of its standard input.
package main

import (
	"fmt"
	"io"
	"os"

	"example.com/tally"
)

func main() {
	b, err := io.ReadAll(os.Stdin)
	if err != nil {
		fmt.Fprintln(os.Stderr, "tally:", err)
		os.Exit(1)
	}
	fmt.Printf("%d words, %d lines\n", tally.Words(string(b)), tally.Lines(string(b)))
}
