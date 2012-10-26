// define vars - only values will mutate
var a = 0, b = 0, c = 0, d = 0;

// create a static function
function foo(x,y,z) {
  a = x * 1;
  b = y * 1;
  c = z * 1;
  return 0;
};

// a statement
d = foo(12,12,"hi");

// a second statement
console.log(d);