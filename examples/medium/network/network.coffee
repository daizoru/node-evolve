#!/usr/bin/env coffee
{inspect}        = require 'util'
deck             = require 'deck'
{map,wait}       = require 'ragtime'
{mutable,mutate} = require 'evolve'
timmy            = require 'timmy'

size = 10
memory = []
for i in [0...size]
  memory.push inputs: [], value: Math.random()

memoryRange = [0...memory.length]
randomNode = -> deck.pick memory
randomIndex = -> Math.round(Math.random() * (memory.length - 1))
randomInputRange = -> [0...(Math.random() * memory.length)]

for n in memoryRange
  for i in randomInputRange()
    memory[n].inputs.push
      input:  -> mutable -> randomIndex() * 1.0 # can use logic
      weight: -> mutable -> Math.random() * 0.01 + 1.0
    memory[n].compute = (inputs) ->
      output_signal = 0
      for i in inputs
        input_signal = memory[i.input].value
        output_signal += mutable -> input_signal * i.weight
      output_signal = if inputs.length > 0 then output_signal / inputs.length else output_signal
      console.log "output_signal: #{output_signal}"
      output_signal

compute = ->
  console.log "computing.."
  console.log "memory: #{inspect memory, no, 3, yes}"

  for n in memory
    # call the integrator
    n.value = n.compute n.inputs
    # done
  console.log "computed."
  console.log "memory: #{inspect memory, no, 3, yes}"

wait(1.sec) compute
