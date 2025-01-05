/*
now cbor lib doesn't support serialization of raw unions.
run this again if they decide to support it.
*/

package main

import "base:intrinsics"
import "core:bytes"
import "core:encoding/cbor"
import "core:fmt"
import "core:os"

// unsupported: raw union
TrickyTypeRawUnion :: struct #raw_union {
	b: u8,
	a: u8,
}

// supported: bit fields
TrickyTypeBitField :: struct {
	a: bit_field u8 {
		a: u8 | 8,
	},
}

cbor_repr :: proc() -> bool {
	marsh_and_unmarshall_thing(TrickyTypeBitField{}, "bit field type") or_return
	marsh_and_unmarshall_thing(TrickyTypeRawUnion{}, "struct with a raw union field") or_return
	return true
}

marsh_and_unmarshall_thing :: proc(thing: $T, test_name: string) -> bool {
	bin, err := cbor.marshal_into_bytes(thing)
	if err != nil {
		fmt.eprintfln("cbor marshal error %v", err)
		return false
	}
	the_thing_back: T
	// uncomment following line to print the diagnostic cbor
	// print_diagnosis(bin) or_return
	derr2 := cbor.unmarshal_from_string(string(bin), &the_thing_back)
	if derr2 != nil {
		fmt.eprintfln("test name: %v, cbor unmarshal error: %v", test_name, derr2)
		return false
	}

	fmt.printfln("test name: %v, all good!", test_name)

	return true
}

main :: proc() {
	// encode/decode test

	res := cbor_repr()
	if res {
		fmt.println("all good")
	} else {
		fmt.println("something went wrong")
	}
}

print_diagnosis :: proc(nes_binary: []u8) -> bool {
	// debugging
	decoded, derr := cbor.decode(string(nes_binary))
	if derr != nil {
		fmt.eprintln("decode error")
		return false
	}

	diagnosis, eerr := cbor.to_diagnostic_format_string(decoded)
	if eerr != nil {
		fmt.eprintln("to diagnostic error")
		return false
	}

	fmt.println(diagnosis)

	return true
}
