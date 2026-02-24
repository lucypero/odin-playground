/*
This has been solved. The "bug" was due to a tiny int encoding optimization that wasn't being handled by
my decoding proc.

https://github.com/odin-lang/Odin/issues/4661


*/

package main

import "base:intrinsics"
import "core:bytes"
import "core:encoding/cbor"
import "core:fmt"
import "core:os"

TrickyType :: struct {
	b: u8,
}

Thing :: struct {
	num:    int,
	tricky: TrickyType,
	b:      int,
}

cbor_repr :: proc() -> bool {
	the_thing := Thing {
		num = 29194,
		tricky = {b = 255},
		b = 5,
	}
	marsh_and_unmarshall_thing(the_thing, "first") or_return
	the_thing.tricky.b = 23
	marsh_and_unmarshall_thing(the_thing, "second") or_return
	return true
}

marsh_and_unmarshall_thing :: proc(thing: Thing, test_name: string) -> bool {

	// marshalling
	marshal_flags := cbor.Encoder_Flags {
		.Self_Described_CBOR,
		//  .Deterministic_Int_Size, .Deterministic_Float_Size, .Deterministic_Map_Sorting
	}

	bin, err := cbor.marshal_into_bytes(thing, flags = marshal_flags)
	if err != nil {
		fmt.eprintfln("cbor marshal error %v", err)
		return false
	}

	// unmarshalling

	the_thing_back: Thing
	decoder_flags: cbor.Decoder_Flags = {.Disallow_Streaming, .Trusted_Input, .Shrink_Excess}
	// uncomment following line to print the diagnostic cbor
	// print_diagnosis(bin) or_return
	derr2 := cbor.unmarshal_from_string(string(bin), &the_thing_back, flags = decoder_flags)
	if derr2 != nil {
		fmt.eprintfln("test name: %v, cbor unmarshal error: %v", test_name, derr2)
		return false
	}

	fmt.printfln("test name: %v, all good!", test_name)

	return true
}

main :: proc() {

	RAW_TAG_NR_TRICKY :: 200
	// registering types

	tricky_type_tag_impl := cbor.Tag_Implementation {
		marshal = proc(
			_: ^cbor.Tag_Implementation,
			e: cbor.Encoder,
			v: any,
		) -> cbor.Marshal_Error {
			cbor._encode_u8(e.writer, RAW_TAG_NR_TRICKY, .Tag) or_return
			the_val: u8 = (cast(^u8)v.data)^
			err := cbor._encode_u8(e.writer, the_val, .Unsigned)
			return err
		},
		unmarshal = proc(
			_: ^cbor.Tag_Implementation,
			d: cbor.Decoder,
			_: cbor.Tag_Number,
			v: any,
		) -> cbor.Unmarshal_Error {
			hdr := cbor._decode_header(d.reader) or_return
			maj, add := cbor._header_split(hdr)
			if maj != .Unsigned {
				return .Bad_Tag_Value
			}

			val, err := cbor._decode_u8(d.reader)
			if err != .None {
				return err
			}
			intrinsics.mem_copy_non_overlapping(v.data, &val, 1)
			return nil
		},
	}

	cbor.tag_register_type(tricky_type_tag_impl, RAW_TAG_NR_TRICKY, TrickyType)

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
	decoded, derr := cbor.decode(string(nes_binary), allocator = context.temp_allocator)
	if derr != nil {
		fmt.eprintln("decode error")
		return false
	}

	diagnosis, eerr := cbor.to_diagnostic_format_string(
		decoded,
		allocator = context.temp_allocator,
	)
	if eerr != nil {
		fmt.eprintln("to diagnostic error")
		return false
	}

	fmt.println(diagnosis)

	return true
}
