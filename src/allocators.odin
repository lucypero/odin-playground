package allocators

import "core:fmt"
import "core:mem/virtual"
import "core:mem"
import "base:runtime"

arena : virtual.Arena
arena_alloc : mem.Allocator

print_arena :: proc(desc: string) {
	fmt.printf(desc)
	fmt.printfln(" - us: %v, reserved: %v", arena.total_used, arena.total_reserved)
}

main :: proc() {
	alloc_err := virtual.arena_init_growing(&arena, 1000)
	assert(alloc_err == .None)
	
	arena_alloc = virtual.arena_allocator(&arena)
	print_arena("init")
	
	data := make([]byte, 100, arena_alloc)
	print_arena("after a make")
	do_thing()
	
	print_arena("after proc")
}

do_thing :: proc() {
	// uses mem from arena temporarily
	// temp := virtual.arena_temp_begin(&arena)
	// defer virtual.arena_temp_end(temp)
	TEMP_GUARD(&arena)
	
	print_arena("in proc - before make")
	
	data := make([]byte, 23000, arena_alloc)
	
	print_arena("in proc - after make")
}

@(deferred_out=virtual.arena_temp_end)
TEMP_GUARD :: #force_inline proc(arena: ^virtual.Arena, loc := #caller_location) -> (virtual.Arena_Temp, runtime.Source_Code_Location) {
	return virtual.arena_temp_begin(arena, loc), loc
}
