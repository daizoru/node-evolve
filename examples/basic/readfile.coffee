#!/usr/bin/env coffee
evolve = require "evolve"

evolve.readFile
  file: "examples/basic/without_mutable.js"
  onComplete: (src) ->
    console.log "two: " + src
