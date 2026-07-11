package core

Error_Code :: enum{
	No_Meta_Call,
}

Error :: struct {
	using _: Object,
	code:    Error_Code,
}

new_error :: proc(stdi: ^Interface, code: Error_Code) -> ^Error {
	instance := cast(^Error) alloc(stdi, stdi.error, new(Error))
	instance.code = code
	return instance
}
