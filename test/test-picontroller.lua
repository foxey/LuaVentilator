-- Tests for avg.lua (Mathematical class library)
-- Written by Michiel Fokke <michiel@fokke.org>
-- MIT license, http://opensource.org/licenses/MIT
-- use with 'shake' (http://shake.luaforge.net)

package.path = package.path..';../?.lua'
require 'mcl'

function debugPrint(...) print(...) end

pic = newPicontroller{Kp=1000, Ki=1000}
assert(type(pic) == 'table', "pic should be a table")

assert(pic.Kp(900) == 900, "return should be identical to the input")
assert(pic.Ki(950) == 950, "return should be identical to the input")

pic.Kp(1000)
pic.Ki(1000)
for i=1,100 do
  debugPrint(i, pic.u(40,45))
end

assert(pic.u(40000,45000) == 1023, "pic.u should be 1023")

for i=1,100 do
  debugPrint(i, pic.u(40000,40000))
end

assert(pic.u(40000,45000) == 1023, "pic.u should be 1023")

for i=1,100 do
  debugPrint(i, pic.u(40000,35000))
end

assert(pic.u(40000,45000) == 100, "pic.u should be 100")

-- vim: set si ts=2 sw=2 expandtab:

