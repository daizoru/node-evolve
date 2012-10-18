node-evolve
===========

Programmatically evolve source code

## Summary

Evolve is a low-level library for evolving JavaScript source code.

You can use it to mutate parts of your application (sub-scripts)
in order to solve "hard to solve" optimization problems.

Since node-evolve only provide a few helper functions for manipulating 
JavaScript code, you have to take care yourself of any other high-level 
selection logic (mating algorithms, fitness function, Pareto frontier..)

## Installation

    $ npm install -g evolve

## Usage

### In command line

    $ evolve path/to/sourcefile.js [debug]

### Using the API

#### Defining a block of mutable code

```CoffeeScript

class Foo

  foo: (x,y,z) =>

    [a,b,c] = [0,0,0]

    # define a block of evolvable code, algorithm, neural network..
    evolve.mutable ->

      # the evolved code can only mess with foo()'s variables
      # if evolution goes wrong
      a = x * 1
      b = y * 1
      c = z * 1

      # you can add an "hidden" level of memory
      f = 5
      g = 42 

      # and maths!
      b = Math.cos(f) + Math.cos(g * a)
      c = a + 3

    # outside the block, you can call your stuff as usual
    @bar a, b, c

```

#### Load a source string

```JavaScript
var evolve = require("evolve");

var old_src = "x1 = 0; x2 = 42; f1 = function() { return x2 * 10; }; x1 = f1();";

evolve.mutateSrc({

  // input source code (string)
  "src" : old_src,

  "tentatives": 1,

  // on complete always return a source; In case of failure, the original is returned
  "onComplete": function(src) { return console.log("finished: " + src); }
});

```

#### Load a file

```JavaScript
  
  evolve.mutateFile({
    "file" : "examples/evolvable.js",
    "onComplete": function(src) { return console.log(src); }
  });

```


## Examples

### Basic example

See /examples

