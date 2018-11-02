[![Coverage Status](https://coveralls.io/repos/github/fennecdjay/mdr/badge.svg)](https://coveralls.io/github/fennecdjay/mdr)
# MDR, a markdown runner

mdr is a small (less than 500 C SLOC :champagne:) program and markup designed to
facilitate documentation and testing.  
I started it to ease [Gwion](https://github.com/fennecdjay/gwion)'s devellopment,
but it is not tied in any way to this project.  
Let' walktrough... :smile:
## Hello World
let's write our first litterate progam.

### Define program structure
``` .c
@[[Includes]]

int main(int argc, char** argv) {
  @[[Print]]
}
```

### Add Headers
As we need the *puts* function, we need **stdio** headers.
``` .c
#include <stdio.h>
```

### Print function
``` .c
puts("Hello World!");
```

### Compile
with this line @exec cc hello_world.c -o hello_world

```
```

we compile hello_world.  
Yes, there should be no output, and that good news.
### Test

Then we run it @exec ./hello_world

```
Hello World!
```Do we Read *Hello World!*?
Assuming yes, let's continue.

### Check
Let's look at hello_world.c @exec cat hello_world.c
```
#include <stdio.h>


int main(int argc, char** argv) {
  puts("Hello World!");

}
```
That's the content of the source file we generated (and compiled).

### More test
Let's try @exec [ "$(./hello_world)" = "Hello World" ] && echo "OK" || echo "NOT_OK"
```
NOT_OK
```

## Building
``` sh
make
```

## Todo
  * [x] hand-written parsers
  * [x] Fix include string
  * [x] Handle file extension
  * [x] remove block extra line
  * [ ] short for filetype when declaring file block
  * [ ] exec might need more info (filetype, command)
  * [ ] test suite
  * [x] threading

generated from [this file](https://github.com/fennecdjay/mdr/blob/master/README.mdr)
