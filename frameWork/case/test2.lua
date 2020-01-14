package.path = package.path .. ";" .. "../?.lua"

require "class.class"

local a = class("a")

function a:get1()
	print("I am a")
	return "a"
end

local b = class("b", a)
function b:get1()
	print("I am b")
	self.__father:get1()
	return "b"
end 

local c = class("c", b)
function c:get1()
--[[
	local meta = getmetatable(self)
	print("meta = ", meta)
	print("b ========= ", self.__father:get1())
	print("a========== ", self.__father.__father:get1())]]
	
	print("I am c")
	self.__father:get1()
	return "c"
end


local o = c:new()

print("o ===== ", o:get1())

local t = {a = 123}
function t:add()
	print("i am add t.")
end


local s = {}
s[t] = 100
for k, v in pairs(s) do
k:add()
	print(k, v)
	
end

print("=============test trigger===============")
local trigger = require "base.trigger"

local a = class("o1")

function a:init()
	trigger.add("come", self, self.doit)
end

function a:doit(...)
	
	print("i am do a ... ", ...)
end

local b = class("b1")

function b:init()
	trigger.add("come", self, self.doit)
end

function b:doit(...)
	
	print("i am do b ... ", ...)
end

local all = class("all")

function all:init()
	
end

function all:come()
	trigger.notify("come", 1, 2, 3)
end


local t1 = all:new()
local a1 = a:new()
local b1 = b:new()
local a2 = a:new()

t1:come()

local m = {__newindex = function (self, k, v)
	error(string.format("self %s k %s connot modify", self, k))
end,
	__index = function (self, k) 
		print("index k = ", k)
	end
}
local z = {a = 100}

print("z.a = ", z.a)
z = setmetatable(z, m)


z.a = 105
z.c =101

print("z.a = ", z.a)











