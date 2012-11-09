#!/usr/bin/env coffee
{inspect}        = require 'util'
deck             = require 'deck'
{map,wait}       = require 'ragtime'
{mutable,mutate} = require 'evolve'
timmy            = require 'timmy'

size = 300
max_iterations = 10

makeMemory = (size) -> { inputs: [], value: Math.random() } for i in [0...size]
memory = makeMemory size

memoryRange = [0...memory.length]
randomNode = -> deck.pick memory
randomIndex = -> Math.round(Math.random() * (memory.length - 1))
randomInputRange = -> [0...randomIndex()]


for n in memoryRange
  for i in randomInputRange()
    input = 
    memory[n].inputs.push mutable
      input: randomIndex() * 1.0 # can use logic
      weight: Math.random() * 0.01 + 1.0
  memory[n].compute = (inputs) ->
    output_signal = 0
    for i in inputs
      input_signal = memory[i.input].value
      output_signal += mutable input_signal * i.weight
    output_signal = if inputs.length > 0 then output_signal / inputs.length else output_signal
    #console.log "output_signal: #{output_signal}"
    output_signal

iterations = 0
operations = 0
integrations = 0
compute = ->
  if iterations++ > max_iterations 
    console.log "stats: "
    console.log "  #{memory.length} in memory"
    console.log "  #{iterations} iterations"
    console.log "  #{operations} node values computed"
    console.log "  #{integrations} integrations"
    return

  console.log "computing.."
  #console.log "memory: #{inspect memory, no, 3, yes}"

  for n in memory
    operations++
    integrations += n.inputs.length
    n.value = n.compute n.inputs
    # done
  console.log "computed."
  #console.log "memory: #{inspect memory, no, 3, yes}"

  wait(100.ms) compute

wait(1.sec) compute
