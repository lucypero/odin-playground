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

main :: proc() {
	// do_raw_thread()
	st_answer_1, st_answer_2 := do_puzzle_singlethread()
	do_puzzle_mt()
}

// The number of threads in the pool.
THREAD_COUNT :: 8

// The number of tasks we want to perform.
// These tasks will be distributed among threads of the pool.
TASK_COUNT :: 64

do_puzzle_mt :: proc() {
	pool: thread.Pool
	
	pool_allocator: mem.Allocator
	pool_allocator = context.allocator
	thread.pool_init(&pool, pool_allocator, THREAD_COUNT)
	thread.pool_start(&pool)
	defer thread.pool_destroy(&pool)
	
	task_data_array: [TASK_COUNT]TaskData
	
	for task_index in 0..<TASK_COUNT {
		
		task_allocator: mem.Allocator
		
		task_allocator = runtime.nil_allocator()
		task_data := &task_data_array[task_index]
		task_data^ = {
			a = int(rand.int31_max(100)),
		}
		
		thread.pool_add_task(&pool, task_allocator, task_handler, task_data, task_index)
	}
	thread.pool_finish(&pool)
	
	result_added : int
	
	for i in 0..<TASK_COUNT {
		task, _ := thread.pool_pop_done(&pool)
		data := cast(^TaskData)task.data
		result_added += data.a_out
	}
	
	fmt.printfln("res is %v", result_added)
}

TaskData :: struct {
	a: int,
	a_out: int
}

task_handler :: proc(task: thread.Task) {
	data := cast(^TaskData)task.data
	
	// processes taskdata and stores the output in the same struct
	data.a_out = data.a * 2
}

// returns the answers
do_puzzle_singlethread :: proc() -> (int, int){
	
	the_input, ok := os.read_entire_file("aoc1.input")
	assert(ok)
	
	lines := strings.split_lines(string(the_input))
	
	return part_one(lines), part_two(lines)
}

part_one :: proc (lines : []string) -> int {
	
	// dial starts at 50
	cur_number : int = 50
	zero_hits : int
	
	for line in lines {
		// gettin number
		if len(line) == 0 do continue
		dial_turn, ok := strconv.parse_int(line[1:], 10)
		assert(ok)
		
		if line[0] == 'L' do dial_turn *= -1
		cur_number = turn_dial(cur_number, dial_turn)
		
		if cur_number == 0 {
			zero_hits += 1
		}
	}
	
	// right answer: 1055
	return zero_hits
}

part_two :: proc(lines : []string) -> int {
	
	// dial starts at 50
	cur_number : int = 50
	zero_hits : int
	
	for line in lines {
		// gettin number
		if len(line) == 0 do continue
		dial_turn, ok := strconv.parse_int(line[1:], 10)
		assert(ok)
		
		prev_number := cur_number
		if line[0] == 'L' do dial_turn *= -1
		
		// turning dial
		cur_number = turn_dial(cur_number, dial_turn)
		
		// counting zero hits
		zero_hits += math.abs(dial_turn) / 100
		after_number := prev_number + (dial_turn % 100)
		
		if prev_number != 0 && (after_number <= 0 || after_number > 99) {
			zero_hits += 1
		}
	}

	// right answer: 6386
	return zero_hits
}

turn_dial :: proc(prev_numb, turn_by: int) -> int {
	return (prev_numb + turn_by) %% 100
}
