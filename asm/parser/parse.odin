package parser

import "../../bytecode"
import "ast"

parse :: proc(source: string) -> (bytecode.Module, Error) {
	p: Parser
	init(&p, source)
	parsed, err := _parse(&p)
	defer ast.destroy(&parsed)
	if err.kind != .None {
		return {}, err
	}
	return lower(&parsed)
}
