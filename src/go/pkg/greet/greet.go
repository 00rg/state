package greet

import (
	"fmt"

	"github.com/thanhpk/randstr"
)

type Greet struct {
	subject string
}

func New(subject string) Greet {
	return Greet{subject: subject}
}

func (g *Greet) Say() string {
	v := randstr.Hex(16)
	return fmt.Sprintf("Hello, %v (%v)!", g.subject, v)
}
