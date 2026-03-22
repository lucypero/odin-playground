/*

This program was written to test the thread sanitizer.

Run the thread sanitizer like this, with MT_SAFE=true/false

odin run src/atomic_sync.odin -file -sanitize:thread -define:MT_SAFE=false -debug

Thread sanitizer proves that adding our atomics operations makes the program thread safe.

This is what we get from the thread sanitizer with MT_SAFE=false:

==================
WARNING: ThreadSanitizer: data race (pid=15564)
  Write of size 8 at 0x00000190cfe8 by thread T1:
    #0 atomic_sync::store_status /home/lucy/dev/odin-playground/src/atomic_sync.odin:79:17 (atomic_sync.bin+0x51ceec) (BuildId: 0a0064bb1938127feb49edb186826bb1fe7e24af)
    #1 atomic_sync::thread_start /home/lucy/dev/odin-playground/src/atomic_sync.odin:60:4 (atomic_sync.bin+0x51ce45) (BuildId: 0a0064bb1938127feb49edb186826bb1fe7e24af)
    #2 thread::create_and_start.thread_proc-0 /home/lucy/dev/Odin/core/thread/thread.odin:277:3 (atomic_sync.bin+0x5185ce) (BuildId: 0a0064bb1938127feb49edb186826bb1fe7e24af)
    #3 thread::[thread_unix.odin]::_create.__unix_thread_entry_proc-0 /home/lucy/dev/Odin/core/thread/thread_unix.odin:53:4 (atomic_sync.bin+0x5183ca) (BuildId: 0a0064bb1938127feb49edb186826bb1fe7e24af)

  Previous read of size 8 at 0x00000190cfe8 by main thread:
    #0 atomic_sync::load_status /home/lucy/dev/odin-playground/src/atomic_sync.odin:71:3 (atomic_sync.bin+0x51ce9a) (BuildId: 0a0064bb1938127feb49edb186826bb1fe7e24af)
    #1 atomic_sync::main /home/lucy/dev/odin-playground/src/atomic_sync.odin:32:3 (atomic_sync.bin+0x51cbb3) (BuildId: 0a0064bb1938127feb49edb186826bb1fe7e24af)
    #2 main /home/lucy/dev/Odin/base/runtime/entry_unix.odin:57:4 (atomic_sync.bin+0x51875d) (BuildId: 0a0064bb1938127feb49edb186826bb1fe7e24af)

  Location is global 'atomic_sync::g_data' of size 16 at 0x00000190cfe0 (atomic_sync.bin+0x190cfe8)

  Thread T1 (tid=15566, running) created by main thread at:
    #0 pthread_create <null> (atomic_sync.bin+0x45e63f) (BuildId: 0a0064bb1938127feb49edb186826bb1fe7e24af)
    #1 thread::[thread_unix.odin]::_create /home/lucy/dev/Odin/core/thread/thread_unix.odin:121:2 (atomic_sync.bin+0x517a27) (BuildId: 0a0064bb1938127feb49edb186826bb1fe7e24af)
    #2 thread::create /home/lucy/dev/Odin/core/thread/thread.odin:110:2 (atomic_sync.bin+0x517b4a) (BuildId: 0a0064bb1938127feb49edb186826bb1fe7e24af)
    #3 thread::create_and_start /home/lucy/dev/Odin/core/thread/thread.odin:279:7 (atomic_sync.bin+0x517f02) (BuildId: 0a0064bb1938127feb49edb186826bb1fe7e24af)
    #4 atomic_sync::main /home/lucy/dev/odin-playground/src/atomic_sync.odin:29:2 (atomic_sync.bin+0x51cb95) (BuildId: 0a0064bb1938127feb49edb186826bb1fe7e24af)
    #5 main /home/lucy/dev/Odin/base/runtime/entry_unix.odin:57:4 (atomic_sync.bin+0x51875d) (BuildId: 0a0064bb1938127feb49edb186826bb1fe7e24af)

SUMMARY: ThreadSanitizer: data race /home/lucy/dev/odin-playground/src/atomic_sync.odin:79:17 in atomic_sync::store_status

*/

package atomic_sync

import "core:fmt"
import "core:sync"
import "core:thread"
import "core:time"

Status :: enum {
	Free,
	Loading,
	Ready
}

DataToProcess :: struct {
	to_process: int,
	status: Status
}

g_data: DataToProcess
g_stop: int = 10

MT_SAFE :: #config(MT_SAFE, false)

main :: proc() {
	
	g_data.to_process = 0
	g_data.status = .Loading
	
	th := thread.create_and_start(thread_start)
	
	for {
		if load_status() == .Ready {
			fmt.println("data is ready by loading thread. sending it back")
			g_data.to_process = 0
			if g_stop == 1 {
				g_data.to_process = -1
			}

			store_status(.Loading)
			// Set it back to loading
			g_stop -= 1
			if g_stop == 0 do break
		}
		time.sleep(100 * time.Millisecond)
		
	}
	
	thread.destroy(th)
	
	fmt.printfln("task done")
}

thread_start :: proc() {
	for {
		if load_status() == .Loading {
			if g_data.to_process == -1 do break
			g_data.to_process = 5
			store_status(.Ready)
		}
		
		time.sleep(10 * time.Millisecond)
	}
}

load_status :: #force_inline proc() -> Status {
	when MT_SAFE {
		return sync.atomic_load_explicit(&g_data.status, .Acquire)
	} else {
		return g_data.status
	}
}

store_status :: #force_inline proc(status: Status) {
	when MT_SAFE {
		sync.atomic_store_explicit(&g_data.status, status, .Release)
	} else {
		g_data.status = status
	}
}
