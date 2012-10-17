#!/usr/bin/env coffee
evolve = require "evolve"

old_src = "x1 = 0; x2 = 42; f1 = function() { return x2 * 10; }; x1 = f1();"

# clone a string
evolve.mutateSrc
  src : old_src
  tentatives: 1
  onComplete: (src) ->
    console.log "one: " + src
   
    evolve.mutateFile
      file: "evolvable.js"
      onComplete: (src) ->
        console.log "two: " + src
