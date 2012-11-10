#!/usr/bin/env coffee
{inspect}        = require 'util'
deck             = require 'deck'
{map,wait}       = require 'ragtime'
{mutable,mutate} = require 'evolve'
timmy            = require 'timmy'

P = (p=0.5) -> +(Math.random() < p)
size = 10
max_iterations = 2

makeMemory = (size) -> { inputs: [], value: Math.random()} for i in [0...size]
memory = makeMemory size

memoryRange = [0...memory.length]
randomNode = -> deck.pick memory
randomIndex = -> Math.round(Math.random() * (memory.length - 1))
randomInputRange = -> [0...randomIndex()]

iterations = 0
compute = ->

  console.log "computing.."
  #console.log "memory: #{inspect memory, no, 3, yes}"

  for n in memory
    console.log "computing element"
    # add a new input
    if P mutable 0.20
      console.log "adding a new input"
      n.inputs.push mutable
        input: randomIndex() # TODO should not be *that* random
        weight: Math.random() * 0.01 + 1.0

    if n.inputs.length

      if P mutable 0.40
        console.log "deleting a random input"
        n.inputs.splice Math.round(Math.random() * n.inputs.length), 1

      # update an input weight
      if P mutable 0.30
        console.log "updating an input weight"
        input = n.inputs[(n.inputs.length - 1) * Math.random()]
        input.weight = mutable input.weight * 1.0

      # compute local state using some inputs
      if P mutable 0.95
        console.log "computing local state"
        n.value = 0
        for i in n.inputs
          input_signal = memory[i.input].value
          n.value += mutable input_signal * i.weight
        if n.inputs.length > 0
          n.value = n.value / n.inputs.length

    # done
  console.log "iteration #{++iterations} completed."

  if iterations >= max_iterations 
    console.log "stats: "
    console.log "  #{memory.length} in memory"
    console.log "  #{iterations} iterations"
    return
  else
    wait(1000.ms) compute

wait(1.sec) compute


# todo add reproduction