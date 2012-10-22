node-evolve
===========

Programmatically evolve source code

## Summary

Evolve is a low-level library for evolving JavaScript source code.

You can use it to mutate parts of your application (sub-scripts)
in order to solve "hard to solve" optimization problems.

This library only provides helper functions for manipulating 
JS code. You have to take care yourself of any other high-level 
selection logic (mating algorithms, fitness function, Pareto frontier..)

## Installation

    $ npm install -g evolve

## Features 

### Mutations

#### Numerical values

  Numerical values are subject to mutation, like random multiplication or addition.

#### Strings

  Strings are also supported.
  Mutation is done by operators like add, delete, move and substitution.

#### Copy & paste

  This mutation copy a node of the AST tree
  to another place.
  It may replace a node or insert between two.

## How-to

### Usage in command line

  $ evolve path/to/sourcefile.js [debug]

### Using the API

#### Defining a block of mutable code

```CoffeeScript
evolve = require 'evolve'

class Foo

  constructor: ->
  
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

#### Dynamic mutation (aka radioactive contamination mode)

```CoffeeScript
{mutate} = require 'evolve'

evolve.mutate 
  obj: Foo.prototype
  func: 'foo'
  onComplete: ->
    console.log "mutation of foo() completed."

    f = new Foo()
    f.foo()
```

#### Load a source string

```JavaScript
var evolve = require("evolve");

var old_src = "x1 = 0; x2 = 42; f1 = function() { return x2 * 10; }; x1 = f1();";

// clone a source, with some "dna" copy errors
evolve.clone({

  // input source code (string)
  "src" : old_src,

  "tentatives": 1,

  // on complete always return a source; In case of failure, the original is returned
  "onComplete": function(src) { return console.log("finished: " + src); }
});

```

#### Load a file

```JavaScript
  
// read a file, with some "dna" copy errors
evolve.readFile({
    "file" : "examples/evolvable.js",
    "onComplete": function(src) { return console.log(src); }
});

```

#### Setup the context (available functions and variables)

```CoffeeScript

context =

  # functions callable
  functions:
    'Math.cos': Math.cos
    'Math.sin': Math.sin
    'Math.random': Math.random

  # vars readables (write-protected)
  constants:
    'Math.PI': Math.PI

evolve.mutate 
  obj: A
  func: 'B'
  context: context
  onComplete: -> # ..
```

#### Customize the mutation rules

```CoffeeScruipt
rules =

  # decorators are applied on each node, and expected to return either
  # the current, new or modified node, or an undefined value (then it is ignored)
  decorators:
    multiply: (type, value) -> 
      if type is 'num' and P(0.87) then [type, Math.random() * value]


```

## Examples

### Basic example

See /examples

## Change log

### 0.0.0
