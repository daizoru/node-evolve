#!/usr/bin/env coffee
evolve = require 'evolve'
mutation_rate = 0.001
foo = 0.25
aaa = (a) -> a
bbb = (a) -> a
do evolve.mutable ->
  foo = foo * 1.0
  mutation_rate = Math.cos(0.001) * Math.sin(0.5) 
  mutation_rate = mutation_rate * foo

evolve.readFile

  ratio: mutation_rate
  file: process.argv[1]

  makeRules: (options, globals, locals, clipboard) ->

    multiply: (t,x) -> if t is 'num' and Math.random < evolve.mutable aaa 0.6
      [t, evolve.mutable Math.random() * x]

    add     : (t,x) -> if t is 'num' and Math.random < evolve.mutable bbb 0.4
      [t, evolve.mutable Math.random() + x]

    # TODO:
    # the rule should look for 'aaa' or 'bbb', and mutate in a different manner

  onComplete: (src) -> console.log src
