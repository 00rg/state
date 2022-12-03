package main

import (
	"testing"

	"github.com/google/go-cmp/cmp"
)

func TestPennyName(t *testing.T) {
	want := "Penny2"
	got := "Penny"
	if diff := cmp.Diff(want, got); diff != "" {
		t.Errorf("(-want +got)\n%s", diff)
	}
}
