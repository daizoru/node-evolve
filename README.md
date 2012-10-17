node-evolve
===========

Programmatically evolve source code

## Introdution

Evolve is a low-level library for evolving JavaScript source code.

## Limitations

The evolved code must respect some security rules and constraints.
You cannot use "var x = ..", so you must use pre-defined variables and function symbols.

In the future I may create an API to make this process painless,
but for the moment you there are only 5 vars for values (x1, x2, x3, x4 and x5),
and 5 vars for functions (f1, f2, f3, f4 and f5)

Functions must not take arguments, but they can have side effects.

These basic constraints allow more freedom to the evolved code,
which can easily mutate without create JavaScript syntax errors (eg. invalid parameters)

## Installation

    $ npm install -g evolve

## Usage

### In command line

    $ evolve path/to/sourcefile.js [debug]

### Using the API

```JavaScript
var evolve = require("evolve");

var old_src = "x1 = 0; x2 = 42; f1 = function() { return x2 * 10; }; x1 = f1();";

// clone a string
evolve.mutateSrc({

  // input source code (string)
  "src" : old_src,

  "tentatives": 1,

  // on complete always return a source; In case of failure, the original is returned
  "onComplete": function(src) { return console.log("finished: " + src); }
});

```

## Example

Given the following input source file:

```JavaScript

// init memory
x1 = 42; x2 = 20; x3 = 40; x4 = 10; x5 = 10;

f1 = function() { return              x1 * x3;                };
f2 = function() { return      Math.cos(x1) + Math.sin(x1);    };
f3 = function() { return              x2 * x2;                };

f3() + f2() + (4*(3+1+6));

```

node-evolve might spit out:


```JavaScript


```

Of course your mileage may vary