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

    # reservoir
    context:
      functions:
        'Math.cos': Math.cos
        'Math.sin': Math.sin
        'Math.random': Math.random
      constants:
        'Math.PI': Math.PI

    clipboard: []
    rules:
      decorators: {}

  options.rules =
      decorators:
        multiply: (type, value) -> 
          if type is 'num' and P(options.ratio * 0.2)
            [type, Math.random() * value]

        add: (type, value) -> 
          if type is 'num' and P(options.ratio * 0.2)
            [type, Math.random() + value]

        change_operator: (type, operator, a, b) ->
          if type is 'binary' and P(options.ratio* 0.3)
            if options.debug
              console.log "change operator for #{type}, #{operator}, #{a}, #{b}"
            operators = ['+','-','*','/']
            idx = operators.indexOf operator
            if idx != -1  
              operators.splice idx, 1
            [type, deck.pick(operators), a, b]

        switch_terms: (type, operator, a, b) ->
          if type is 'binary' and P(options.ratio *0.1)
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
          if type is 'read_variable' and P(options.ratio * 0.1)
            [type, deck.pick(options.context.constants)]

        change_write_variable: (type, name, write_variables) ->
          if type is 'write_variable' and P(options.ratio * 0.1)
            [type, name]

        copy_term: (type,name,a,b) ->
          if type is 'binary' and P(options.ratio * 0.1)
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
          if type is 'string' and P(options.ratio * 0.05)
            chars = value.split ''
            other_chars = "abcefghijklmnopqrstuvwxyz0123456789 ".split ''
            new_chars = []
            r = -> chars[Math.round(Math.random() * other_chars.length)]
            for c in chars
              if P(0.9) 
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

  clipboard = []

  searchMutable = (node) ->
    results = []

    recursive = (node) ->

      if isArray node
        found = no
        if node[0]  is 'call'
          if node[1][0] is 'dot'
            if isArray node[1][1] 
              if node[1][1][0] is 'name' and node[1][1][1] is 'evolve'
                if node[1][2] is 'mutable'
                  found = yes
          else if node[1][0] is 'name'
            if node[1][1] is 'mutable'
              found = yes
        
        if found
          results = [node,copy(node[2][0][3])]
        else
          for n in node
            recursive n
    recursive node

    results


  constant_tree = copy work.old_ast 
  mutableResult = searchMutable constant_tree
  if mutableResult.length > 0
  else
    console.log "not found.."
    return
  [constant_tree_hook,mutable_tree] = mutableResult

  mutations = 0

  passOne = ->

    recursive = (parent, id) ->
      if isArray parent[id]
        i = 0
        for n in parent[id]
          recursive parent[id], i++

      # NOT A BUG

      if isArray parent[id]
        if parent[id][0] in [ 'num', 'binary', 'string' ]
          for decoratorName, decorator of options.rules.decorators
            res = decorator parent[id]...
            if isArray res
              mutations += 1
              parent[id] = res


    recursive [mutable_tree], 0

    if options.debug
      console.log "pass one"

  passOne()
  
  # todo rather than a pass one and two, maybe just do N iterations?

  # second pass, to past elements of the clipboard
  passTwo = ->
    if options.debug
      console.log "pass two"

  passTwo()
  
  if options.debug
    console.log "mutable_tree: #{inspect mutable_tree, no, 20, yes}"

  constant_tree_hook[2][0][3] = mutable_tree

  work.new_ast = copy constant_tree

  if options.debug
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


# mutate replace a function inline!
exports.mutate = mutate = (options) ->
  if options.debug
    console.log "mutate options: #{inspect options}"
  clone 
    src: options.obj[options.func].toString()
    debug: options.debug
    ratio: options.ratio
    onComplete: (new_src) ->

      newFunction = eval new_src

      console.log "replaced function with #{newFunction}"
      options.obj[options.func] = newFunction
      options.onComplete()

# mutate replace a function inline!
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

