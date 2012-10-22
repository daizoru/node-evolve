#!/usr/bin/env coffee
evolve = require 'evolve'

console.log "calling mutate"

class Robot

  setVelocity: (x,y,z) =>
    console.log "setting velocity.."

  compute: (x,y,z) =>

    [a,b,c] = [0,0,0]

    z = ""
    m = ""

    # only what's inside this block will evolve
    evolve.mutable ->
      a = x * 1
      b = y * 1
      c = z * 1
      z = "wolrd"
      m = "robot"

    console.log "hello #{z}"
    @setVelocity a, b, c

robot = new Robot()

# mutate our function during execution, plutonium style
evolve.mutate 
  obj: Robot.prototype
  func: 'compute'
  debug:  ('debug' in process.argv)

  # 0.40 give between 0~5 mutations for a very small file
  # big files resist better to mutations
  ratio: 0.40 

  onComplete: ->
    console.log "mutation completed"
  

