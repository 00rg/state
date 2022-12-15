package greet

import (
	"testing"

	"github.com/google/go-cmp/cmp"
)

func TestGreet(t *testing.T) {
	want := "Greet"
	got := "Greet"
	if diff := cmp.Diff(want, got); diff != "" {
		t.Errorf("(-want +got)\n%s", diff)
	}
}
