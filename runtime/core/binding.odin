package core

Binding_Flag :: enum {
	Read_Only,
	Hidden,
}

Binding_Flags :: bit_set[Binding_Flag]

Binding :: struct {
	value: Value,
	flags: Binding_Flags,
}

Read_Only_Binding_Error :: struct {
	name: string,
}

Frozen_Object_Error :: struct {}
Frozen_Class_Error :: struct {}
Sealed_Class_Error :: struct {}
