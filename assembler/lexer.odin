package assembler

import "core:text/scanner"
import "core:unicode"

@(private)
_Token_Kind :: enum {
	EOF,
	Instruction,
	String,
	Integer,
	Float,
	Label,
	Space,
	Line,
	Error,
}

@(private)
_Token :: struct {
	kind:  _Token_Kind,
	value: string,
	line:  int,
	col:   int,
}

@(private)
_Lexer :: struct {
	scanner: scanner.Scanner,
	line:    int,
	col:     int,
}

@(private)
_lexer_init :: proc(l: ^_Lexer, source: string) {
	scanner.init(&l.scanner, source)
	l.line = 1
	l.col = 1
}

@(private)
_lexer_peek :: proc(l: ^_Lexer) -> rune {
	return scanner.peek(&l.scanner)
}

@(private)
_lexer_advance :: proc(l: ^_Lexer) -> rune {
	it := scanner.next(&l.scanner)
	if it == scanner.EOF {
		return it
	}
	if it == '\n' {
		l.line += 1
		l.col = 1
	} else {
		l.col += 1
	}
	return it
}

@(private)
_lexer_parse_kind :: proc(l: ^_Lexer) -> _Token_Kind {
	it := _lexer_advance(l)
	if it == scanner.EOF {
		return .EOF
	} else if it == '\n' {
		for unicode.is_white_space(_lexer_peek(l)) {
			_lexer_advance(l)
		}
		return .Line
	} else if unicode.is_white_space(it) {
		for it := _lexer_peek(l); it != '\n' && unicode.is_white_space(it); it = _lexer_peek(l) {
			_lexer_advance(l)
		}
		return .Space
	} else if unicode.is_digit(it) || (it == '-' && unicode.is_digit(_lexer_peek(l))) {
		for unicode.is_digit(_lexer_peek(l)) {
			_lexer_advance(l)
		}
		if _lexer_peek(l) == '.' {
			_lexer_advance(l)
			for unicode.is_digit(_lexer_peek(l)) {
				_lexer_advance(l)
			}
			return .Float
		}
		return .Integer
	} else if it == '.' {
		for it := _lexer_peek(l);
		    unicode.is_alpha(it) || unicode.is_digit(it) || it == '.' || it == '_';
		    it = _lexer_peek(l) {
			_lexer_advance(l)
		}
		return .Label
	} else if unicode.is_alpha(it) {
		for it := _lexer_peek(l);
		    unicode.is_alpha(it) || unicode.is_digit(it) || it == '.' || it == '_';
		    it = _lexer_peek(l) {
			_lexer_advance(l)
		}
		return .Instruction
	} else if it == '"' {
		for it := _lexer_peek(l); it != scanner.EOF && it != '"' && it != '\n'; it = _lexer_peek(l) {
			_lexer_advance(l)
		}
		if _lexer_advance(l) == '"' {
			return .String
		}
	}
	return .Error
}

@(private)
_lexer_next :: proc(l: ^_Lexer) -> _Token {
	pos := scanner.position(&l.scanner)
	start := pos.offset
	line := l.line
	col := l.col
	kind := _lexer_parse_kind(l)
	if kind == .Space {
		pos = scanner.position(&l.scanner)
		start = pos.offset
		line = l.line
		col = l.col
		kind = _lexer_parse_kind(l)
	}
	end := scanner.position(&l.scanner).offset
	return {kind = kind, value = l.scanner.src[start:end], line = line, col = col}
}
