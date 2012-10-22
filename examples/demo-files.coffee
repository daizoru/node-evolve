#!/usr/bin/env coffee
evolve = require "evolve"

evolve.readFile
  file: "examples/evolvable_big.js"
  onComplete: (src) ->
    console.log "two: " + src
