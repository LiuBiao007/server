
package.path = package.path .. ";" .. "../?.lua"

require "class.class"

local a = class("a")

function a:init(...)

	print("a init ", ...)
	
	return self
end	

function a:doa()
	error("a doa")
end	

function a:attach(...)
	self:doa()
	print("a attach ", ...)
end	

function a:create(...)

	self:new():attach(...)
end	


--a:create("hahaha")

local b = class("b", a)
function b:init(...)
	self.__father:init(...)
	print("b init", ...)
end

function b:doa()

	print("b do a.")
end	

local obj = b:new(1, 2, "hahha"):attach("a", "b")	


local c = class("c")
function c:init()	
	print("c============ init")
end

local d = class("d",c)
function d:init()

end

d:new()


