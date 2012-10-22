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

### Fast constrained mutation

node-evolve only try to mutate when it has meaning.
Or rather, it will try to evolve useless things.

For instance, constraints prevent mutating this:

```JavaScript
var x = 4 + 2 / y;
```

To this:

```JavaScript
var 3 = * 4 + 2 + y /;
```

Because it would violate three constraints (assign to a number,
lone '/' and '*' operators..)

But for instance, this mutation would be allowed: 

```JavaScript
var y = 2 / x / y + 4 ;
```

In the end, all these constraints make mutation more efficient,
by avoiding running a "compilation" step or evaluation on obviously bad code. It saves time.

### Customizable rules

You can input your own rules, if they can be applied to an AST node (or the root node of the whole tree).

### Type safety

node-evolve check that functions references ae not mixed with values.
For instance, if you define this context:

```CoffeeScript
context = -> [ Math.PI, Math.cos ]
```

then this mutation can't happen with node-evolve:

```CoffeeScript
var x = Math.PI * Math.cos;
```

But this one can:

```CoffeeScript
var x = Math.PI * Math.cos(Math.PI);
```

On the other hand, this one is prohibed:

```CoffeeScript
Math.PI = x * Math.cos(x);
```

Since variables and functions passed in context are read-only


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
