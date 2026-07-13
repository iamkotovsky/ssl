package assembler

import "../bytecode"
import "core:strconv"

@(private)
_Parser :: struct {
	lexer:         _Lexer,
	builder:       bytecode.Builder,
	labels:        [dynamic]_Label_Symbol,
	label_indices: map[string]int,
}

@(private)
_parser_init :: proc(p: ^_Parser, source: string) {
	_lexer_init(&p.lexer, source)
	p.label_indices = make(map[string]int)
}

@(private)
_parser_destroy :: proc(p: ^_Parser) {
	bytecode.destroy_builder(&p.builder)
	delete(p.labels)
	delete(p.label_indices)
}

@(private)
_parser_next :: proc(p: ^_Parser) -> _Token {
	return _lexer_next(&p.lexer)
}

@(private)
_opcode_from_string :: proc(value: string) -> (bytecode.Opcode, bool) {
	for opcode in bytecode.Opcode {
		if bytecode.opcode_name(opcode) == value {
			return opcode, true
		}
	}
	return .None, false
}

@(private)
_parse_integer :: proc(token: _Token) -> (i64, Error) {
	value, ok := strconv.parse_i64(token.value)
	if !ok {
		return 0, _error_at(.Bad_Integer, token)
	}
	return value, _error(.None)
}

@(private)
_parse_float :: proc(token: _Token) -> (f64, Error) {
	value, ok := strconv.parse_f64(token.value)
	if !ok {
		return 0, _error_at(.Bad_Float, token)
	}
	return value, _error(.None)
}

@(private)
_emit_instruction :: proc(p: ^_Parser, opcode: bytecode.Opcode, operand: _Token) -> Error {
	build_error: bytecode.Builder_Error
	switch bytecode.opcode_operand(opcode) {
	case .None:
		_, build_error = bytecode.emit(&p.builder, opcode)
	case .I8:
		if operand.kind != .Integer {
			return _error_at(.Invalid_Operand_Type, operand)
		}
		value, err := _parse_integer(operand)
		if err.kind != .None {
			return err
		}
		if value < i64(min(i8)) || value > i64(max(i8)) {
			return _error_at(.Integer_Out_Of_Range, operand)
		}
		_, build_error = bytecode.emit(&p.builder, opcode, i8(value))
	case .I16:
		if operand.kind != .Integer {
			return _error_at(.Invalid_Operand_Type, operand)
		}
		value, err := _parse_integer(operand)
		if err.kind != .None {
			return err
		}
		if value < i64(min(i16)) || value > i64(max(i16)) {
			return _error_at(.Integer_Out_Of_Range, operand)
		}
		_, build_error = bytecode.emit(&p.builder, opcode, i16(value))
	case .I32:
		if operand.kind != .Integer {
			return _error_at(.Invalid_Operand_Type, operand)
		}
		value, err := _parse_integer(operand)
		if err.kind != .None {
			return err
		}
		if value < i64(min(i32)) || value > i64(max(i32)) {
			return _error_at(.Integer_Out_Of_Range, operand)
		}
		_, build_error = bytecode.emit(&p.builder, opcode, i32(value))
	case .I64:
		if operand.kind != .Integer {
			return _error_at(.Invalid_Operand_Type, operand)
		}
		value, err := _parse_integer(operand)
		if err.kind != .None {
			return err
		}
		_, build_error = bytecode.emit(&p.builder, opcode, value)
	case .F32:
		if operand.kind != .Float {
			return _error_at(.Invalid_Operand_Type, operand)
		}
		value, err := _parse_float(operand)
		if err.kind != .None {
			return err
		}
		_, build_error = bytecode.emit(&p.builder, opcode, f32(value))
	case .F64:
		if operand.kind != .Float {
			return _error_at(.Invalid_Operand_Type, operand)
		}
		value, err := _parse_float(operand)
		if err.kind != .None {
			return err
		}
		_, build_error = bytecode.emit(&p.builder, opcode, value)
	case .Constant:
		if operand.kind != .String {
			return _error_at(.Invalid_Operand_Type, operand)
		}
		value := operand.value[1:len(operand.value) - 1]
		constant := bytecode.make_constant(&p.builder, value)
		_, build_error = bytecode.emit(&p.builder, opcode, constant)
	case .Target:
		if operand.kind != .Label || len(operand.value) <= 1 {
			return _error_at(.Invalid_Operand_Type, operand)
		}
		target := _get_or_create_label(p, operand.value, operand)
		_, build_error = bytecode.emit(&p.builder, opcode, target)
	}
	if build_error != nil {
		return _build_error_at(build_error, operand)
	}
	return _error(.None)
}

@(private)
_parse_instruction :: proc(p: ^_Parser, token: _Token) -> Error {
	opcode, ok := _opcode_from_string(token.value)
	if !ok {
		return _error_at(.Unknown_Instruction, token)
	}

	operand := _parser_next(p)
	expects_operand := bytecode.opcode_has_operand(opcode)
	if operand.kind == .EOF || operand.kind == .Line {
		if expects_operand {
			return _error_at(.Missing_Operand, operand)
		}
		return _emit_instruction(p, opcode, operand)
	}
	if !expects_operand {
		return _error_at(.Unexpected_Operand, operand)
	}

	err := _emit_instruction(p, opcode, operand)
	if err.kind != .None {
		return err
	}
	end := _parser_next(p)
	if end.kind != .EOF && end.kind != .Line {
		return _error_at(.Expected_Newline, end)
	}
	return _error(.None)
}

@(private)
_parse_label :: proc(p: ^_Parser, token: _Token) -> Error {
	if len(token.value) <= 1 {
		return _error_at(.Invalid_Label, token)
	}
	end := _parser_next(p)
	if end.kind != .Line {
		return _error_at(.Expected_Newline, end)
	}

	label := _get_or_create_label(p, token.value)
	index := p.label_indices[token.value]
	symbol := &p.labels[index]
	if symbol.defined {
		return _error_at(.Invalid_Label, token)
	}
	if build_error := bytecode.bind_label(&p.builder, label); build_error != nil {
		return _build_error_at(build_error, token)
	}
	symbol.defined = true
	return _error(.None)
}

@(private)
_finish :: proc(p: ^_Parser) -> (bytecode.Module, Error) {
	for symbol in p.labels {
		if !symbol.defined {
			return {}, _error_at(.Label_Not_Defined, symbol.first_reference)
		}
	}
	module, build_error := bytecode.finish(&p.builder)
	if build_error != nil {
		return {}, _build_error_at(build_error)
	}
	return module, _error(.None)
}

parse :: proc(source: string) -> (bytecode.Module, Error) {
	p: _Parser
	_parser_init(&p, source)
	defer _parser_destroy(&p)

	for {
		token := _parser_next(&p)
		#partial switch token.kind {
		case .EOF:
			return _finish(&p)
		case .Line:
			continue
		case .Instruction:
			err := _parse_instruction(&p, token)
			if err.kind != .None {
				return {}, err
			}
		case .Label:
			err := _parse_label(&p, token)
			if err.kind != .None {
				return {}, err
			}
		case:
			return {}, _error_at(.Expected_Instruction_Or_Label, token)
		}
	}
}
