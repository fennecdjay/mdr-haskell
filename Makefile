CFLAGS += -I. -g -std=c99 -Wall
LDFLAGS += -lpthread -pthread
PREFIX ?= /usr/local
#ifeq (${USE_COVERAGE}, 1)
COV_CFLAGS += -ftest-coverage -fprofile-arcs
CFLAGS += -Wall -Wextra
COV_LDFLAGS += --coverage
#endif

mdr: src/mdr.o
	${CC} ${LDFLAGS} -o $@ $^

mdr_debug: src/mdr.g
	${CC}  ${COV_LDFLAGS} ${LDFLAGS} -o $@ $^

.c.o:
	${CC} ${CFLAGS} -c $< -o $(<:.c=.o) -O3

.c.g:
	${CC} ${COV_CFLAGS} ${CFLAGS} -c $< -o $(<:.c=.g) -Og -g

install: mdr
	cp -f mdr ${DESTDIR}${PREFIX}/bin
	chmod 755 ${DESTDIR}${PREFIX}/bin/mdr


clean:
	rm -rf mdr mdr_debug hello_world.c hello_world src/*.o src/*.g tests/*.md

test: mdr_debug
	./mdr_debug **/*.mdr non_mdr_file

.SUFFIXES: .c .o .g
