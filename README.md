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


## Usage

### In command line

    $ evolve path/to/sourcefile.js [debug]

### Using the API

```JavaScript
var evolve = require("evolve");

var old_src = "x1 = 0; x2 = 42; f1 = function() { return x2 * 10; }; x1 = f1();"

var options = {
  "fidelity" : 0.90 // global fidelity when cloning source code
};
var new_src = evolve.clone(old_src, options);

```
