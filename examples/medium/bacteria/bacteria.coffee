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
  onComplete: (src) -> console.log src
