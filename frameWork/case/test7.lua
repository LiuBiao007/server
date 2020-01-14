package.path = package.path .. ";" .. "../?.lua"

require "class.class"

print("=====================")
print(...)
local t = {...}
print(#t)
print("=====================")
function deepcompare(t1,t2)
 
  local ty1 = type(t1)
  local ty2 = type(t2)
  if ty1 ~= ty2 then return false end
  if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
 
  for k1,v1 in pairs(t1) do
    local v2 = t2[k1]
    if v2 == nil or not deepcompare(v1,v2) then return false end
  end
  for k2,v2 in pairs(t2) do
    local v1 = t1[k2]
    if v1 == nil or not deepcompare(v1,v2) then return false end
  end
  return true
end

local t1 = {a = 3, b = 4, c = {m = 1, n = 2, z = "ccc"}}
local t2 = {a = 3, b = 41, c = {m = 1, n = 2, z = "ccc"}}
print(deepcompare(t1, t2))

return {
  a = function () print("aaaaaaaaaa") end
}
