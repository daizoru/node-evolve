jsp = require "../node_modules/uglify-js/lib/parse-js"
pro = require "../node_modules/uglify-js/lib/process"
cs2js = require('../node_modules/coffee-script').compile
js2cs = require('../node_modules/js2coffee/lib/js2coffee').build

fs = require 'fs'
{inspect} = require 'util'
{async} = require 'ragtime'
deck = require 'deck'

{makeRules} = require './rules'

copy = (a) -> JSON.parse(JSON.stringify(a))

P           = (p=0.5) -> + (Math.random() < p)
isFunction  = (obj) -> !!(obj and obj.constructor and obj.call and obj.apply)
isUndefined = (obj) -> typeof obj is 'undefined'
isArray     = (obj) -> Array.isArray obj
isString    = (obj) -> !!(obj is '' or (obj and obj.charCodeAt and obj.substr))
isNumber    = (obj) -> (obj is +obj) or toString.call(obj) is '[object Number]'
isBoolean   = (obj) -> obj is true or obj is false
isString    = (obj) -> !!(obj is '' or (obj and obj.charCodeAt and obj.substr))

exports.toAST = toAST = (f) -> jsp.parse f.toString()

# clone a function, with recopy errors
exports.clone = clone = (opts) -> 

  options = 
    src       : ""
    ratio     : 0.01
    iterations: 2
    pretty    : yes
    debug     : no
    ignore_var: no
    isCoffee  : no

    # global context - user-provided
    # I'm fraid I'll have to transform to the
    # context: "abs: (x) -> Math.abs(x)" form, in order to read the params
    context: -> [
      Math.abs    # the absolute value of a
      Math.acos   # arc cosine of a
      Math.asin   # arc sine of a
      Math.atan   # arc tangent of a
      Math.atan2  # arc tangent of a/b
      Math.ceil   # integer closest to a and not less than a
      Math.cos    # cosine of a
      Math.exp    # exponent of a (Math.E to the power a)
      Math.floor  # integer closest to a, not greater than a
      Math.log    # log of a base e
      Math.max    # the maximum of a and b
      Math.min    # the minimum of a and b
      Math.pow    # a to the power b
      Math.random # pseudorandom number 0 to 1 (see examples)
      Math.round  # integer closest to a (see rounding examples)
      Math.sin    # sine of a
      Math.sqrt   # square root of a
      Math.tan    # tangent of a
      Math.PI 
    ]
  
  # global data - shared among branchs
  globals = 
    callables: []
    readables: []
    writables: []

  mutations = 0 # simple stats for debug

  # Transform any path eg. like: ['dot', ['name','foo'], 'bar'] 
  # to 'foo.bar', recursively.
  resolve = (item) ->
    name = ""
    if item[0] is 'dot'
      sub = ""
      if isArray item[1]
        sub = ""+resolve(item[1])
      else
        sub = item[1][1]
      name = "#{sub}.#{item[2]}"
    else if item[0] is 'name'
      name = item[1]
    name

  ##########################################################
  #         ANALYSIS OF CONTEXT: TYPE DETECTION            #
  # FIRST WE PARSE THE USER-PROVIDED CONTEXT SOURCE TO AST #
  ##########################################################
  items = []
  try
    reservoir_ast = jsp.parse "RESERVOIR = #{options.context.toString()};", {}  
    items = reservoir_ast[1][0][1][3][3][0][1][1] # fuck this shit
    if options.debug
      console.log "imported context:"
  catch e
    console.log "couldn't run static analysis of context: #{e}"

  ###########################################################
  # THEN FOR EACH ENTRY, WE EVALUATE AND TRY TO DETECT TYPE #
  ###########################################################
  for item in items
    name = resolve item
    i = undefined
    try
      i = eval name
    catch e
      console.log "error when checking #{name}: #{e}"
      continue

    #####################################################
    # FINALLY WE PUT THE AST NODE IN THE RIGHT CATEGORY #
    #####################################################
    if isFunction i
      if options.debug
        console.log " - #{name} is a function"
      globals.callables.push name
    else if isArray i
      if options.debug
        console.log " - #{name} is an array - not supported yet"
    else if isNumber i
      if options.debug
        console.log " - #{name} is a number"
      globals.readables.push name
    else
      if options.debug
        console.log " - type of #{name} couldn't be found (value: #{i})"

  # use use-provided options - except rules which are not supported yet
  for k,v of opts
    unless k is 'rules'
      options[k] = v

  work = {}
  work.old_src = options.src

  if options.debug
    console.log "old_src: #{work.old_src}"

  if options.isCoffee
    work.old_src = cs2js work.old_src, bare: yes
    if options.debug
      console.log "old_src: #{work.old_src}"
    
  try
    work.old_ast = jsp.parse work.old_src, {}
  catch e1
    # dirty, dirty hack for uglify-js, which cannot parse code with a lambda as root:
    if e1.message is 'Unexpected token: punc (()'
      try
        work.old_ast = jsp.parse "var ROOT = #{work.old_src};", {}
        work.old_ast[1][0] = work.old_ast[1][0][1][0][1]
      catch e2
        console.log e2.message
        console.log "function wrapping failed: #{e1.message}"
        return
    else
      console.log "unsupported parsing error: #{e1.message}"

  ###################
  # MUTATE A BRANCH #
  ###################
  mutateBranch = (branch) ->

    locals =
      callables: []
      readables: []
      writables: []
    clipboard = []

    ######################################################
    # ANALYZE THE BRANCH: EXTRACT WRITABLES (AKA 'VARS') #
    ######################################################
    analyze = (parent, id) ->
      #console.log "analyze(#{parent},#{id})"
      #console.log "checking: #{inspect parent[id], no, 20, yes}"
      if isArray parent[id]
        type = parent[id][0] 
        if type is 'var'
          for w in parent[id][1]
            writable = ['name', w]
            locals.writables.push writable
        else if type is 'assign'
          writable = copy parent[id][2] # might be a name or a dot
          locals.writables.push writable
        for i in [0...parent[id].length]
          do (i) ->
            analyze parent[id], i++
      analyze [branch], 0


    #######################
    # MAKE MUTATION RULES #
    #######################
    rules = makeRules options, globals, locals, clipboard


    #################################################
    # MAIN FUNCTION: MUTATE RECURSIVELY AN AST TREE #
    #################################################
    transform = (parent, id) ->
      #console.log "recursive(#{parent},#{id})\nchecking: #{inspect parent[id], no, 20, yes}"
      if isArray parent[id]
        #console.log "is array. first try to apply rules"
        type = parent[id][0] 
        for name, rule of rules
          res = rule parent[id]...
          if isArray res
            mutations += 1
            parent[id] = res
        #console.log "then iterate over children recursively"
        for i in [0...parent[id].length]
          transform parent[id], i++

    #############################
    # APPLY MULTIPLE ITERATIONS #
    #############################

    # this serves many purposes: 
    # first, it is the main mecanism for copy-pasting blocks:
    # an iteration may copy data to a clipboard, and paste it else where
    # but also, this can create crazy compound mutations:
    # eg. 2 mutations: a copy and a multiplication, when applied individually
    # may kill the program, but when both are applied at the same time it works: 
    # this scenario can be solved by our iteration mecanism 
    for i in [0..options.iterations]
      if options.debug
        console.log "ITERATION #{i}"
      transform [branch], 0
      if options.debug
        console.log "new branch: #{inspect branch, no, 20, yes}"
    branch

  #####################################################
  # MUTATE CODE: FIRST TRY TO MUTATE EVOLVE() BLOCKS, #
  # ELSE TRY TO FALLBACK TO FIRST FUNCTION            #
  #####################################################
  mutateTree = (tree) ->
    found = no

    #####################################################
    # RECURSIVE SEARCH FOR ALL (evolve.?)mutable BLOCKS #
    #####################################################
    do search = (node=tree) ->
      if isArray node
        if node[0] is 'call'
          if "#{node[1]}" in ['dot,name,evolve,mutable','name,mutable']
            found = yes
            node[2][0][3] = mutateBranch copy node[2][0][3]
        else
          search n for n in node

    #############################################
    # FALL BACK TO MUTATING THE FIRST FUNCTION  #
    #############################################
    unless found
      branch = undefined
      try
        branch = tree#[1][0][1][3][3]
      catch e
        if options.debug
          console.log "couldn't find first function, aborting: #{e}"
      if branch
        if options.debug
          console.log "found function! mutating it.."
        tree = mutateBranch copy branch
      else
        if options.debug
          console.log "could not find branch"
    tree

  if options.debug
    console.log "old AST: #{inspect work.old_ast, no, 20, yes}\n\n\n\n"
  
  ################################
  # MUTATE THE PROGRAM TREE ROOT #
  ################################
  work.new_ast = mutateTree copy work.old_ast

  if options.isCoffee
    try
      if work.new_ast[1][0][0] is 'var'
        work.new_ast[1].shift()
    catch e
      if options.debug
        console.log "no var? good thing? #{e}"

  if options.debug
    console.log "new AST: #{inspect work.new_ast, no, 20, yes}"

  if options.debug
    console.log "applied #{mutations} mutations. generating code.."

  work.new_src = pro.gen_code work.new_ast, 
    beautify    : options.pretty # – pass true if you want indented output
    indent_start: 0 # only applies when beautify is true – initial indentation in spaces
    indent_level: 4 # only applies when beautify is true – indentation level, in spaces (pass an even number)
    quote_keys  : no  #  if you pass true it will quote all keys in literal objects
    space_colon : no # (only applies when beautify is true) – wether to put a space before the colon in object literals

  if options.isCoffee
    work.new_src = js2cs work.new_src, no_comments: no

  options.onComplete work.new_src


###############################################
# LIVE MUTATION AND REPLACEMENT OF A FUNCTION #
###############################################
exports.mutate = mutate = (obj, func, options={}) ->
  clone 
    src       : obj[func].toString()
    isCoffee  : options.isCoffee   ? no
    debug     : options.debug      ? no
    ratio     : options.ratio      ? 0.01
    iterations: options.iterations ? 2
    onComplete: (new_src) ->
      if options.debug
        console.log "obj[func] = #{new_src};"
      newFunction = eval "obj[func] = #{new_src};" # interpret the code to create the func
      if options.debug
        console.log "replaced function with #{newFunction}"
      obj[func] = newFunction
      options.onComplete()

#############################################################
# READ A FILE AND MUTATE IT - SPIT OUT OUTPUT TO A CALLBACK #
#############################################################
exports.readFile = readFile = (opts) ->
  options =
    file      : ''
    encoding  : 'utf-8'
    debug     : no
    ratio     : 0.01
    iterations: 1
    onError: (err) ->
  for k,v of opts
    options[k] = v

  fs.readFile options.file, options.encoding, (err, src) ->
    #console.log "loaded : "
    if err
      console.log "couldn't load file: #{err}"
      async -> options.onError err
      return

    isCoffee = options.file[-7..] is ".coffee"
    clone 
      src       : src
      isCoffee  : isCoffee
      debug     : options.debug
      ratio     : options.ratio
      iterations: options.iterations
      onComplete: (new_src) ->
        options.onComplete new_src


# magic wrapper
exports.mutable = mutable = (f) -> if isFunction f then f() else f

########################
# COMMAND-LINE PROGRAM # 
########################
exports.cli = main = ->

  # PARSE COMMAND-LINE ARGUMENTS
  args       = process.argv
  nb_args    = args.length
  file       = args[2]
  debug      = 'debug'  in args
  pretty     = 'pretty' in args
  encoding   = 'utf-8'
  ratio      = 0.10
  iterations = 1
  for a in args
    if a.lastIndexOf('ratio=', 0) is 0
      ratio = (Number) a[6..]

  # CONFIGURE PARAMS (INPUTS)
  config = {debug,pretty,encoding,ratio,iterations}

  # CONFIGURE CALLBACKS (OUTPUTS)
  config.onComplete = (src) -> console.log src
  config.onError    = (err) -> console.log "error: #{err}" ; process.exit(-1)

  # EITHER TRY TO LOAD A SPECIFIC JS FILE
  if nb_args > 2
    config.file = file
    readFile config

  # OR ELSE READ STDIN
  else
    config.src = fs.readFileSync('/dev/stdin').toString()
    clone config


