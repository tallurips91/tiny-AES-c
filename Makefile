#CC           = avr-gcc
#CFLAGS       = -Wall -mmcu=atmega16 -Os -Wl,-Map,test.map
#OBJCOPY      = avr-objcopy
#CC           = gcc
#LD           = gcc
CC           = /opt/riscv32i/bin/riscv32-unknown-elf-gcc
LD           = /opt/riscv32i/bin/riscv32-unknown-elf-gcc
AR           = ar
ARFLAGS      = rcs
#CFLAGS       = -Wall -Os -c
#LDFLAGS      = -Wall -Os -Wl,-Map,test.map
CFLAGS       = -c -MD -O3 -march=rv32i -DTIME -DRISCV -Wno-implicit-int -Wno-implicit-function-declaration
LDFLAGS      = -MD -O3 -march=rv32i -DTIME -DRISCV -Wl,-Bstatic,-Map,test.map,--strip-debug -lgcc -lc
ifdef AES192
CFLAGS += -DAES192=1
endif
ifdef AES256
CFLAGS += -DAES256=1
endif

OBJCOPYFLAGS = -j .text -O ihex
OBJCOPY      = /opt/riscv32i/bin/riscv32-unknown-elf-objcopy
OBJDUMP      = /opt/riscv32i/bin/riscv32-unknown-elf-objdump

# include path to AVR library
INCLUDE_PATH = /usr/lib/avr/include
# splint static check
SPLINT       = splint test.c aes.c -I$(INCLUDE_PATH) +charindex -unrecog

default: aes_test.bin

.SILENT:
.PHONY:  lint clean

test.hex : test.elf
	echo copy object-code to new image and format in hex
	$(OBJCOPY) ${OBJCOPYFLAGS} $< $@

test.o : test.c aes.h aes.o
	echo [CC] $@ $(CFLAGS)
	$(CC) $(CFLAGS) -o  $@ $<

aes.o : aes.c aes.h
	echo [CC] $@ $(CFLAGS)
	$(CC) $(CFLAGS) -o $@ $<

test.elf : aes.o test.o
	echo [LD] $@
	$(LD) $(LDFLAGS) -o $@ $^

aes_test.bin : test.elf
	$(OBJCOPY) -O binary test.elf  aes_test.bin
	$(OBJDUMP) -d -M no-aliases test.elf > disass

aes.a : aes.o
	echo [AR] $@
	$(AR) $(ARFLAGS) $@ $^

lib : aes.a

clean:
	rm -f *.OBJ *.LST *.o *.gch *.out *.hex *.map *.elf *.a

test:
	make clean && make && ./test.elf
	make clean && make AES192=1 && ./test.elf
	make clean && make AES256=1 && ./test.elf

lint:
	$(call SPLINT)
