#!usr/bin/env coffee
{inspect} = require "util"
path      = require "path"
cluster   = require "cluster"
os        = require "os"
fs        = require "fs"
crypto    = require "crypto"
deck      = require "deck"
evolve    = require "evolve"
{wait,repeat}    = require "ragtime"
timmy     = require "timmy"
 
 # machine constraints ##################
NB_CORES = os.cpus().length
DB_SIZE = 20 # soft db limit
#########################################

# debug options #########################
DELAY = 20.ms   # delay between subprocesses launches
SAMPLING = 0.05 # how often we should print logs
#########################################

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
    @counter = 0

    @batch = []

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
      stats: {}

  pick    :       => @_[deck.pick Object.keys @_]
  remove  : (g)   => delete @_[g.id]
  record  : (g)   => @_[g.id] = g ; @counter++
  size    :       => Object.keys(@_).length
  oldestGeneration: =>
    oldest = 0
    for k,v of @_
      if v.generation > oldest
        oldest = v.generation
    oldest

  # The decimator should take params,
  # to decimate in priority badly performing individual


  decimate: =>
    size = @size()
    return if size < @max_size
    to_remove = size - @max_size
    #console.log "to remove: #{to_remove}"
    keys = deck.shuffle Object.keys @_
    for k in keys[0...to_remove]
      #console.log "removing #{k}"
      delete @_[k]

  # pick up next individual in a round
  next: =>
    #console.log "batch: #{@batch}"
    k = @batch.pop()
    #console.log "next: #{k}"
    if !k? and @size() > 0
      #console.log "end of cycle. size: #{@size()}"
      @decimate()
      #console.log "new size: #{@size()}"
      @batch = deck.shuffle Object.keys @_
      #console.log "new batch: #{@batch}"
      k = @batch.pop()
      #console.log "new next: #{k}"

    @_[k]



MASTER = ->

  db = new Database DB_SIZE # genome database, with a max limit
  db.load '0-0.js'          # import an 'eve' program in the database

  
  # helper function to send a genome to some worker
  sendGenome = (worker) ->
    #console.log "sendGenome()"
    genome = db.next()
    if genome?
      #console.log "sending genome"
      worker.genome = genome
      worker.send JSON.stringify {genome}
    else
      #console.log "error, no genome to send; retrying later"
      wait(50.ms) -> sendGenome worker

  broadcast = (f) ->
    for id in cluster.workers
      f cluster.workers[id]

  runWorker = ->
    worker = cluster.fork()
    worker.on 'message', (msg) ->
      msg = JSON.parse msg
      sendGenome worker       if 'hello'  of msg
      db.record msg.record    if 'record' of msg # no else, to support batch mode
      db.remove worker.genome if 'die'    of msg
      #if 'die' of msg
      #  console.log msg.die

  # reload workers if necessary
  cluster.on "exit", (worker, code, signal) ->
    wait(DELAY) -> runWorker() 

  # run workers over CPU cores
  [0..NB_CORES].map (i) -> runWorker()

  repeat 2.sec, ->

    g = db.pick()
    return unless g
    console.log "random individual:"
    console.log "  hash:     : #{g.hash}"
    console.log "  generation: #{g.generation}"
    console.log "  forking   : #{g.stats.forking_rate}"
    console.log "  mutation  : #{g.stats.mutation_rate}"
    console.log "  lifespan  : #{g.stats.lifespan_rate}\n"
    console.log " general stats:"
    console.log "  db size: #{db.size()}"
    console.log "  counter: #{db.counter}"
    console.log "  oldest : #{db.oldestGeneration()}\n"

# a worker iteration
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
      
      # eve is not killed until we fully bootstrapped the system
      # maybe it's optional, since there will die after all,
      # and we can achieve the same by stopping forking
      if genome.generation > 0 and Math.random() < lifespan_rate
        outputs die: "end of tree"

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
                stats: { mutation_rate, lifespan_rate, forking_rate }
            process.exit 0
      else
        process.exit 0
    else
      err = "error, unknow message: #{inspect msg}"
      console.log err
      process.exit 1

do if cluster.isMaster then MASTER else WORKER