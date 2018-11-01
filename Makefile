CFLAGS += -I. -g -std=c99
LDFLAGS += -lpthread -pthread

mdr: src/mdr.o
	${CC} ${LDFLAGS} -o $@ $^

mdr_debug: src/mdr.g
	${CC} ${LDFLAGS} -o $@ $^

.c.o:
	${CC} ${CFLAGS} -c $< -o $(<:.c=.o) -O3

.c.g:
	${CC} ${CFLAGS} -c $< -o $(<:.c=.g) -Og -g

test: mdr
	./mdr test/*.mdr || exit 0
	./mdr README.mdr

clean:
	rm -rf mdr mdr_debug hello_world.c hello_world src/*.o src/*.g tests/*.md

.SUFFIXES: .c .o .g
