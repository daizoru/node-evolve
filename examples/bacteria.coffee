#!/usr/bin/env coffee

#########
# TOOLS #
#########
evolve = require 'evolve'

###########
# CONTEXT #
###########
mutation_rate = 0.001
foo = 0.25

##################
####
# MUTABLE SOURCE-CODE #
#######################
evolve.mutable ->
  foo = foo * 1.0
  mutation_rate = Math.cos(0.001) * Math.sin(0.5) 
  mutation_rate = mutation_rate * foo

####################
# SELF-REPLICATION #
####################
evolve.readFile
  ratio: mutation_rate
  file: process.argv[1]
  debug: no
  onComplete: (src) -> console.log src