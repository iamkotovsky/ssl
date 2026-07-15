package assembler

import "../bytecode"
import "core:strconv"
import "core:strings"

@(private)
_Parser :: struct {
	lexer:            _Lexer,
	module_builder:   bytecode.Module_Builder,
	function_builder: bytecode.Function_Builder,
	labels:           [dynamic]_Label_Symbol,
	label_indices:    map[string]int,
	fixups:           [dynamic]_Label_Fixup,
}

@(private)
@(rodata)
_OPCODE_NAMES := [bytecode.Opcode]string {
	.None          = "none",
	.Load_Global   = "load.global",
	.Load_Local    = "load.local",
	.Load_Capture  = "load.capture",
	.Store_Global  = "store.global",
	.Store_Local   = "store.local",
	.Store_Capture = "store.capture",
	.Make_I8       = "make.i8",
	.Make_I16      = "make.i16",
	.Make_I32      = "make.i32",
	.Make_I64      = "make.i64",
	.Make_F32      = "make.f32",
	.Make_F64      = "make.f64",
	.Make_String   = "make.string",
	.Make_Class    = "make.class",
	.Make_Function = "make.func",
	.Make_List     = "make.list",
	.Call          = "call",
	.Return        = "ret",
	.Jump          = "jump",
	.Get_Field     = "field.get",
	.Set_Field     = "field.set",
	.Add           = "add",
	.Sub           = "sub",
	.Mul           = "mul",
	.Div           = "div",
	.Halt          = "halt",
}

@(private)
_parser_init :: proc(p: ^_Parser, source: string) {
	_lexer_init(&p.lexer, source)
	p.label_indices = make(map[string]int)
}

@(private)
_parser_destroy :: proc(p: ^_Parser) {
	bytecode.destroy_function_builder(&p.function_builder)
	bytecode.destroy_module_builder(&p.module_builder)
	delete(p.labels)
	delete(p.label_indices)
	delete(p.fixups)
}

@(private)
_parser_next :: proc(p: ^_Parser) -> _Token {
	return _lexer_next(&p.lexer)
}

@(private)
_opcode_from_string :: proc(value: string) -> (bytecode.Opcode, bool) {
	for opcode in bytecode.Opcode {
		if _OPCODE_NAMES[opcode] == value {
			return opcode, true
		}
	}
	return .None, false
}

@(private)
_opcode_operand :: proc(opcode: bytecode.Opcode) -> bytecode.Operand_Kind {
	return bytecode.opcode_operand_kind(opcode)
}

@(private)
_opcode_has_operand :: proc(opcode: bytecode.Opcode) -> bool {
	return _opcode_operand(opcode) != .None
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
_parse_u32 :: proc(token: _Token) -> (u32, Error) {
	if token.kind != .Integer {
		return 0, _error_at(.Invalid_Operand_Type, token)
	}
	value, err := _parse_integer(token)
	if err.kind != .None {
		return 0, err
	}
	if value < 0 || value > i64(max(u32)) {
		return 0, _error_at(.Integer_Out_Of_Range, token)
	}
	return u32(value), _error(.None)
}

@(private)
_emit_instruction :: proc(p: ^_Parser, opcode: bytecode.Opcode, token: _Token) -> Error {
	switch _opcode_operand(opcode) {
	case .None:
		bytecode.emit(&p.function_builder, opcode)
	case .I8:
		if token.kind != .Integer {
			return _error_at(.Invalid_Operand_Type, token)
		}
		value, err := _parse_integer(token)
		if err.kind != .None {
			return err
		}
		if value < i64(min(i8)) || value > i64(max(i8)) {
			return _error_at(.Integer_Out_Of_Range, token)
		}
		bytecode.emit(&p.function_builder, opcode, i8(value))
	case .I16:
		if token.kind != .Integer {
			return _error_at(.Invalid_Operand_Type, token)
		}
		value, err := _parse_integer(token)
		if err.kind != .None {
			return err
		}
		if value < i64(min(i16)) || value > i64(max(i16)) {
			return _error_at(.Integer_Out_Of_Range, token)
		}
		bytecode.emit(&p.function_builder, opcode, i16(value))
	case .I32:
		if token.kind != .Integer {
			return _error_at(.Invalid_Operand_Type, token)
		}
		value, err := _parse_integer(token)
		if err.kind != .None {
			return err
		}
		if value < i64(min(i32)) || value > i64(max(i32)) {
			return _error_at(.Integer_Out_Of_Range, token)
		}
		bytecode.emit(&p.function_builder, opcode, i32(value))
	case .I64:
		if token.kind != .Integer {
			return _error_at(.Invalid_Operand_Type, token)
		}
		value, err := _parse_integer(token)
		if err.kind != .None {
			return err
		}
		bytecode.emit(&p.function_builder, opcode, value)
	case .F32:
		if token.kind != .Float {
			return _error_at(.Invalid_Operand_Type, token)
		}
		value, err := _parse_float(token)
		if err.kind != .None {
			return err
		}
		bytecode.emit(&p.function_builder, opcode, f32(value))
	case .F64:
		if token.kind != .Float {
			return _error_at(.Invalid_Operand_Type, token)
		}
		value, err := _parse_float(token)
		if err.kind != .None {
			return err
		}
		bytecode.emit(&p.function_builder, opcode, value)
	case .Constant:
		if token.kind != .String {
			return _error_at(.Invalid_Operand_Type, token)
		}
		value := token.value[1:len(token.value) - 1]
		constant := bytecode.add_utf8(&p.module_builder, value)
		bytecode.emit(&p.function_builder, opcode, constant)
	case .Function:
		value, err := _parse_u32(token)
		if err.kind != .None {
			return err
		}
		bytecode.emit(&p.function_builder, opcode, bytecode.Function_Index(value))
	case .Global:
		value, err := _parse_u32(token)
		if err.kind != .None {
			return err
		}
		bytecode.emit(&p.function_builder, opcode, bytecode.Global_Index(value))
	case .Target:
		if token.kind != .Label || len(token.value) <= 1 {
			return _error_at(.Invalid_Operand_Type, token)
		}
		label := _get_or_create_label(p, token.value, token)
		instruction := bytecode.emit(&p.function_builder, opcode, bytecode.Instruction_Index(0))
		append(&p.fixups, _Label_Fixup{instruction, label})
		return _error(.None)
	case .Local:
		value, err := _parse_u32(token)
		if err.kind != .None {
			return err
		}
		bytecode.emit(&p.function_builder, opcode, bytecode.Local_Index(value))
	case .Capture:
		value, err := _parse_u32(token)
		if err.kind != .None {
			return err
		}
		bytecode.emit(&p.function_builder, opcode, bytecode.Capture_Index(value))
	case .Count:
		value, err := _parse_u32(token)
		if err.kind != .None {
			return err
		}
		bytecode.emit(&p.function_builder, opcode, value)
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
	expects_operand := _opcode_has_operand(opcode)
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

	index := _get_or_create_label(p, token.value)
	symbol := &p.labels[index]
	if symbol.defined {
		return _error_at(.Invalid_Label, token)
	}
	symbol.instruction = bytecode.position(&p.function_builder)
	symbol.defined = true
	return _error(.None)
}

@(private)
_finish :: proc(p: ^_Parser) -> (bytecode.Module, Error) {
	for symbol in p.labels {
		if !symbol.defined {
			return {}, _error_at(.Label_Not_Defined, symbol.first_reference)
		}
		if int(symbol.instruction) >= len(p.function_builder.instructions) {
			return {}, _error(.Build_Failed)
		}
	}

	for fixup in p.fixups {
		target := p.labels[fixup.label].instruction
		bytecode.patch_target(&p.function_builder, fixup.instruction, target)
	}

	function := bytecode.finish_function(&p.function_builder)
	initializer := bytecode.add_function(&p.module_builder, function)
	bytecode.set_initializer(&p.module_builder, initializer)

	if len(p.labels) > 0 {
		labels := make([]bytecode.Debug_Label, len(p.labels))
		for symbol, index in p.labels {
			labels[index] = {
				name        = strings.clone(symbol.name),
				instruction = symbol.instruction,
			}
		}
		bytecode.add_function_debug(
			&p.module_builder,
			bytecode.Function_Debug_Info{function = initializer, labels = labels},
		)
	}

	return bytecode.finish_module(&p.module_builder), _error(.None)
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
