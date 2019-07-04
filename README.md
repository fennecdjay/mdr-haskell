# MDR, a markdown runner

mdr is a **small** (less than **500 Haskell SLOC** :champagne:) *program* and *markup*
designed to facilitate documentation and testing.  

I started it to ease [Gwion](https://github.com/fennecdjay/gwion)'s devellopment,
but it is not tied in any way to this project.  

Let' walktrough... :smile:
## Hello World
let's write our first litterate progam.

### Define program structure
``` hello_world.c .c
@[[Includes]]

int main(int argc, char** argv) {
  @[[Print]]
}
```


### Add Headers
As we need the *puts* function, we need **stdio** headers.

``` Includes .c  
#include <stdio.h>
```


### Print function
``` Print .c
puts("Hello, World!");
```



### Compile
with this line 

we compile *hello_world.c*.  
Yes, there should be no output, and that good news.
### Test

Then we run it
```
./hello_world
```  

```
Hello, World!
```  

Do we read *Hello World!* ?  
Assuming yes, let's continue.

### Check
Let's look at hello_world.c
```
#include <stdio.h>

int main(int argc, char** argv) {
  puts("Hello, World!");
}
```
That's the content of the source file we generated (and compiled).

### More test
Let's try it
```
[ "$(./hello_world)" = "Hello, World!" ] && echo "OK" || echo "NOT_OK"
```  

and the result is
```
OK
```  

## Building
``` sh
make
```  

generated from [this file](https://github.com/fennecdjay/mdr/blob/master/README.mdr)
