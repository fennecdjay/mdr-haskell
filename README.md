# MDR, a markdown runner

[![Build Status](https://travis-ci.org/fennecdjay/mdr.svg?branch=master)](https://travis-ci.org/fennecdjay/mdr)

mdr is a **small** (less than **500 Haskell SLOC** :champagne:) *program* and *markup*
designed to facilitate documentation and testing.  


![logo](logoreadme.png "The Mdr logo! (WIP)")

I started it to ease [Gwion](https://github.com/fennecdjay/gwion)'s devellopment,
but it is not tied in any way to this project.  

Let' walktrough... :smile:

## Hello World
let's write our first litterate progam.

### Define program structure

``` c
@[[Includes]]

int main(int argc, char** argv) {
  @[[Print]]
}
```


### Add Headers
As we need the *puts* function, we need **stdio** headers.

``` c
#include <stdio.h>
```


### Print function

``` c
puts("Hello, World!");
```



### Compile
with this line
``` sh
@exec cc hello_world.c -o hello_world
```
we compile *hello_world.c*.

``` sh
```

Yes, there should be no output, and that good news.



### Check
Let's look at hello_world.c

``` sh
@exec cat hello_world.c
```

``` c
#include <stdio.h>

int main(int argc, char** argv) {
  puts("Hello, World!");
}
```

That's the content of the source file we generated (and compiled).



### Test

Then we run it
``` sh
./hello_world
```

``` sh
Hello, World!
```

Do we read *Hello World!* ?
Assuming yes, let's continue.

### More test
Let's try it
```
[ "$(./hello_world)" = "Hello, World!" ] && echo "OK" || echo "NOT_OK"
```

and the result is
``` sh
OK
```

## Building

As a haskell programm, it seemed natural to use [cabal](https://www.haskell.org/cabal/)
as a build system.

``` sh
cabal build
```

## Installing

As easy as before, just type.

``` sh
cabal install
```

generated from [this file](https://github.com/fennecdjay/mdr/blob/master/README.mdr)
