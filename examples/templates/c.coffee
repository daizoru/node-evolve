{C} = require 'cello'
{mutable, mutateNow} = require 'evolve'

generate = C
  indent: '  '
  debug: yes
  ignore: -> [
    mutateNow
    mutable
  ]
  evaluate: -> [
    mutateNow
  ]

console.log generate -> mutateNow -> 
  include 'stdio.h'
  include 'stdlib.h'

  int x = mutable 40

  main = ->
   int y = mutable 43 + x
   printf "hello"
   0
