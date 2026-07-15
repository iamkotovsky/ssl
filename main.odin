package ssl

import b "bytecode/builder"
import "bytecode"

main :: proc() {
	m: b.Module
	defer b.destroy(&m)

	start := b.export(&m, "__start")

	start_func := b.function(&m, ".__start")
	b.make_int(start_func, 1)
	x := b.local(start_func, "a")
	b.make_int(start_func, 12)
	y := b.local(start_func, "b")
	b.load(start_func, x)
	// b.add

	init := b.init(&m)
	b.make_func(init, start_func)
	b.store(init, start)

	code := b.finish(&m)
	bytecode.print(code)
}
