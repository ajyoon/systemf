build:
	nasm -f elf64 src/systemf.asm -o bin/systemf.o \
	&& ld bin/systemf.o -o bin/systemf \
	&& rm bin/systemf.o

debug:
	nasm -f elf64 -F dwarf src/systemf.asm -o bin/systemf.o \
	&& ld bin/systemf.o -o bin/systemf \
	&& rm bin/systemf.o

clean:
	find bin/ -type f ! -name ".gitignore" -delete
