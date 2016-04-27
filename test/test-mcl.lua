-- Tests for avg.lua (Mathematical class library)
-- Written by Michiel Fokke <michiel@fokke.org>
-- MIT license, http://opensource.org/licenses/MIT
-- use with 'shake' (http://shake.luaforge.net)

package.path = package.path..';../?.lua'
require 'mcl'

a = newRingbuffer()
assert (type(a) == 'table', "a should be a table")
assert (a.avg() ~= a.avg(), "avg should be -nan")
assert (a.push(1) == 1, "return should be equal to input parameter")
assert (a.avg() == 1, "avg should be 1")
assert (a.push(1) == 1, "return should be equal to input parameter")
assert (a.push(4) == 4, "return should be equal to input parameter")
assert (a.sum() == 6, "sum should be 6")
assert (a.avg() == 2, "avg should be 2")
assert (a.push(4) == 4, "return should be equal to input parameter")
assert (a.avg() == 3, "avg should be 3")

a2 = newRingbuffer()
assert (a2.push(2) == 2, "return should be equal to input parameter")
assert (a2.avg() == 2, "avg should be 2")
assert (a2.push(2) == 2, "return should be equal to input parameter")
assert (a2.push(5) == 5, "return should be equal to input parameter")
assert (a2.sum() == 9, "sum should be 3")
assert (a2.avg() == 3, "avg should be 9")

b = newRunningAverage()
assert (type(b) == 'table', "b should be a table")
assert (b.avg() ~= b.avg(), "avg should be -nan")
assert (b.push(2) == 1, "n should be 1")
assert (b.push(1) == 2, "n should be 2")
assert (b.avg() == 1.5, "avg should be 1.5")
assert (b.push(3) == 3, "n should be 3")
assert (b.avg() == 2, "avg should be 2")
assert (b.reset() == 0, "return should be 0")
assert (b.avg() ~= b.avg(), "avg should be -nan")
assert (b.push(2) == 1, "n should be 1")
assert (b.push(1) == 2, "n should be 2")
assert (b.avg() == 1.5, "avg should be 1.5")
assert (b.push(3) == 3, "n should be 3")
assert (b.avg() == 2, "avg should be 2")

size = 5
maxElements = 100
c = newRunningAverageList{size=size, maxElements=maxElements}
assert (c.avg() ~= c.avg(), "current average should be -nan")

sum = 0

assert (type(c) == 'table', "c should be a table")
for i=1,size*2 do
  sum = sum + 3
  for j=1,maxElements,1 do
    c.push(3)
  end
end

assert (c.index() == 0, "index should be 0 again")
assert (c.avg() == sum/(2*size), "current average is wrong")

for i=1,size do
  assert (c.avg(i) == sum/(2*size), "average is wrong")
end

result = { 3.6, 4.2, 4.8, 5.4, 6 }
for i=1,size do
  for j=1,maxElements do
    c.push(6)
  end
  print(string.format("avg==result[%d]", i))
  assert (c.avg() == result[i], "average is wrong")
end

-- vim: set si ts=2 sw=2 expandtab:
