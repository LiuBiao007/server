local child = require "child"

local c1 = child:new("hello")
local c2 = child:new("world")
local c3 = child:new("hhhhhh")

-----------------test class------------------
local function test_class()
	c1:do_it()
	c2:do_it("i am c2")
	c3:do_it("hehe c3")

	c1:check("c1 checking...")

	assert(c1 ~= c2)
	assert(c2 ~= c3)
	assert(c1.class)
	assert(c1.__classname == "child")
end	
--test_class()

---------------------test component-------------------------
--[[
print("start test component")
local function test_com()
	require "class.class"

	local event = class("event")


	local component = require "component"
	component.addComponent(c1, )
end	


print("end test component")
]]
function import(name, cur)

	print(debug.getlocal(3, 1))
end	

import("name")

import("name", "dir")

