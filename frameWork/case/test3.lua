package.path = package.path .. ";" .. "../?.lua"

require "class.class"

local base = class("base")
function base:setData(data)
	print("base setData")
	for k, v in pairs(data) do
		self[k] = v
	end	
end	

local a = class("a", base)

function a:init(name)

	print("name = ", name, " db init.")
end

function a:attach(data)

	print("a -------- attach")
	for k, _ in pairs(data) do
		assert(not rawget(self, k), string.format("class [%s] key [%s] must be in metatable.", self.__classname, k))
	end	

	local meta = getmetatable(self)
	meta.__newindex = function (self, k, v)

		meta.__index[k] = v
	end

	self:setData(data)
	return self
end	

local b = class("b", a)
function b:init(...)

	self.z = 1
	--self.a = 99
	self.__father:init(...)
end

local obj = b:new("player"):attach({a = 100, b = "abc", d = {j = 1, mm = "hahah"}})


print("b.a = ", obj.a)
print("raw b.a = ", rawget(obj, a))

obj.a = 999
obj.a = 1000
obj.c = "aaaaaaaa"
obj.z = 9
obj.b = 9


local t = {}
function t.test()

	print("t is test")
end	

local zz = {}

for k, v in pairs(t) do

	zz[k] = v
end	

zz.test()
