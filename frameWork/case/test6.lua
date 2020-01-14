package.path = package.path .. ";" .. "../?.lua"

require "class.class"
require "ext.string"
local a = class("a")

function a:create(data)
	return a:new():attach(data)
end	

function a:attach(data)

	self.rawdata = {}
	local myindex = {}
	local old_meta = getmetatable(self)
	local newfunction = function (self, k)

		local myindex = old_meta.__index
		if myindex[k] then return myindex[k] end

		local v = self.rawdata[k]
		print("get-------> ", k, v, string.dump(v))
		return v
		--return rawget(self.rawdata, k) --self.rawdata[k]
	end	

	local meta = {
		__index = newfunction,
		__newindex = function (self, k, v)

			print("set----> ", k, string.dump(v))
			self.rawdata[k] = v
		end
	}

	setmetatable(self, meta)

	for k, v in pairs(data) do
		self[k] = v
	end	

	return self
end	


local b = class("b", a)

local o = b:create({m = 1, n = 2, c = { d = 1, k = {jj = 100}}})

--print("1m = ", o.m)
--o.m = o.m + 1	
--print("test---------> m = 2")
--print("2m = ", o.m)

--print("0.c = ", o.c)

--o.c = {d = 1, {k = {jj = 111}}}

print("1====================", o.c)

local k = o.c.k
--print("c === ", string.dump(o.c))
--print("k === ", string.dump(o.c.k))
----

print("2====================")
print("k = ", string.dump(k))
k.jj = k.jj + 100
--print("jj = ", string.dump(o.c))

--o.c = o.c

