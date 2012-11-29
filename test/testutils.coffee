# stolen from 
# https://github.com/phstc/levenshtein/blob/master/src/Levenshtein.coffee

Array::minimum = () ->
  # Hmmm... I know, I know... I can do it more dynamic.
  return Math.min(Math.min(this[0], this[1]), this[2])


String::levenshtein = (str1) ->
  distance = new Array()

  for i in [0..this.length]
    distance[i] = new Array()
    distance[i][0] = i

  for j in [0..str1.length]
    distance[0][j] = j

  for i in [1..this.length]
    for j in [1..str1.length]
      subSize = if (this.charAt(i - 1) == str1.charAt(j - 1)) then 0 else 1
      deletion = distance[i - 1][j] + 1
      insertion = distance[i][j - 1] + 1
      substitution = distance[i - 1][j - 1] + subSize
      distance[i][j] = (new Array(deletion, insertion, substitution)).minimum()

  return distance[this.length][str1.length]