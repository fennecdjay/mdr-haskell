CFLAGS += -Wall -Wextra -Wpedantic -I.
STRIP ?= strip

mdr: mdr.o
	${CC} ${LDFLAGS} -o $@ $^ -flto
	${STRIP} $^

mdr_debug: mdr.g
	${CC} ${LDFLAGS} -o $@ $^

.c.o:
	${CC} ${CFLAGS} -c $< -o $(<:.c=.o) -O3 -flto

.c.g:
	${CC} ${CFLAGS} -c $< -o $(<:.c=.g) -Og -g

test: mdr
	./mdr README.mdr test/*.mdr

vg_test: mdr_debug
	valgrind ./mdr_debug README.mdr tests/*.mdr

clean:
	rm -r mdr mdr_debug hello_world.c hello_world mdr.o mdr.g test/*.mdr

.SUFFIXES: .c .o .g
