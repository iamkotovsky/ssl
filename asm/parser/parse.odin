package parser

import "../module"
import "ast"

parse :: proc(source: string) -> (module.Module, Error) {
	p: Parser
	init(&p, source)
	parsed, err := _parse(&p)
	defer ast.destroy(&parsed)
	if err.kind != .None {
		return {}, err
	}
	return lower(&parsed)
}
