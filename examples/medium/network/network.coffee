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

    # add a new input
    if P mutable 0.04
      n.inputs.push mutable
        input: randomIndex() # TODO should not be *that* random
        weight: Math.random() * 0.01 + 1.0

    # delete an input
    if P mutable 0.001
      n.splice randomIndex(), 1

    if n.inputs.length

      # update an input weight
      if P mutable 0.01
        input = n.inputs[(n.inputs.length - 1) * Math.random()]
        input.weight = mutable input.weight * 1.0

      # compute local state using some inputs
      if P mutable 0.01
        n.value = 0
        for i in inputs
          input_signal = memory[i.input].value
          n.value += mutable input_signal * i.weight
        n.value = if inputs.length > 0 then n.value / inputs.length else n.value
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
