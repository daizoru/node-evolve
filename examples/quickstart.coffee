#!/usr/bin/env coffee

####################################################
# Welcome to node-evolve!                          #
# please begin a project by requiring the library  #
####################################################
{mutable,mutate} = require 'evolve'

#########################################################################
# We will show in this quickstart how to evolve a simple, wont-do-many- #
# things robot. Feel free to fork and hack it!                          #
# I choose the fancy "robot" word not (just) not to make it cooler,     #
# but also to highlight the fact you could effectively use node-evolve  #
# to grow complex, dynamic programs, that could reproduce and evolve    #
# to become more advanced after many generations.                       #
#########################################################################



###########################################################################
# did you notice this was written in coffee-script? actually, since node- #
# -evolve will work on the final AST tree, you can of course write your   #
# program in JS. To keep the quickstart small and clear, I choose Coffee. #
###########################################################################

#######################################
# So let's start modelling our Robot! #
#######################################
class Robot

  constructor: (@x=0, @y=0, @z=0) ->

  ###########################################################################
  # this is the main loop! it will hold the main algorithm and computations #
  # not eit can receive parameters (a.k.a. context)                         #
  ###########################################################################
  update: (t=0) =>

    ############################################################################
    # let's define some vars we will use for the output (see end of function). #
    ############################################################################
    [a,b,c] = [0,0,0]

    ######################################################################
    # but also local "memory" the algorithm is free to use for mutation. #
    ######################################################################
    [d,e,f] = [0,0,0]

 

    ############################################################
    # now, here where's interesting things happen:             #
    # by defining a "mutable" block, you can actually define   #
    # which part of your code is allowed to mutate actively.   #
    ############################################################

    mutable ->

      ###########################################################################
      # what can you do in a mutable code? well, actually.. it's just code.     #
      # You could call node-java, node-ffi, generate stuff.. Anything you want  #
      # describe with code (eg. templating, code generation, control of a sub-  #
      # -library..) and make evolve! so just don't forget it will mutate badly. #
      # So start with a well-defined algorithm to "bootstrap" the evolutionary  #
      # search, then put everything YOU DON'T WANT TO MUTATE outside the block: #
      # pre-processors, constants, filters, and post-processors.                #
      ###########################################################################

      ############################################################################
      # since this is a quickstart tutorial and not a real program, let's just   #
      # not think too much about what it does and just apply random maths stuff. #
      ############################################################################
      d = x * 1.0
      e = y * 1.0
      f = z * 1.0
      a = d + e
      b = e + f
      c = f + d

    #######################################################################
    # end of the mutable block! we go back to the classic immutable and   #
    # sequential code, and we can do meaningful (?) things with the data. #
    #######################################################################

    ###############################################################################
    # for instance, let's call another function using the output of our algorithm #
    ###############################################################################
    @move a, b, c

  ###########################################
  # immutable function which does something #
  ###########################################
  move: (x=0, y=0, z=0) =>
    @x += x
    @y += y
    @z += z
    console.log "moved to x: #{@x}, y: #{y}, z: #{z}"


main ->
  ##################################################################
  # now we run in-process mutation, by calling the mutate function #
  ##################################################################
  mutate Robot.prototype, 'compute',


    ################################################################################
    # mutation rate used by each rule to decide if we should mutate a node, or not #
    # 1.0 = maximum (systematic) probability of mutation                           #
    # 0.0 = minimum (null)       probability or mutation                           #
    # Needless to say P > 0.30 is already very strong, and that you probably want  #
    # to stick to values around 0.05~0.15                                          #
    ################################################################################

    ratio: 0.10 # mutation ratio

    # optionally, you can print the ASTs in debug mode
    debug: 'debug' in process.argv

    ######################################################
    # Called once the function has been modified inline. #
    ######################################################
    onComplete: ->
      console.log "mutation completed"

      robot = new Robot()

      ##############################################################################
      # Starting from now it will run the loop and call our random, untested code, #
      # so you probably want to run it in a subprocess, or a VM context (sandbox): #
      # see http://nodejs.org/api/vm.html for more details about this.             #
      # Here and for readability's sake we will just wrap it in a try-catch block! #
      ##############################################################################
      for i in [0..10]
        try
          robot.update i
        catch e
          console.log "crashed.. may I say: as expected from a random mutation? #{e}"

main()

