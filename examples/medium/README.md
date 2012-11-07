# medium

These are examples of average complexity that use node-evolve to do fun things.

## Bacteria

A demo of a self-replicating program.

## Petri

Like bacteria, except it runs in a node-cluster.

This is a [must-try](https://github.com/daizoru/node-evolve/tree/master/examples/medium/petri/README.md "must-try") if you are looking for live node-evolve action!

## TODO

 * Show how to mutate the mutation rules themselves, and not just the global probability parameter

Should looks like something like this (for instance):

```CoffeeScript

myrules =
  mymutation: (t,x) ->
    if t is 'num' and mutable -> 0.5 + 0.5
      [t, mutable -> Math.random() + x]
```