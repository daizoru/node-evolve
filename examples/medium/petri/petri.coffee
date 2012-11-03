#!usr/bin/env coffee
{inspect} = require "util"
path      = require "path"
cluster   = require "cluster"
os        = require "os"
fs        = require "fs"
crypto    = require "crypto"
deck      = require "deck"
evolve    = require "evolve"
{wait}    = require "ragtime"
timmy     = require "timmy"
 
 # machine constraints #########
NB_CORES = 8
MAX_EGGS = 200
DECIMATION = 0.10 # used this variable to control mutation rate in real time
SAMPLING = 0.20 # sampling for debug logs
DELAY = 10.ms
TMP_DIR = "box/"
################################

sha1 = (src) ->
  shasum = crypto.createHash 'sha1'
  shasum.update src
  shasum.digest 'hex'

getFiles = (dir, cb) ->
  fs.readdir dir, (err, files) ->
    eggs = []
    unless err
      for f in files
        eggs.push f if f.match /(.*)\.egg.js/
    cb deck.shuffle eggs

###
Il faudrait encourager les sources qui se forkent

###
if cluster.isMaster
  console.log "master"
  [0..NB_CORES].map (i) -> cluster.fork()
  cluster.on "exit", (worker, code, signal) ->
    getFiles "#{TMP_DIR}", (eggs) ->
      if eggs.length > MAX_EGGS
        #console.log "too many source files, removing random files.."
        for i in [0..eggs.length - MAX_EGGS - 1]
          unlucky = "#{TMP_DIR}#{deck.pick eggs}"
          try
            fs.unlinkSync unlucky
          catch e
            0
      wait(DELAY) -> cluster.fork()

else
  getFiles "#{TMP_DIR}", (eggs) ->
    for egg in eggs
      generation = (Number) egg.split("_")[1]
      file = "#{TMP_DIR}#{egg}"

      # DECIMATION - controlled by the user. we do not decimate the eve
      if generation > 0 and Math.random() < DECIMATION
        try
          fs.unlinkSync file
          continue
        catch e
          0

      # default values of I/O variables
      mutation_rate = 0.05   
      forking_rate  = 0.60
      lifespan_rate = 0.01

      #  intenal (local) variables
      foo = 0.25  

      src = ""
      try
        src = fs.readFileSync file, "utf8"
      catch e
        continue
      if src is ""
        #console.log "deleting empty file.."
        try
          fs.unlinkSync file
        catch e
          0
        continue

      eval src

      mutation_rate = Math.abs mutation_rate
      lifespan_rate = Math.abs lifespan_rate
      forking_rate = Math.abs forking_rate

      if Math.random() < SAMPLING
        console.log "worker #{process.pid}: #{egg}"
        console.log "  generation: #{generation}"
        console.log "  forking: #{forking_rate}"
        console.log "  mutation: #{mutation_rate}"
        console.log "  lifespan: #{lifespan_rate}\n"
      
      # eve is not killed until we fully bootstrapped the system
      if generation > 0 and Math.random() < lifespan_rate
        try
          fs.unlinkSync file
          console.log "#{name} life ended"
        catch e
          0

      if Math.random() > forking_rate 
        process.exit 1

      evolve.clone
        ratio: mutation_rate
        src: src
        onComplete: (src) ->
          if src is ""
            #console.log "generated empty src!"
            process.exit -1
            return
          hash = sha1 src
          name = "#{hash}_#{generation + 1}_#{new Date().valueOf()}_#{Math.round(Math.random() * 1000)}"
          fs.writeFile "#{TMP_DIR}#{name}.egg.js", src, 'utf8', (err) ->
            #console.log "forked!"
            process.exit 1



