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

main :: proc() {
	
	g_data.to_process = 0
	g_data.status = .Loading
	
	th := thread.create_and_start(thread_start)
	
	
	for {
		if g_data.status == .Ready {
			fmt.println("data is ready by loading thread. sending it back")
			g_data.to_process = 0
			g_data.status = .Loading
			// Set it back to loading
			g_stop -= 1
		}
		time.sleep(100 * time.Millisecond)
		
		if g_stop <= 0 {
			break
		}
	}
	
	thread.destroy(th)
	
	fmt.printfln("task done")
}

thread_start :: proc() {
	
	for {
		
		if g_data.status == .Loading {
			g_data.to_process = 5
			g_data.status = .Ready
		}
		
		time.sleep(10 * time.Millisecond)
		
		if g_stop <= 0 {
			break
		}
	}
}
