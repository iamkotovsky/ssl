package lexer

import "core:text/scanner"
import "core:unicode"

Token_Kind :: enum {
	EOF,
	Inst,
	String,
	Int,
	Float,
	Label,
	Space,
	Line,
	Error,
}

Token :: struct {
	kind:  Token_Kind,
	value: string,
	line:  int,
	col:   int,
}

Lexer :: struct {
	scanner: scanner.Scanner,
	line:    int,
	col:     int,
}

init :: proc(l: ^Lexer, source: string) {
	scanner.init(&l.scanner, source)
	l.line = 1
	l.col = 1
}

@(private)
_peak :: proc(l: ^Lexer) -> rune {
	return scanner.peek(&l.scanner)
}
@(private)
_next :: proc(l: ^Lexer) -> rune {
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
_parse :: proc(l: ^Lexer) -> Token_Kind {
	it := _next(l)
	if it == scanner.EOF {
		return .EOF
	} else if it == '\n' {
		for unicode.is_white_space(_peak(l)) {
			_next(l)
		}
		return .Line
	} else if unicode.is_white_space(it) {
		for it := _peak(l); it != '\n' && unicode.is_white_space(it); it = _peak(l) {
			_next(l)
		}
		return .Space
	} else if unicode.is_digit(it) || (it == '-' && unicode.is_digit(_peak(l))) {
		for unicode.is_digit(_peak(l)) {
			_next(l)
		}
		if _peak(l) == '.' {
			_next(l)
			for unicode.is_digit(_peak(l)) {
				_next(l)
			}
			return .Float
		} else {
			return .Int
		}
	} else if it == '.' {
		for it := _peak(l);
		    unicode.is_alpha(it) || unicode.is_digit(it) || it == '.' || it == '_';
		    it = _peak(l) {
			_next(l)
		}
		return .Label
	} else if unicode.is_alpha(it) {
		for it := _peak(l);
		    unicode.is_alpha(it) || unicode.is_digit(it) || it == '.' || it == '_';
		    it = _peak(l) {
			_next(l)
		}
		return .Inst
	} else if it == '"' {
		for it := _peak(l); it != scanner.EOF && it != '"'; it = _peak(l) {
			_next(l)
		}
		if _next(l) == '"' {
			return .String
		}
	}
	return .Error
}

next :: proc(l: ^Lexer) -> Token {
	pos := scanner.position(&l.scanner)
	start := pos.offset
	line := l.line
	col := l.col
	kind := _parse(l)
	if kind == .Space {
		pos = scanner.position(&l.scanner)
		start = pos.offset
		line = l.line
		col = l.col
		kind = _parse(l)
	}
	end := scanner.position(&l.scanner).offset
	return {kind = kind, value = l.scanner.src[start:end], line = line, col = col}
}
