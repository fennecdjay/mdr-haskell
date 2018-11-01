# MDR, a markdown runner

## Hello World
let's write our first litterate progam.

### Define program structure
```.c

@[[Includes]]

int main(int argc, char** argv) {
  @[[Print]]
}
```

### Add Headers
As we ll later call the puts function, we need **stdio** headers.
```.c

#include <stdio.h>
```

### Print function
```.c

puts("Hello World");
```

### Compile
with this line @exec cc hello_world.c -o hello_world
```

```

we compile hello_world.

### Test

Then we run it @exec ./hello_world
```
Hello World

```
### Check
Let's look at hello_world.c @exec cat hello_world.c
```
#include <stdio.h>


int main(int argc, char** argv) {
  puts("Hello World");

}

```
### More test
Let's try @exec [ "$(./hello_world)" = "Hello World" ] && echo "OK" || echo "NOT_OK"
```
OK

```

## Building
``` sh
make
```

## Todo
  * [x] hand-written parsers
  * [x] Fix include string
  * [ ] Handle file extension
  * [ ] test suite
  * [ ] threading
