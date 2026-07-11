package token

Kind :: enum {
	EOF,
}

Token :: struct {
	kind:       Kind,
	start, end: int,
}

make :: proc(kind: Kind, start, end: int) -> Token {
	return Token{kind, start, end}
}
