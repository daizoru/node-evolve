
chai = require 'chai'
expect = chai.expect
require './testutils'

evolve = require 'evolve'

describe 'Evolve', ->
  it 'should mutate a function', (done) ->
    this.timeout 800
    input = mutable ->
      a = x * 1
      b = y * 1
      z = "hello"
      c = z * 1
    inputSrc = input.toString()
    avgDist = 0
    max = 100
    for i in [0..max]
      do (i) -> evolve.clone 
        src       : inputSrc
        ratio     : 0.5
        iterations: 1
        onComplete: (outputSrc) ->
          avgDist += inputSrc.levenshtein outputSrc
          return unless i is max
          avg = avgDist / max
          console.log "avg: #{avg}"
          expect(avg).to.be.above(70).and.to.be.below(80)
          done()
        

  it 'should inline files', (done) ->
    this.timeout 20
    input = -> 
      do mutable ->
        inline "sequence1"
        z = "hello"
        c = z * 1
    inputSrc = input.toString()
    evolve.clone 
      src       : inputSrc
      ratio     : 0.5
      iterations: 1
      inlinePath: [ __dirname ] # necessary, and actually helpful
      onComplete: (outputSrc) ->
        console.log "result: " + outputSrc
        done()
        
      
