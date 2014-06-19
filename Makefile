AS=nasm
LD=ld
ASFLAGS=-g -f elf64
LDFLAGS=-m elf_x86_64 -dynamic-linker /lib64/ld-linux-x86-64.so.2 -lc -lgmp
EXEC=perfectnb
SRC=perfectnb.asm
OBJ=$(SRC:.asm=.o)
DEPFLAGS= 

all: $(EXEC)
$(EXEC): $(OBJ)
	$(LD) $(LDFLAGS) -o $@ $^
%.o: %.asm
	$(AS) $(ASFLAGS) -o $@ $< 


.PHONY: clean mrproper
clean:
	rm -f $(OBJ)
mrproper: clean
	rm -f *~ $(EXEC)
