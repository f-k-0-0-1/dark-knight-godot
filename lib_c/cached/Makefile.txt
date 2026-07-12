CC = gcc
WIN_CC = x86_64-w64-mingw32-gcc
OUT_DIR = output

all: dir linux windows

dir:
	mkdir -p $(OUT_DIR)

linux:
	$(CC) peer.c -o $(OUT_DIR)/peer
	$(CC) server.c -o $(OUT_DIR)/server

windows:
	$(WIN_CC) peer.c -o $(OUT_DIR)/peer.exe -lws2_32
	$(WIN_CC) server.c -o $(OUT_DIR)/server.exe -lws2_32

clean:
	rm -rf $(OUT_DIR)/*