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

  __kernel VOID floatVectorSum = () ->
    int i = get_global_id 0
    # yes this is a lame example which does *NOTHING*
    # please be patient for future updates!
