package allocators

import "core:fmt"
import "core:mem/virtual"
import "core:mem"
import "base:runtime"

arena : virtual.Arena
arena_alloc : mem.Allocator

scratch : mem.Scratch
scratch_alloc : mem.Allocator

print_arena :: proc(desc: string) {
	fmt.printf(desc)
	fmt.printfln(" - us: %v, reserved: %v", arena.total_used, arena.total_reserved)
}

main :: proc() {
	alloc_err := virtual.arena_init_growing(&arena, 1000)
	assert(alloc_err == .None)
	
	alloc_err = mem.scratch_init(&scratch, 2000)
	assert(alloc_err == .None)
	
	scratch_alloc = mem.scratch_allocator(&scratch)
	
	arena_alloc = virtual.arena_allocator(&arena)
	
	data := make([]byte, 100, arena_alloc)
	do_thing()
	
	
	data = make([]byte, 100, allocator = context.temp_allocator)
}

do_thing :: proc() {
	TEMP_GUARD(&arena)
	// equal to:
	// temp := virtual.arena_temp_begin(&arena)
	// defer virtual.arena_temp_end(temp)
	
	data := make([]byte, 23000, arena_alloc)
}

// Convenience function for clearing used memory in scope
@(deferred_out=virtual.arena_temp_end)
TEMP_GUARD :: #force_inline proc(arena: ^virtual.Arena, loc := #caller_location) -> (virtual.Arena_Temp, runtime.Source_Code_Location) {
	return virtual.arena_temp_begin(arena, loc), loc
}
