
{inspect} = require 'util'
deck = require 'deck'

copy = (a) -> JSON.parse JSON.stringify a

P           = (p=0.5) -> + (Math.random() < p)
isFunction  = (obj) -> !!(obj and obj.constructor and obj.call and obj.apply)
isUndefined = (obj) -> typeof obj is 'undefined'
isArray     = (obj) -> Array.isArray obj
isString    = (obj) -> !!(obj is '' or (obj and obj.charCodeAt and obj.substr))
isNumber    = (obj) -> (obj is +obj) or toString.call(obj) is '[object Number]'
isBoolean   = (obj) -> obj is true or obj is false
isString    = (obj) -> !!(obj is '' or (obj and obj.charCodeAt and obj.substr))


################################################
# MAKE RULES USING GLOBAL AND LOCAL SCOPE DATA #
################################################
exports.makeRules = makeRules = (options, globals, locals, clipboard) ->

  ratio = options.ratio

  # variables
  callables   = globals.callables.concat locals.callables
  writables   = globals.writables.concat locals.writables
  readables   = globals.readables.concat locals.readables

  operators   = ['+','-','*','/']
  other_chars = "abcefghijklmnopqrstuvwxyz0123456789 ".split ''   

  # probabilities
  p =
    multiply   : -> P ratio
    add        : -> P ratio
    opchange   : -> P ratio
    termswitch : -> P ratio
    termdelete : -> P 0.0
    termduplic : -> P 0.0
    termcopy   : -> P 0.0
    termpaste  : -> P 0.5
    strmutate  : -> P ratio

  #####################
  # RULES FOR NUMBERS #
  #####################
  multiply: (t,x) -> if t is 'num' and p.multiply() then [t, Math.random() * x]
  add     : (t,x) -> if t is 'num' and p.add()      then [t, Math.random() + x]

  ########################
  # RULES FOR OPERATIONS #
  ########################
  opchange: (t, o, a, b) ->
    if t is 'binary' and p.opchange()
      ops = copy operators
      idx = ops.indexOf o
      if idx != -1  
        ops.splice idx, 1
      [t, deck.pick(ops), a, b]

  termswitch: (t, o, a, b) ->
    if t is 'binary' and p.termswitch() then [t, o, b, a]

  # delete the node but not children
  termdelete: (t, o, a, b) ->
    if t is 'binary' and p.termdelete()
      if P 0.5 then a else b

  termduplic: (t, o, a, b) ->
    if t is 'binary' and p.termduplic()
      cpy = copy [t, o, a, b]
      if P 0.5 then [t, o, cpy, b] else [t, o, a, cpy]

  termcopy: (t,name,a,b) ->
    if t is 'binary' and p.termcopy()
      node = copy [t,name,a,b]
      clipboard.push node
      node

  termpaste: (t, o, a, b) ->
    if t is 'binary' and clipboard.length > 0
      node = clipboard[0]
      clipboard.shift()
      if p.termpaste()
        r = if P(0.5) then 2 else 3
        node[r] = [t, o, a, b]
      node

  #####################
  # RULES FOR STRINGS #
  #####################
  strmutate: (t, s) ->
    if t is 'string' and p.strmutate()
      chars = s.split ''
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



