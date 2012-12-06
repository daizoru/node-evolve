evolve = require 'evolve'
{C} = require 'cello'

# inspired by http://stackoverflow.com/a/5602143

src = C -> 
  char *count = "\x8b\x5c\x24\x4\x3d\xe8\x3\x0\x0\x7e\x2\x31\xc0\x83\xf8\x64\x7d\x6\x40\x53\xff\xd3\x5b\xc3\xc3"
  typedef f = int ($) (0,0)
  int i = f(count)(count)
