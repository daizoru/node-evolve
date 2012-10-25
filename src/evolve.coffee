jsp = require "../node_modules/uglify-js/lib/parse-js"
pro = require "../node_modules/uglify-js/lib/process"
fs = require 'fs'
{inspect} = require 'util'
{async} = require 'ragtime'
deck = require 'deck'

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

    src: ""
    ratio: 0.001

    pretty: yes

    debug: no

    ignore_var: no

    # reservoir
    context: -> [
      Math.cos
      Math.sin
      Math.random
      Math.PI
    ]

    reservoir: 
      callables: []
      constants: []
      writables: []

    clipboard: []
    rules:
      decorators: {}


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

  items = []
  try
    reservoir_ast = jsp.parse "RESERVOIR = #{options.context.toString()};", {}  
    items = reservoir_ast[1][0][1][3][3][0][1][1] # fuck this shit
    console.log "imported context:"
  catch e
    console.log "couldn't run static analysis of context: #{e}"
  for item in items
    name = resolve item
    i = undefined
    try
      i = eval name
    catch e
      console.log "error when checking #{name}: #{e}"
      continue
    if isFunction i
      console.log " - #{name} is a function"
      options.reservoir.callables.push name
    else if isArray i
      console.log " - #{name} is an array - not supported yet"
    else if isNumber i
      console.log " - #{name} is a number"
      options.reservoir.constants.push name
    else
      console.log " - type of #{name} couldn't be found (value: #{i})"

  options.rules =
      decorators:
        multiply: (type, value) -> 
          console.log "in multiply(#{type},#{value})"
          if type is 'num' and P(options.ratio * 1.0)
            console.log "multiplying.."
            [type, Math.random() * value]

        add: (type, value) -> 
          if type is 'num' and P(options.ratio * 1.0)
            [type, Math.random() + value]

        change_operator: (type, operator, a, b) ->
          if type is 'binary' and P(options.ratio* 1.0)
            if options.debug
              console.log "change operator for #{type}, #{operator}, #{a}, #{b}"

            operators = ['+','-','*','/']
         
            idx = operators.indexOf operator
            if idx != -1  
              operators.splice idx, 1
            [type, deck.pick(operators), a, b]

        switch_terms: (type, operator, a, b) ->
          if type is 'binary' and P(options.ratio * 1.0)
            if options.debug
             console.log "switching terms for #{type}, #{operator}, #{a}, #{b}"
            [type, operator, b, a]

        delete_term: (type, operator, a, b) ->
          if type is 'binary' and P(options.ratio * 0.0)
            if options.debug
              console.log "deleting term for #{type}, #{operator}, #{a}, #{b}"
            if P 0.5 then a else b

        duplicate_term: (type, operator, a, b) ->
          if type is 'binary' and P(options.ratio * 0.0)
            if options.debug
              console.log "duplicate_term for #{type}, #{operator}, #{a}, #{b}"
            cpy = copy [type, operator, a, b]
            if P 0.5
              [type, operator, cpy, b]
            else 
              [type, operator, a, cpy]

        # change a read-only variable
        change_read_variable: (type, name, read_variables) ->
          if type is 'read_variable' and P(options.ratio * 1.0)
            [type, deck.pick(options.reservoir.constants)]

        change_write_variable: (type, x, output, input) ->
          if type is 'assign' and P(options.ratio * 1.0)
            console.log "changing assignment"
            [type, x, deck.pick(options.reservoir.constants), input]

        copy_term: (type,name,a,b) ->
          if type is 'binary' and P(options.ratio * 1.0)
            node = copy([type,name,a,b])
            if options.debug
              console.log "copying #{inspect node}"
            options.clipboard.push node
            node

        # no probability on this one - it is controlled by copy_term
        paste_replace: (type, operator, a, b) ->
          if type is 'binary' and options.clipboard.length > 0
            options.clipboard[0]
            options.clipboard.shift()

        # no probability on this one - it is controlled by copy_term
        paste_insert: (type, operator, a, b) ->
          if type is 'binary' and options.clipboard.length > 0
            node = options.clipboard[0]
            options.clipboard.shift()
            t = if P(0.5) then 2 else 3
            node[t] = [type, operator, a, b]
            node

        # no probability on this one - it is controlled by copy_term
        mutate_string: (type, value) ->
          if type is 'string' and P(options.ratio * 1.0)
            chars = value.split ''
            other_chars = "abcefghijklmnopqrstuvwxyz0123456789 ".split ''
            new_chars = []
            r = -> chars[Math.round(Math.random() * other_chars.length)]
            for c in chars
              if P(0.5) 
                new_chars.push c
              else
                c2 = r()
                unless isUndefined c2
                  new_chars.push c2
            ['string', new_chars.join('')]

  for k,v of opts
    options[k] = v

  work = {}
  work.old_src = options.src

  #if options.debug
  #  console.log "old_src: #{work.old_src}"
  try
    work.old_ast = jsp.parse "ENDPOINT = #{work.old_src};", {}
  catch e
    console.log e.message
  
  #if options.debug
  #  console.log "old_ast: #{work.old_ast}"
  work.context = options.context

  mutations = []


  ###################
  # MUTATE A BRANCH #
  ###################
  mutateBranch = (branch) ->

    branch_data =
      callables: []
      constants: []
      writables: []

      clipboard: []

    ######################################################
    # ANALYZE THE BRANCH: EXTRACT WRITABLES (AKA 'VARS') #
    ######################################################
    analyze = (parent, id) ->
      console.log "analyze(#{parent},#{id})"
      console.log "checking: #{inspect parent[id], no, 20, yes}"
      if isArray parent[id]
        console.log "is array. first try to apply decorators"
        type = parent[id][0] 
        if type is 'var'
          for w in parent[id][1]
            writable = ['name', w]
            branch_data.writables.push writable
        else if type is 'assign'
          writable = copy parent[id][2] # might be a name or a dot
          branch_data.writables.push writable
        for i in [0...parent[id].length]
          do (i) ->
            analyze parent[id], i++
      analyze [branch], 0

    #################################################
    # MAIN FUNCTION: MUTATE RECURSIVELY AN AST TREE #
    #################################################
    transform = (parent, id) ->
      console.log "recursive(#{parent},#{id})\nchecking: #{inspect parent[id], no, 20, yes}"
      if isArray parent[id]
        console.log "is array. first try to apply decorators"
        type = parent[id][0] 
        if type in [ 'num', 'binary', 'string', 'assign' ]
          console.log "applying rules"
          for decoratorName, decorator of options.rules.decorators
            do (decoratorName, decorator) ->
              res = decorator parent[id]...
              if isArray res
                mutations += 1
                parent[id] = res
        console.log "then iterate over children recursively"
        for i in [0...parent[id].length]
          do (i) ->
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
    nb iterations = 1
    for i in [0..nb_iterations]
      console.log "ITERATION #{i}"
      transform [branch], 0
      console.log "new branch: #{inspect branch, no, 20, yes}"

  #################################################################
  # MUTATE CODE: IT TRIES FIRST TO MUTATE EVOLVE() BLOCKS, BUT IF #
  # NOTHING IS FOUND THEN IT FALLBACK TO MUTATING FIRST FUNCTION  #
  #################################################################
  mutateTree = (tree) ->
    found = no
    search = (node) ->
      if options.debug
        console.log "#{inspect node, false, 20, true}"
      if isArray node
        if node[0] is 'call'
          if "#{node[1]}" in ['dot,name,evolve,mutable','name,mutable']
            found = yes
            node[2][0][3] = mutateBranch copy node[2][0][3]
        else
          for n in node
            search n
    search tree
    #############################################
    # FALL BACK TO MUTATING THE FIRST FUNCTION  #
    #############################################
    unless found
      branch = []
      try
        branch = copy tree[1][0][1][3][3]
      catch e
        console.log "couldn't find first function, aborting: #{e}"
      if branch.length > 0
        console.log "found function! mutating it.."
        tree[1][0][1][3][3] = mutateBranch branch
    tree

  ################################
  # MUTATE THE PROGRAM TREE ROOT #
  ################################
  work.new_ast = mutateTree copy work.old_tree

  #if options.debug
  console.log "new_ast: #{inspect work.new_ast, no, 20, yes}"

  console.log "done #{mutations} mutations"
  if options.debug
    console.log "generating code.."
  work.new_src = pro.gen_code work.new_ast, 
    beautify: options.pretty # – pass true if you want indented output
    indent_start: 0 # (only applies when beautify is true) – initial indentation in spaces
    indent_level: 4 #(only applies when beautify is true) – indentation level, in spaces (pass an even number)
    quote_keys: no # – if you pass true it will quote all keys in literal objects
    space_colon: no # (only applies when beautify is true) – wether to put a space before the colon in object literals

  options.onComplete work.new_src


###############################################
# LIVE MUTATION AND REPLACEMENT OF A FUNCTION #
###############################################
exports.mutate = mutate = (options) ->
  if options.debug
    console.log "mutate options: #{inspect options}"
  clone 
    src: options.obj[options.func].toString()
    debug: options.debug
    ratio: options.ratio
    onComplete: (new_src) ->
      newFunction = eval new_src # interpret the code to create the func
      console.log "replaced function with #{newFunction}"
      options.obj[options.func] = newFunction
      options.onComplete()

#############################################################
# READ A FILE AND MUTATE IT - SPIT OUT OUTPUT TO A CALLBACK #
#############################################################
exports.readFile = readFile = (opts) ->
  options =
    file: ''
    encoding: 'utf-8'
    debug: no
    ratio: 0.001
    onError: (err) ->
  for k,v of opts
    options[k] = v


  #if options.debug
  #  console.log "mutate options: #{inspect options}"

  fs.readFile options.file, options.encoding, (err, src) ->
    #console.log "loaded : "
    if err
      console.log "couldn't load file: #{err}"
      async -> options.onError err
      return

    clone 
      src: src
      debug: options.debug
      ratio: options.ratio
      onComplete: (new_src) ->
        options.onComplete new_src


# simple marker
exports.mutable = mutable = (f) -> f()

exports.cli = main = ->
  ratio = 0.001
  if ('+' in process.argv)
    ratio = 0.01
  else if ('++' in process.argv) 
    ratio = 0.05
  else if ('+++' in process.argv)
    ratio = 0.10
  else if ('++++' in process.argv)
    ratio = 0.20
  else if ('+++++' in process.argv)
    ratio = 0.40
  else if ('++++++' in process.argv)
    ratio = 0.60
  else if ('+++++++' in process.argv)
    ratio = 0.80
  else if ('++++++++' in process.argv)
    ratio = 0.90
  console.log "ratio: #{ratio}"

  if process.argv.length > 2
    readFile
      debug: ('debug' in process.argv)
      pretty: ('pretty' in process.argv)
      encoding: 'utf-8'
      file: process.argv[2]
      ratio: ratio
      onError: (err) -> 
        console.log "error: #{err}"
        throw err
      onComplete: (src) -> console.log src
  else
    clone
      src: fs.readFileSync('/dev/stdin').toString()
      debug: ('debug' in process.argv)
      pretty: ('pretty' in process.argv)
      ratio: ratio
      onError: (err) ->
        console.log "error: #{err}"
        throw err
      onComplete: (src) -> console.log src

