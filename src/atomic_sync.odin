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
g_stop :int = 10

MT_SAFE :: #config(MT_SAFE, false)

main :: proc() {
	
	g_data.to_process = 0
	g_data.status = .Loading
	
	th := thread.create_and_start(thread_start)
	
	for {
		if load_status() == .Ready {
			fmt.println("data is ready by loading thread. sending it back")
			g_data.to_process = 0
			store_status(.Loading)
			// Set it back to loading
			g_stop -= 1
		}
		time.sleep(100 * time.Millisecond)
		
		if g_stop <= 0 {
			break
		}
	}
	
	thread.terminate(th, 1)
	
	fmt.printfln("task done")
}

thread_start :: proc() {
	
	for {
		if load_status() == .Loading {
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
