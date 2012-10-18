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
    ratio: 0.5

    pretty: yes

    reservoir:
      functions:
        'Math.cos': Math.cos
        'Math.sin': Math.sin
        'Math.random': Math.random
      constants:
        'Math.PI': Math.PI

  options.rules =
      decorators:
        multiply: (type, value) -> 
          if type is 'num' and P 0.5
            [type, Math.random() * value]

        add: (type, value) -> 
          if type is 'num' and P 0.5
            [type, Math.random() + value]

        change_operator: (type, operator, first, second) ->
          if type is 'binary' and P 1.0
            console.log "change operator for #{type}, #{operator}, #{first}, #{second}"
            operators = ['+','-','*','/']
            idx = operators.indexOf operator
            if idx != -1  
              operators.splice idx, 1
            [type, deck.pick(operators), first, second]

        switch_terms: (type, operator, first, second) ->
          if type is 'binary' and P 0.5
            console.log "switching terms for #{type}, #{operator}, #{first}, #{second}"
            [type, operator, second, first]

        delete_term: (type, operator, first, second) ->
          if type is 'binary' and P 0.0
            console.log "deleting term for #{type}, #{operator}, #{first}, #{second}"
            if P 0.5 then first else second

        duplicate_term: (type, operator, first, second) ->
          if type is 'binary' and P 0.0
            console.log "duplicate_term for #{type}, #{operator}, #{first}, #{second}"
            cpy = copy [type, operator, first, second]
            if P 0.5 
              [type, operator, cpy, second]
            else 
              [type, operator, first, cpy]


        # change a read-only variable
        change_read_variable: (type, name, read_variables) ->
          if type is 'read_variable' and P 0.5
            [type, deck.pick(options.reservoir.constants)]

        change_write_variable: (type, name, write_variables) ->
          if type is 'write_variable' and P 0.5
            [type, name]

  for k,v of opts
    options[k] = v


  console.log "options: #{inspect options}"
  work.old_src = work.src


  console.log "old_src: #{work.old_src}"
  try
    work.old_ast = jsp.parse "ENDPOINT = #{work.old_src};", {}
  catch e
    console.log e.message
  
  console.log "old_ast: #{work.old_ast}"
  work.reservoir = options.reservoir

  clipboard = []

  searchMutable = (node) ->
    results = []

    recursive = (node) ->

      if isArray node
        found = no
        if node[0]  is 'call'
          #console.log "call: #{inspect node}"
          if node[1][0] is 'dot'
            #console.log "dot"
            if isArray node[1][1] 
              if node[1][1][0] is 'name' and node[1][1][1] is 'evolve'
                #console.log "found evolve module. node[1][2] is : #{inspect node[1][2]}"
                if node[1][2] is 'mutable'
                  #console.log "found yes!!"
                  found = yes
          else if node[1][0] is 'name'
            #console.log "name"
            if node[1][1] is 'mutable'
              found = yes
        
        if found
          #console.log "found yes!!!!! pushing #{inspect node[2][0][3]}"
          results = [node,copy(node[2][0][3])]
        else
          for n in node
            recursive n
    recursive node

    results


  constant_tree = copy work.old_ast 
  mutableResult = searchMutable constant_tree
  if mutableResult.length > 0
    console.log "found mutable function: #{mutableResult[1]}"
  else
    console.log "not found.."
    return
  [constant_tree_hook,mutable_tree] = mutableResult

  passOne = ->

    recursive = (parent, id) ->

      console.log "in node #{parent[id]}"
      if isArray parent[id]
        i = 0
        for n in parent[id]
          recursive parent[id], i++

      # NOT A BUG

      if isArray parent[id]
        switch parent[id][0]
          when 'num'
            for decoratorName, decorator of options.rules.decorators
              #console.log "applying rule #{decoratorName} to #{parent[id]}"
              res = decorator parent[id]...
              unless isUndefined res
                parent[id] = res

          when 'binary'
            for decoratorName, decorator of options.rules.decorators
              res = decorator parent[id]...
              if isArray res
                console.log "result: type: #{res[0]}, operator: #{res[1]}, first: #{res[2]}, second: #{res[3]}"
              
                parent[id] = res

        
    recursive [mutable_tree], 0

    console.log "pass one"

  passOne()

  # second pass, to past elements of the clipboard
  passTwo = ->
    console.log "pass two"

  passTwo()
  
  console.log "mutable_tree: #{inspect mutable_tree, no, 20, yes}"

  console.log "modifying the original buffer tree.."
  constant_tree_hook[2][0][3] = mutable_tree

  work.new_ast = copy constant_tree

  console.log "new_ast: #{inspect work.new_ast, no, 20, yes}"

  console.log "generating code.."
  work.new_src = pro.gen_code work.new_ast, 
    beautify: options.pretty # – pass true if you want indented output
    indent_start: 0 # (only applies when beautify is true) – initial indentation in spaces
    indent_level: 4 #(only applies when beautify is true) – indentation level, in spaces (pass an even number)
    quote_keys: no # – if you pass true it will quote all keys in literal objects
    space_colon: no # (only applies when beautify is true) – wether to put a space before the colon in object literals

  console.log "work terminated"
  options.onComplete work.new_src


# mutate replace a function inline!
exports.mutate = mutate = (options) ->
  console.log "mutate options: #{inspect options}"
  clone 
    src: options.obj[options.func].toString()
    onComplete: (new_src) ->

      newFunction = eval new_src

      console.log "replacing function with #{newFunction}"
      options.obj[options.func] = newFunction
      options.onComplete()

# mutate replace a function inline!
exports.readFile = readFile = (opts) ->
  options =
    file: ''
    encoding: 'utf-8'
    onError: (err) ->
  for k,v of opts
    options[k] = v

  console.log "mutate options: #{inspect options}"

  fs.readFile options.file, options.encoding, (err, src) ->
    console.log "loaded : "
    if err
      console.log "couldn't load file: #{err}"
      async -> options.onError err
      return

    clone 
      src: src
      onComplete: (new_src) ->
        options.onComplete new_src


# simple marker
exports.mutable = mutable = (f) -> f()

m
exports.cli = main = ->
  if process.argv.length > 2
    readFile
      debug: ('debug' in process.argv)
      pretty: ('pretty' in process.argv)
      encoding: 'utf-8'
      file: process.argv[2]
      onError: (err) -> 
        console.log "error: #{err}"
        throw err
      onComplete: (src) -> console.log src
  else
    clone
      src: fs.readFileSync('/dev/stdin').toString()
      debug: ('debug' in process.argv)
      pretty: ('pretty' in process.argv)
      onError: (err) ->
        console.log "error: #{err}"
        throw err
      onComplete: (src) -> console.log src

