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

## Limitations

The evolved code must respect some security rules and constraints.
You cannot use "var x = ..", so you must use pre-defined variables and function symbols.

In the future I may create an API to make this customizable,
but for the moment there are only 5 vars for values (x1, x2, x3, x4 and x5),
and 5 vars for functions (f1, f2, f3, f4 and f5)

Functions must not take arguments, but they can have side effects. Actually, this is encouraged if you want emergence of complex patterns and algorithms.

These basic constraints allow more freedom to the evolved code,
which can easily mutate without create JavaScript syntax errors (eg. invalid parameters)

## WARNING

  For the moment you cannot customize the mutations rules and probabilities

  Yes, I know, it is pretty useless then. 
  That why I haven't published the lib on NPM yet. There is still some work to do.

## Installation

    $ npm install -g evolve

## Usage

### In command line

    $ evolve path/to/sourcefile.js [debug]

### Using the API

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

