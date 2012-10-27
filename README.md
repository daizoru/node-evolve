node-evolve
===========

A library for evolving Javascript functions - BETA

## Summary

Evolve is a library designed to explore parameters, algorithms and solutions automatically,
by introducing random changes in a program, constrained by a set of rules.

It works by mutating JavaScript ASTs, using random mutations over trees and nodes,
and a set of rules to constrain mutations to specific patterns and parts of your code.

That said, please don't use it mindlessly! there is absolutely no guarantees your program
will still work after mutation, therefore your really should use a higher-level 
genetic algorithm library on top of it.

## Examples

Please see the /examples dir for cool examples. 

For instance:

### Replicator

    $ examples/bacteria.coffee

 Will run a minimalist demo program which can replicates itself (it just print a modified
 version of its own source code to the standard output).
To keep the demo simple, it is constrained to mutate only one thing - its own mutation rate:

```CoffeeScript
evolve = require('evolve')
mutation_rate = .001
foo = .20
evolve.mutable ->
  foo = foo * 0.10
  mutation_rate = Math.cos(0.001) + Math.sin(0.5)
  mutation_rate = mutation_rate / foo
evolve.readFile
  ratio: mutation_rate
  file: process.argv[1]
  debug: false
  onComplete: (src) ->
    console.log src
```

### More examples

See the /xamples dir

## WARNING

  node-evolve is still in development and won't solve all problems for you:
  no matter how powerful it might looks like, you still have to design your program - and your problem - carefully.

## Installation

  Since node-evolve is not released yet, you have to install it using:

    $ npm install git://github.com/daizoru/node-evolve.git

## Features 

### Radioactive batteries included

Various mutators are already available in node-evolve:
random insert, replace, delete of AST nodes, numbers, strings..

### EXPERIMENTAL - Support for multiples iterations
 
It can apply more than one layer of mutation:
For instance, one iteration might copy AST nodes to a buffer,
and another may paste the content to overwrite or insert data.

Use this feature to create complex, combined mutations.

### Constrained syntax and semantics

node-evolve will try hard to avoid useless or bad mutations - your code will already have a hard time surviving its first eval() anyway!

It works thanks to AST constraints.
These constraints prevent mutating this:

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

### Simple type checking

node-evolve check that incompatible references are not mixed.

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

On the other hand, this one is prohibited:

```CoffeeScript
Math.PI = x * Math.cos(x);
```

Since variables and functions passed in context are read-only


### List of supported mutations

#### Numerical values

  Numerical values are subject to mutation, like random multiplication or addition.

#### Binary operator substitution

  Operator of binary operations may be substituted by any operator
  of this list: + - * /

#### Binary operator switching

  This mutation simply switch two terms of an operation,
  eg. 10.0 / 5.0 becomes 5.0 / 10.0. 

#### EXPERIMENTAL - String mutation, levenshtyle.

  String mutation is supported, and done using atomic operators like add, delete, move and substitution. However it is still experimental, and doesn't offer
  much control over which ASCII characters are allowed, forbidden,
  constants strings, collections of strings.. you have to implement this
  yourself for the moment (using Rules)

#### EXPERIMENTAL - Block copying, cutting & pasting

  This mutation copy or cut a node of the AST tree to another place.
  It may replace a node or insert between two.

#### EXPERIMENTAL - Variable substitution

  Any variable is subject to change and remplacement by another variable.

## How-to

### Use it in command line

    $ evolve src [ratio=0.42] [debug]

Example :

    $ evolve examples/evolvable.js ratio=0.10

```JavaScript
mutable(function() {
    a = x * 1;
    b = y * 1;
    z = "hello";
    return c = 1.4881885522045195 * z;
});
```

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

evolve.mutate context: context, .....
```

#### Customize the mutation rules

```CoffeeScript
rules =

  # decorators are applied on each node, and expected to return either
  # the current, new or modified node, or an undefined value (then it is ignored)
  decorators:
    multiply: (t, value) -> 
      if t is 'num' and Math.random() < 0.5 then [t, Math.random() * value]


```

## Change log

### 0.0.0
