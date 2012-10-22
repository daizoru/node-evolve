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

### library of mutations

A serie of mutation is already available

### Constrained mutation

Most mutations are partially "safe", and constrained to specific types.

### Customizable rules

You can input your own rules, if they can be applied to an AST node (or the root node of the whole tree).

### Basic type checking

node-evolve check that functions references ae not mixed with values.
For instance, this mutation can't happen with node-evolve:

```CoffeeScript
var x = Math.PI * Math.cos;
```

But this one can:

```CoffeeScript
var x = Math.PI * Math.cos(Math.PI);
```


### List of supported mutations

#### Numerical values

  Numerical values are subject to mutation, like random multiplication or addition.

#### Strings

  Strings are also supported.
  Mutation is done by operators like add, delete, move and substitution.

#### Block copying, cutting & pasting

  This mutation copy or cut a node of the AST tree to another place.
  It may replace a node or insert between two.

#### Binary operator substitution

  Operator of binary operations may be substituted by any operator
  of this list: + - * /

#### Binary operation switch

  This mutation simply switch two terms of an operation,
  eg. 10.0 / 5.0 becomes 5.0 / 10.0. 

#### Variable substitution

  Any variable is subject to change and remplacement by another variable


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

#### Setup the context


Just pass a bunch of variables to be used in mutations

```CoffeeScript

# the function is important here
context = -> [
  Math.cos
  Math.sin
  Math.random
  Math.PI
]

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
