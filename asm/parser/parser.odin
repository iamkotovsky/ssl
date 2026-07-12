package parser

import "../lexer"
import "../module/inst"
import "ast"

import "core:strconv"

Parser :: struct {
	l: lexer.Lexer,
}

init :: proc(p: ^Parser, source: string) {
	lexer.init(&p.l, source)
}

@(private)
_next :: proc(p: ^Parser) -> lexer.Token {
	return lexer.next(&p.l)
}

@(private)
_expect :: proc(p: ^Parser, kind: lexer.Token_Kind) -> (lexer.Token, bool) {
	t := _next(p)
	return t, t.kind == kind
}

@(private)
_parse :: proc(p: ^Parser) -> (ast.Module, Error) {
	parsed: ast.Module
	parsed.labels = make(map[string]int)

	for it := _next(p); it.kind != .EOF; it = _next(p) {
		if it.kind == .Line {
			continue
		} else if it.kind == .Inst {
			kind, exists := inst.from_string(it.value)
			if !exists {
				return parsed, _error_at(.Unknown_Inst, it)
			}

			parsed_inst: ast.Inst
			parsed_inst.kind = kind

			it = _next(p)
			if it.kind == .EOF {
				if inst.has_operand(kind) {
					return parsed, _error_at(.Missing_Operand, it)
				}
				append(&parsed.insts, parsed_inst)
				return parsed, _error(.None)
			}
			if it.kind == .Line {
				if inst.has_operand(kind) {
					return parsed, _error_at(.Missing_Operand, it)
				}
				append(&parsed.insts, parsed_inst)
				continue
			}
			if !inst.has_operand(kind) {
				return parsed, _error_at(.Unexpected_Operand, it)
			}

			#partial switch it.kind {
			case .String:
				parsed_inst.operand = ast.make_string(it.value[1:len(it.value) - 1], it)
			case .Int:
				value, ok := strconv.parse_i64(it.value)
				if !ok {
					return parsed, _error_at(.Bad_Int, it)
				}
				parsed_inst.operand = ast.make_int(value, it)
			case .Float:
				value, ok := strconv.parse_f64(it.value)
				if !ok {
					return parsed, _error_at(.Bad_Float, it)
				}
				parsed_inst.operand = ast.make_float(value, it)
			case .Label:
				if len(it.value) == 0 {
					return parsed, _error_at(.Invalid_Label, it)
				}
				parsed_inst.operand = ast.make_label(it.value, it)
			case:
				return parsed, _error_at(.Invalid_Operand, it)
			}

			end := _next(p)
			if end.kind == .EOF {
				append(&parsed.insts, parsed_inst)
				return parsed, _error(.None)
			}
			if end.kind != .Line {
				return parsed, _error_at(.Expected_Newline, end)
			}
			append(&parsed.insts, parsed_inst)
		} else if it.kind == .Label {
			if end, ok := _expect(p, .Line); !ok {
				return parsed, _error_at(.Expected_Newline, end)
			} else if len(it.value) == 0 {
				return parsed, _error_at(.Invalid_Label, it)
			} else if _, exists := parsed.labels[it.value]; exists {
				return parsed, _error_at(.Invalid_Label, it)
			}

			parsed.labels[it.value] = len(parsed.insts)
			append(&parsed.debug_labels, ast.Debug_Label{name = it.value, inst = len(parsed.insts)})
			continue
		} else {
			return parsed, _error_at(.Expected_Inst_Or_Label, it)
		}
	}
	return parsed, _error(.None)
}
