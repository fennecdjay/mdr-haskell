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

clean:
	rm -rf mdr mdr_debug hello_world.c hello_world mdr.o mdr.g tests/*.mdr

.SUFFIXES: .c .o .g
