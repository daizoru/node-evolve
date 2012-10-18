evolve = require 'evolve'

console.log "calling mutate"

class Robot

  setVelocity: (x,y,z) =>
    console.log "setting velocity.."

  compute: (x,y,z) =>

    [a,b,c] = [0,0,0]

    # only what's inside this block will evolve
    evolve.mutable ->
      a = x * 1
      b = y * 1
      c = z * 1

    @setVelocity a, b, c

robot = new Robot()

console.log "robot compute: #{Robot.prototype.compute.toString()}"
# mutate our function during execution, plutonium style
evolve.mutate 
  obj: Robot.prototype
  func: 'compute'
  onComplete: ->
    console.log "mutation completed"
  

