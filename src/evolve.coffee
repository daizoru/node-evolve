jsp = require "../node_modules/uglify-js/lib/parse-js"
pro = require "../node_modules/uglify-js/lib/process"
fs = require 'fs'
{inspect} = require 'util'
{async} = require 'ragtime'
deck = require 'deck'

###
TODO substitute numbers, variables, called functions.. by
themselves
also: delete them, or duplicate them
or add a random new one


###

clone = (a) -> JSON.parse(JSON.stringify(a))

P           = (p=0.5) -> + (Math.random() < p)
isFunction  = (obj) -> !!(obj and obj.constructor and obj.call and obj.apply)
isUndefined = (obj) -> typeof obj is 'undefined'
isArray     = (obj) -> Array.isArray obj
isString    = (obj) -> !!(obj is '' or (obj and obj.charCodeAt and obj.substr))
isNumber    = (obj) -> (obj is +obj) or toString.call(obj) is '[object Number]'
isBoolean   = (obj) -> obj is true or obj is false
isString    = (obj) -> !!(obj is '' or (obj and obj.charCodeAt and obj.substr))

options = {}

code_to_ast = (code) -> (cb) -> async ->
  cb jsp.parse code, options.strict_semicolons

optimize_ast = (ast) -> (cb) -> async ->
  ast = pro.ast_mangle ast, options.mangle_options
  async ->
    ast = pro.ast_squeeze ast, options.squeeze_options
    async ->
      cb ast

getNodes = (root) ->
  # put all nodes in one big list
  # THIS + PROBAS => MUTATIONS RULES (defined in the higher level program)
  nodes = []
  parse = (list) ->
    if isArray list
      for item in list
        nodes.push item
      for item in list
        if isArray
          parse item
  parse root
  nodes: nodes

# THIS PART SHOULD NOT MUTATE!

callable_variables =
  x1: 10
  x2: 10
  x3: 10
  x4: 10
  x5: 10

writable_variables =
  x1: 10
  x2: 10
  x3: 10
  x4: 10
  x5: 10

writable_functions =     
  f1: 10
  f2: 10
  f3: 10
  f4: 10
  f5: 10

callable_functions_ast = 
  f1: [ 'name', 'f1' ]
  f2: [ 'name', 'f2' ]
  f3: [ 'name', 'f3' ]
  f4: [ 'name', 'f4' ]
  f5: [ 'name', 'f5' ]
  # library
  'Math.cos': [ 'dot', ['name', 'Math'], 'cos' ]
  'Math.sin': [ 'dot', ['name', 'Math'], 'sin' ]
callable_functions = {}
for k,v of callable_functions_ast
  callable_functions[k] = 10

fidelity = 0.95

THIS_CODE_CAN_BE_MUTATED_TOO =

  mutateNumber: (value) ->

    if P fidelity
      return value

    #console.log "num!!"
    numOperations =
      mult: 5000

    action = deck.pick numOperations
    #console.log "action: #{action}"
    switch action
      when 'mult'
        console.log "MUTATION: NUMBER #{value} * Math.random()"
        return value * Math.random()
    return value

  substituteValueNode: (value, values) ->
    if P fidelity
      value
    else
      ast = deck.pick values
      if isUndefined ast
        value
      else
        ast

  substituteCallableFunctionAST: (value) ->
    #console.log "substituteCallableFunctionAST #{value}"
    if P fidelity # this value may be computed using current machine state, aka. previous events
      value
    else
      f = deck.pick callable_functions
      callable_functions_ast[f]

  substituteCallableFunctionName: (value) ->
    #console.log "substituteCallableFunctionName #{value}"
    if P fidelity
      value
    else
      deck.pick callable_functions


  substituteWritableFunctionName: (value) ->
    #console.log "substituteWritableFunctionName #{value}"
    if P fidelity
      value
    else
      ['name', deck.pick writable_functions]

  substituteWritableVariableName: (value) ->
    #console.log "substituteWritableVariableName #{value}"
    if P fidelity
      value
    else
      varName = deck.pick writable_variables
      #console.log "MUTATION: VARIABLE REF #{value} BECOMES #{varName}"
      unless varName is undefined
        return ['name', varName]
      value

  substituteCallableVariableName: (value) ->
    #console.log "substituteCallableVariableName #{value}"
    if P fidelity
      value
    else
      ['name', deck.pick callable_variables]

  substituteBinaryOperator: (value) ->
    if P fidelity
      value
    else
      operators =
        '+': 100
        '/':  50
        '-': 100
        '*': 150
        '^':   5
      deck.pick operators



mutate = (old_code, tmin, tmax, dbg, cb) -> async ->
  copy = []

  old_ast = jsp.parse old_code, options.strict_semicolons
  
  if dbg
    console.log "old: #{inspect old_ast, false, 20, true}"

  # THIS + PROBAS => MUTATIONS RULES (defined in the higher level program)
  {nodes} = getNodes old_ast

  values = []
  for node in nodes
    #console.log "testing node: #{node}"
    if isArray node
      if node[0] in ['call', 'name','num']

        # in 'name' we only authorize variables, not functions
        # (functions are in 'call')
        if node[0] is 'name'
          unless node[1] in callable_variables
            continue
        k = "#{node[0]}"
        #console.log "writing using '#{k}'"
        values.push node
        

  #console.log "values: #{inspect values}"
  # list of authorized variables and functions
  # TODO should be built from  a magicRequire('library.js') function, no?

  algo = THIS_CODE_CAN_BE_MUTATED_TOO

  # walk and mutate the tree
  transform = (node,n0='') ->


    # if we have an easy mutable node 
    if isArray node
      
      if node.length is 0
        return node

      #console.log "node is array: #{inspect node}"

      nodeType = node[0]

      if node.length is 1
        node[0] = transform node[0], ''

      # ignore the whole variable definition tree
      if nodeType in [ 'var' ]
        return node 

      ###########################
      # MUTATION OF ASSIGNEMENT #
      ###########################
      if nodeType is 'assign'
        varName = node[2][1]

        if varName of writable_variables
          node[2] = algo.substituteWritableVariableName node[2]
          #console.log "variable assignement of #{varName} BECOMES #{newName}"


        else if varName of writable_functions
          node[2] = algo.substituteWritableFunctionName node[2]
          #console.log "function assignement of #{varName} BECOMES #{newName}"

      ###########################################################
      # MUTATION BY COPY, DESTRUCTION OR DISPLACEMENT OF A TERM #
      ###########################################################

      # TODO


      ################################
      # MUTATION OF BINARY OPERATION #
      ################################
      if nodeType is 'binary'
        node[1] = algo.substituteBinaryOperator node[1]
        node[2] = algo.substituteValueNode node[2], values
        node[3] = algo.substituteValueNode node[3], values


      ########################
      # MUTATION OF A NUMBER #
      ########################
      if nodeType is 'num'
        node[1] = algo.mutateNumber node[1]

      ####################################
      # MUTATION OF CALLED FUNCTION NAME #
      ####################################
      if nodeType is 'call'
        varName = node[1][1]
        if varName of callable_variables
          node[1] = algo.substituteCallableVariableName node[1]
        else if varName of callable_functions
          node[1] = algo.substituteCallableFunctionAST node[1]

      ##################################
      # MUTATION OF VARIABLE REFERENCE #
      ##################################
      #if (n0 isnt 'dot') and (n0 isnt 'call') and (node[0] is 'name')
      #  node[1] = substituteCallableVariableName node[1]

      for i in [1..node.length]
        if isArray node[i]
          r = transform node[i], nodeType
          unless r is undefined
            node[i] = r
  
    #else
    #  if P 0.10
    #    console.log "node: #{node}"
    #    n = deck.pick nodes
    #    unless n is undefined
    #      node = n
    #console.log "node: #{node}"
    node

  new_ast = transform old_ast

  if dbg
    console.log "copy: #{inspect new_ast, false, 20, true}"
  #if isArray(node) and node[0] is 'num'

  # 1. pick random or not-so-random element
  # choose action:
  # Copy, move or delete it


  try
    new_code = pro.gen_code new_ast, options.gen_options

    header = "////////// MEMORY ////////// \nvar x0=0"
    for i in [1..6]
      header += ", x#{i}=0"
    header += ";\n"
    for i in [1..6]
      header += "var f#{i}=function(){ return 0; };\n"

    new_code = "#{header} /////// END OF MEMORY ////////\n\n #{new_code}"

    console.log "success after #{tmin} tentatives"
    async ->  cb new_code
  catch e
    #console.log "failed tentative #{tmin}: #{e}"
    if tmin < tmax
      #console.log "trying again"
      async -> mutate old_code, tmin + 1, tmax, dbg, cb
    else
      console.log "aborting after #{tmin} tentatives"
      async -> cb old_code 


mutateSrc = exports.mutateSrc = (options = {}) -> async ->
  console.log "mutateSrc"
  opts =
    src:  ""
    debug: no
    insist: no
    tentatives: 1
    onError: (err) -> throw err
    onComplete: (src) ->
  for k, v of options
    opts[k] = v
  console.log "options: #{inspect options}"
  if opts.debug
    console.log src
  mutate opts.src, 0, opts.tentatives, opts.debug, (src) -> 
    async -> opts.onComplete(src)

mutateFile = exports.mutateFile = (options = {}) -> async ->
  console.log "mutateFile"
  opts =
    file: process.argv[1]
    debug: no
    insist: no
    tentatives: 1
    encoding: 'utf-8'
    onError: (err) -> throw err
    onComplete: (src) ->

  for k, v of options
    opts[k] = v

  fs.readFile opts.file, opts.encoding, (err, src) ->
    if err
      async -> opts.onError err
      return
    mutateSrc
      src: src
      debug: opts.debug
      tentatives: opts.tentatives
      onError: (err) -> async -> opts.onError err
      onComplete: (src) -> async -> opts.onComplete src


exports.cli = main = ->
  if process.argv.length > 2
    mutateFile
      debug: ('debug' in process.argv)
      tentatives: if ('insist' in process.argv) then 3 else 1
      encoding: 'utf-8'
      file: process.argv[2]
      onError: (err) -> throw err
      onComplete: (src) -> console.log src
  else
    mutateSrc
      src: fs.readFileSync('/dev/stdin').toString()
      debug: ('debug' in process.argv)
      tentatives: if ('insist' in process.argv) then 3 else 1
      onError: (err) -> throw err
      onComplete: (src) -> console.log src
