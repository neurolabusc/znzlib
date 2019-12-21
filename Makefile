# Regular use
CFLAGS= -O3

ZFLAGS=-lm -lz
#run "CF=1 make" for cloudflare build
ifeq "$(CF)" "1"
	ifneq ($(OS),Windows_NT)
		OS = $(shell uname)
		ifeq "$(OS)" "Darwin"
			ZFLAGS=-lm  -I./darwin ./darwin/libz.a	
		endif
	endif
endif

all:
	gcc $(CFLAGS) $(ZFLAGS) -o clib_01_read_write clib_01_read_write.c  niftilib/nifti1_io.c znzlib/znzlib.c -I./niftilib -I./znzlib -DHAVE_ZLIB
	