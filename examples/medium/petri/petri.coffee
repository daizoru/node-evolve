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
NB_CORES = 1#os.cpus().length ? 2
DB_SIZE = 20 # this is a soft limit
SAMPLING = 1#0.05 # sampling for debug logs
DELAY = 2.sec
TMP_DIR = "box/"
################################

# TODO
# packets can be grouped when sent from worker to cluster

# make a random, mostly unique id
makeId = -> (Number) ("#{new Date().valueOf()}#{Math.round(Math.random() * 10000)}")

sha1 = (src) ->
  shasum = crypto.createHash 'sha1'
  shasum.update src
  shasum.digest 'hex'

class Database
  constructor: (@max_size) ->
    @_ = {}
    @length = 0

  load: (file) =>
    console.log "importing #{file}"
    src  = fs.readFileSync file, "utf8"
    [generation, id] = file.split '-'
    id = id.split('.')[0]
    generation = ((Number) generation) ? 0
    id = id ? makeId()
    hash = sha1 src
    @record
      src: src
      id: id
      generation: generation
      hash: hash

  pick    :       => @_[deck.pick Object.keys @_]
  remove  : (g)   => delete @_[g.id]
  record  : (g)   => @_[g.id] = g
  size    :       => Object.keys(@_).length

  # apply a soft limit by removing random genomes.
  # older genomes have more "opportunities" of dying than younger ones
  decimate: =>
    p = 1.0 - (@max_size / @size())
    for id, g of @_
      @remove g if Math.random() < p

MASTER = ->

  db = new Database DB_SIZE # genome database, with a max limit
  db.load '0-0.js'          # import an 'eve' program in the database

  
  # helper function to send a genome to some worker
  sendGenome = (worker) ->
    #console.log "sendGenome()"
    genome = db.pick()
    if genome
      #console.log "sending genome"
      worker.genome = genome
      worker.send JSON.stringify {genome}
    else
      console.log "error, no genome to send; retrying later"
      wait(1.sec) -> sendGenome worker

  broadcast = (f) ->
    for id in cluster.workers
      f cluster.workers[id]

  runWorker = ->
    db.decimate()
    worker = cluster.fork()
    worker.on 'message', (msg) ->
      msg = JSON.parse msg
      sendGenome worker       if 'hello'  of msg
      db.record msg.record    if 'record' of msg # no else, to support batch mode
      db.remove worker.genome if 'die'    of msg

  # reload workers if necessary
  cluster.on "exit", (worker, code, signal) ->
    console.log "  db size: #{db.size()}"
    wait(DELAY) -> runWorker() 

  # run workers over CPU cores
  [0..NB_CORES].map (i) -> runWorker()


WORKER = ->
  #console.log "WORKER STARTED"
  # worker-specific functions
  outputs = (msg) -> process.send JSON.stringify msg
  inputs  = (cb) -> 
    process.on 'message', (msg) -> 
      #console.log "worker received raw msg"
      cb JSON.parse msg

  outputs hello: 'world'

  # start listening to incoming messages
  inputs (msg) ->
    #console.log "master sent us #{inspect msg}"
    genome = msg.genome

    if genome?

      # default values of I/O variables
      mutation_rate = 0.05   
      forking_rate  = 0.60
      lifespan_rate = 0.01

      #  intenal (local) variables
      foo = 0.25  

      eval genome.src # run the evolvable kernel

      mutation_rate = Math.abs mutation_rate
      lifespan_rate = Math.abs lifespan_rate
      forking_rate  = Math.abs forking_rate

      if Math.random() < SAMPLING
        console.log "worker #{process.pid}:"
        console.log "  hash:     : #{genome.hash}"
        console.log "  generation: #{genome.generation}"
        console.log "  forking   : #{forking_rate}"
        console.log "  mutation  : #{mutation_rate}"
        console.log "  lifespan  : #{lifespan_rate}\n"
      
      # eve is not killed until we fully bootstrapped the system
      if genome.generation > 0 and Math.random() < lifespan_rate
        outputs die: "end of life"

      if Math.random() < forking_rate 
        #console.log "cloning"
        evolve.clone
          ratio: mutation_rate
          src: genome.src
          onComplete: (new_src) ->
            #console.log "sending back a new src to master"
            outputs
              record:
                src: new_src
                generation: genome.generation + 1
                id: makeId()
                hash: sha1 new_src
            process.exit 0
      else
        process.exit 0
    else
      err = "error, unknow message: #{inspect msg}"
      console.log err
      process.exit 1

do if cluster.isMaster then MASTER else WORKER