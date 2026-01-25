odin build thread-stuff.odin -file -o:speed -out:happy-st.exe
odin build thread-stuff.odin -file -o:speed -define:MULTITHREAD=true -out:happy-mt.exe
hyperfine -w 3 happy-st.exe happy-mt.exe
