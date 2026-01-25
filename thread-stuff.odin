package thread_stuff

import "core:thread"
import "core:fmt"
import "core:strconv"
import "core:os"
import "core:strings"
import "core:math"
import "core:mem"
import "base:runtime"
import "core:math/rand"
import vmem "core:mem/virtual"

// The number of threads in the pool.
thread_count : uint

do_raw_thread :: proc() {
	
	thread_proc :: proc(t: ^thread.Thread) {
		td := cast(^ThreadDataRaw)t.data
		td.asdf *= 2
	}

	ThreadDataRaw :: struct {
		asdf: int
	}
	
	td := ThreadDataRaw {
		asdf = 5
	}
	
	t := thread.create(thread_proc)
	assert(t != nil)
	t.data = &td
	
	thread.start(t)
	
	thread.join(t)
	thread.destroy(t)
	
	fmt.printfln("t is %v", td.asdf)
}

MULTITHREAD :: #config(MULTITHREAD, false)

main :: proc() {
	
	thread_count = uint(os.processor_core_count())
	fmt.printfln("os processor core count: %v", thread_count)
	
	when MULTITHREAD {
		do_happy_mt()
	} else {
		do_happy_st()
	}
}


// The number of tasks we want to perform.
// These tasks will be distributed among threads of the pool.

SEARCH_LIMIT :: 1_000_123
// SEARCH_LIMIT :: 9

get_start_end :: proc(thread_id: uint) -> (uint, uint) {
	
	ensure(SEARCH_LIMIT > thread_count)
	
	res_start, res_end: uint
	
	chunk_size : uint = SEARCH_LIMIT / thread_count
    remainder : uint = SEARCH_LIMIT % thread_count
    
    res_start = thread_id * chunk_size + 1
    res_end = (thread_id + 1) * chunk_size
    
    if thread_id == 0 {
   		res_start = 0
    }
    
    if thread_id == thread_count - 1 {
    	res_end = SEARCH_LIMIT
    }
	
	// fmt.printfln("thread id: %v, taking numbers from %v to %v. len: %v", thread_id, res_start, res_end, res_end - res_start + 1)
	return res_start, res_end
}

do_happy_mt :: proc() {
	
	pool: thread.Pool
	thread.pool_init(&pool, context.allocator, int(thread_count))
	thread.pool_start(&pool)
	defer thread.pool_destroy(&pool)
	
	task_data_array:= make_slice([]TaskData, thread_count)
	defer delete(task_data_array)
	
	for task_index in 0..<thread_count {
		task_data := &task_data_array[task_index]
		task_data^ = {}
		thread.pool_add_task(&pool, runtime.nil_allocator(), task_handler, task_data, int(task_index))
	}
	thread.pool_finish(&pool)
	
	// Summing the count
	
	result_added : uint
	
	for i in 0..<thread_count {
		task, _ := thread.pool_pop_done(&pool)
		data := cast(^TaskData)task.data
		result_added += data.happy_count
	}
	
	fmt.printfln("number of happy numbers between 0 and %v is %v", SEARCH_LIMIT, result_added)
}

TaskData :: struct {
	happy_count: uint
}

task_handler :: proc(task: thread.Task) {
	data := cast(^TaskData)task.data
	search_start, search_end := get_start_end(uint(task.user_index))
	res: uint
	
	for i in search_start..=search_end {
		if is_number_happy(i) {
			res += 1
		}
	}
	
	data.happy_count = res
}

is_number_happy :: proc(num: uint) -> bool {
	n := num
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
	
	seen := make_map(map[uint]struct{}, context.temp_allocator)
	
	for n != 1 && !(n in seen) {
		seen[n] = {}
		n = sum_squares(n)
	}
	
	return n == 1
}

sum_squares :: proc(n : uint) -> uint {
	n := n
	sum : uint = 0
	for n > 0 {
		digit := n % 10
		sum += digit * digit
		n /= 10
	}
	return sum
}

do_happy_st :: proc() {
	
	res : uint
	
	for i in 0..=SEARCH_LIMIT {
		if is_number_happy(uint(i)) {
			res += 1
		}
	}
	
	fmt.printfln("res is %v", res)
}
