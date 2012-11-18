{C} = require 'cello'
{mutable} = require 'evolve'

console.log C -> 
  include 'stdio.h'
  include 'stdlib.h'

  int x = mutable 40

  main = ->
   int y = mutable 43 + x
   printf "hello"
