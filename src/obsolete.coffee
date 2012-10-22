






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
  x6: 10

writable_variables =
  x1: 10
  x2: 10
  x3: 10
  x4: 10
  x5: 10
  x6: 10

writable_functions =     
  f1: 10
  f2: 10
  f3: 10
  f4: 10
  f5: 10
  f6: 10

callable_functions_ast = 
  f1: [ 'name', 'f1' ]
  f2: [ 'name', 'f2' ]
  f3: [ 'name', 'f3' ]
  f4: [ 'name', 'f4' ]
  f5: [ 'name', 'f5' ]
  f6: [ 'name', 'f6' ]
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



mutate = (options) -> async ->


  console.log "mutate #{options.src}"
  
  copy = []

  old_ast = jsp.parse options.src
  
  if options.debug
    console.log "old: #{inspect old_ast, false, 20, true}"

  # THIS + PROBAS => MUTATIONS RULES (defined in the higher level program)
  {nodes} = getNodes old_ast

  values = [
   ['num',0]
   ['num',1]
  ]
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


  # iterate a first time to cust some nodes
  cutOrCopyLoop = (node) ->

  
    clipboard = []
    # walk and mutate the tree
    _cutOrCopyLoop = (parent, id) ->

      console.log "\n1. parent: #{inspect parent}  id: #{id}"

      node = parent[id]
      console.log "2. node: #{inspect node}"

      # if we have an easy mutable node 
      if isArray node
        console.log "node is array (lenght: #{node.length})"
        if node.length is 0
          console.log "but node length is 0"
          return node

        if node.length is 1
          console.log "node is length 1: going inside"
          node[0] = _cutOrCopyLoop node, 0

        #console.log "node is array: #{inspect node}"
        nodeType = node[0]
        console.log "node type: #{nodeType}"

        # ignore the whole variable definition tree
        if nodeType in [ 'var' ]
          return node 

        
        ####################
        # CUT ASSIGNEMENTS #
        ####################
        if nodeType is 'assign'
          varName = node[2][1]

        ########################
        # CUT BINARY OPERATION #
        ########################
        if nodeType is 'binary'
          
          # probability of being copied
          if P 0.5 
            # copy to clipboard
            console.log "copying"
            #clipboard.push node

          # probability of being deleted
          if P 0.5
            # delete replacing by one of the two terms of the binary operation
            console.log "deleting"
            #parent[id] = node[if P(0.5) then 2 else 3]


        ########################
        # MUTATION OF A NUMBER #
        ########################
        if nodeType is 'num'
          0#node[1] = algo.mutateNumber node[1]

        ####################################
        # MUTATION OF CALLED FUNCTION NAME #
        ####################################
        if nodeType is 'call'
          varName = node[1][1]
          if varName of callable_variables
            0#node[1] = algo.substituteCallableVariableName node[1]
          else if varName of callable_functions
            0#node[1] = algo.substituteCallableFunctionAST node[1]

        ##################################
        # MUTATION OF VARIABLE REFERENCE #
        ##################################
        #if parent
        #  if (parent[0] isnt 'dot') and (parent[0] isnt 'call') and (node[0] is 'name')
        #    node[1] = substituteCallableVariableName node[1]

        console.log "don't iterate inside strings!"
        console.log "IGNORE MAIN ROOT FUNCTION, TOO!"

        #if nodeType in ['']

        if node.length > 1
          console.log "iterating over children"
        for i in [1..node.length]
          console.log "child #{i}: #{node[i]}"
          if isArray node[i]
            console.log "child #{i} is an array, calling recursive function"
            r = _cutOrCopyLoop node, i
            unless r is undefined
              console.log "overwriting child"
              node[i] = r
    
      #else
      #  if P 0.10
      #    console.log "node: #{node}"
      #    n = deck.pick nodes
      #    unless n is undefined
      #      node = n
      #console.log "node: #{node}"
      node
    console.log "node: #{inspect node} id: 0"

    root = node[1][0][1][0][1]
    inputs = root[2]
    statements = root[3]
    variables = root[3][0][1]
    outputs = root[3][-1..][1]
    console.log "root: #{inspect root}"
    console.log "statements: #{inspect statements, no, 20, yes}\n"

    console.log "inputs: #{inspect inputs}"
    console.log "variables: #{inspect variables}"
    console.log "outputs: #{inspect outputs}"


    # concat  [ [ vars = ...,]  WITH [ statement1, statement2 ] ]
    node[0][0] = [node[0][0][0]].concat _cutOrCopyLoop(node, 1)
    node: node, clipboard: clipboard

  # iterate
  addReplaceOrDitchLoop = (node,clipboard) ->

    console.log "addReplaceOrDitchLoop. Clipboard:"
    for element in clipboard
      console.log "  #{inspect element}"

    _addReplaceOrDitchLoop = (node,whatToDo='',parent=no) ->

    node


  # walk and mutate the tree
  mutateLoop = (node,parent=no) ->


    # if we have an easy mutable node 
    if isArray node
      
      if node.length is 0
        return node

      #console.log "node is array: #{inspect node}"

      nodeType = node[0]

      if node.length is 1
        node[0] = mutateLoop node[0], node

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
      #if parent
      #  if (parent[0] isnt 'dot') and (parent[0] isnt 'call') and (node[0] is 'name')
      #    node[1] = substituteCallableVariableName node[1]

      for i in [1..node.length]
        if isArray node[i]
          r = mutateLoop node[i], node
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


  if options.debug
    console.log "#{inspect old_ast, false, 20, true}"
    
  console.log "mutate loop"
  #new_ast = mutateLoop old_ast

  # this loop iterate over the AST, and randomly cut (or clone)
  # parts of it, to store the bits in a list
  console.log "cut or copy loop"

  res = cutOrCopyLoop old_ast
  new_ast = res.new_ast
  clipboard = res.clipboard

  # this part iterate over the clipboard, and randomly add, replace or delete
  # parts of it
  console.log "add, replace or ditch clipboard element loop"
  #new_ast = addReplaceOrDitchLoop old_ast, clipboard

  if options.debug
    console.log "copy: #{inspect new_ast, false, 20, true}"
  #if isArray(node) and node[0] is 'num'

  # 1. pick random or not-so-random element
  # choose action:
  # Copy, move or delete it
  
  try
    new_code = pro.gen_code new_ast, 
      beautify: options.beautify # – pass true if you want indented output
      indent_start: 0 # (only applies when beautify is true) – initial indentation in spaces
      indent_level: 4 #(only applies when beautify is true) – indentation level, in spaces (pass an even number)
      quote_keys: no # – if you pass true it will quote all keys in literal objects
      space_colon: no # (only applies when beautify is true) – wether to put a space before the colon in object literals

    # TODO would be simpler to just ignore vars, to allow recursive 
    header = "\n\n/* Global memory */ \n\nvar "
    for i in [1..options.nbVariables]
      header += "x#{i}=0,"
    header += "\n"
    for i in [1..options.nbFunctions]
      header += "f#{i}=function(){ return 0; },"
    header = "#{header[..-2]};\n\n"

    new_code = "#{header} /* Program */\n\n #{new_code}"

    #console.log "success after #{options.tentatives} tentatives"
    async -> options.onComplete new_code
  catch e
    #console.log "failed tentative #{options.tentatives}: #{e}"
    if options.tentatives < options.max_tentatives
      #console.log "trying again"
      options.tentatives += 1
      
      async ->
        mutate options, (new_code) -> 
          options.onComplete (new_code)
    else
      console.log "aborting after #{options.tentatives} tentatives: #{e}"
      async -> options.onComplete options.src 


###
optimizeAST = exports.optimizeAST = (options = {}) -> async ->
  #ast = pro.ast_mangle ast
  ast = pro.ast_squeeze ast,
    make_seq: yes # 
    dead_code: yes # don't remove junk code, it may have a purpose

  async -> options.onComplete ast
###

mutateSrc = exports.mutateSrc = (options = {}) -> async ->
  console.log "mutateSrc"
  opts =
    src:  ""
    nbVariables: 6
    nbFunctions: 6
    debug: no
    insist: no
    beautify: no
    tentatives: 0
    max_tentatives: 1
    onError: (err) -> throw err
    onComplete: (src) ->
  for k, v of options
    opts[k] = v
  console.log "options: #{inspect options}"

  mutate opts

mutateFile = exports.mutateFile = (options = {}) -> async ->
  console.log "mutateFile"
  opts =
    file: process.argv[1]
    debug: no
    insist: no
    beautify: no
    nbVariables: 6
    nbFunctions: 6
    max_tentatives: 1
    encoding: 'utf-8'
    onError: (err) -> 
      console.log "default mutate file onError: #{err}"
      throw err
    onComplete: (src) ->

  for k, v of options
    opts[k] = v

  fs.readFile opts.file, opts.encoding, (err, src) ->
    console.log "loaded : "
    if err
      console.log "couldn't load file: #{err}"
      async -> opts.onError err
      return

    console.log "calling mutateSrc"
    mutateSrc
      src: src
      debug: opts.debug
      max_tentatives: opts.max_tentatives
      beautify: opts.beautify
      nbVariables: opts.nbVariables
      nbFunctions: opts.nbFunctions
      onError: opts.onError
      onComplete: opts.onComplete


exports.cli = main = ->
  if process.argv.length > 2
    mutateFile
      debug: ('debug' in process.argv)
      max_tentatives: if ('insist' in process.argv) then 3 else 1
      beautify: ('pretty' in process.argv)
      encoding: 'utf-8'
      file: process.argv[2]
      onError: (err) -> 
        console.log "error: #{err}"
        throw err
      onComplete: (src) -> console.log src
  else
    mutateSrc
      src: fs.readFileSync('/dev/stdin').toString()
      debug: ('debug' in process.argv)
      max_tentatives: if ('insist' in process.argv) then 3 else 1
      beautify: ('pretty' in process.argv)
      onError: (err) ->
        console.log "error: #{err}"
        throw err

      onComplete: (src) -> console.log src

#exports.mutate = mutate = (f, cb) ->
#  mutateFunction f, cb

