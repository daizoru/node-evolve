#!/usr/bin/env coffee
evolve = require 'evolve'
mutation_rate = 0.001
foo = 0.25
evolve.mutable ->
  foo = foo * 1.0
  mutation_rate = Math.cos(0.001) * Math.sin(0.5) 
  mutation_rate = mutation_rate * foo

evolve.readFile

  ratio: mutation_rate
  file: process.argv[1]

  makeRules: (options, globals, locals, clipboard) ->

    multiply: (t,x) -> if t is 'num' and Math.random < evolve.mutable 0.6
      [t, evolve.mutable Math.random() * x]

    add     : (t,x) -> if t is 'num' and Math.random < evolve.mutable 0.4
      [t, evolve.mutable Math.random() + x]

  onComplete: (src) -> console.log src
