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
    f: ->
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
          if type is 'number' and P 0.9
            [type, Math.random() * value]
          else
            [type, value]

        add: (type, value) -> 
          if type is 'number' and P 0.9
            [type, Math.random() + value]
          else
            [type, value]

        change_operator: (type, operator, first, second) ->
          if type is 'operation' and P 0.9
            [type, deck.pick ['+','-','*','/'], first, second]
          else
            [type, operator, first, second]

        switch_terms: (type, operator, first, second) ->
          if type is 'operation' and P 0.9
            [type, operator, second, first]
          else
            [type, operator, first, second]

        delete_term: (type, operator, first, second) ->
          if type is 'operation' and P 0.9
            if P 0.5 then first else second
          else
            [type, operator, first, second]

        duplicate_term: (type, operator, first, second) ->
          if type is 'operation' and P 0.9
            if P 0.5 
              [type, operator, [type, operator, first, second], second]
            else 
              [type, operator, first, [type, operator, first, second]]
          else
            [type, operator, first, second]

        # change a read-only variable
        change_read_variable: (type, name, read_variables) ->
          if type is 'read_variable' and P 0.9
            [type, deck.pick(options.reservoir.constants)]
          else
            [type, name]

        change_write_variable: (type, name, write_variables) ->
          if type is 'write_variable' and P 0.9
            [type, name]

  for k,v of opts
    options[k] = v


  console.log "options: #{inspect options}"
  work = old_func: options.f
  work.old_src = work.old_func.toString()


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

  work.new_func = eval work.new_src
  
  console.log "work terminated"
  options.onComplete work.new_func


# mutate replace a function inline!
exports.mutate = mutate = (options) ->
  console.log "mutate options: #{inspect options}"
  clone 
    f: options.obj[options.func]
    onComplete: (newFunction) ->
      console.log "replacing function with #{newFunction}"
      options.obj[options.func] = newFunction
      options.onComplete()

# simple marker
exports.mutable = mutable = (f) -> f()

