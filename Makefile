CFLAGS += -Wall -Wextra -Wpedantic -I.
STRIP ?= strip

mdr: mdr.o generated/prep.o generated/tangle.o generated/weave.o
	${CC} ${LDFLAGS} -o $@ $^ -flto
#	${STRIP} $^

mdr_debug: mdr.g generated/prep.g generated/tangle.g generated/weave.g
	${CC} ${LDFLAGS} -o $@ $^

generated/prep.c: generated/ lexers/prep.l mdr.h
	${LEX} ${LFLAGS} lexers/prep.l

generated/tangle.c: generated/ lexers/tangle.l mdr.h
	${LEX} ${LFLAGS} lexers/tangle.l

generated/weave.c: generated/ lexers/weave.l
	${LEX} ${LFLAGS} lexers/weave.l

generated/:
	mkdir generated

.c.o:
	${CC} ${CFLAGS} -c $< -o $(<:.c=.o) -O3 -flto

.c.g:
	${CC} ${CFLAGS} -c $< -o $(<:.c=.g) -Og -g

test: mdr
	./mdr README.md

vg_test: mdr_debug
	valgrind ./mdr README.md

clean:
	rm -r mdr mdr_debug generated hello_world.c hello_world mdr.o mdr.g README.mdr

.SUFFIXES: .l .c .o .g
