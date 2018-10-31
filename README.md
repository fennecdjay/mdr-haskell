# MDR, a markdown runner

## Hello World
let's write our first litterate progam.

### Define program structure
```  hello_world.c
@[[Includes]]

int main(int argc, char** argv) {
  @[[Print]]
}
```

### Add Headers
As we ll later call the puts function, we need **stdio** headers.
```  Includes
#include <stdio.h>
```

### Print function
```  Print
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

## TLDR ;-)
  * when writing code block, use file or block name
  * add result of a command with @exec whatever command here

## Building
``` sh
make
# or even only
make test
```
If this does not work, you're probably missing (f)lex, either install it,
check the 'generated' branch or file an issue

## Todo
  * [x] hand-written parsers
  * [ ] Fix include string
  * [ ] test suite
  * [ ] threading

## Added


```  Test
## Added
```
