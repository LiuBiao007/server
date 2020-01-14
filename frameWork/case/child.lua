package.path = package.path .. ";" .. "../?.lua"

require "class.class"
local father = require "father"

local child = class("child", father)

function child:init(...)

	print("child init", ...)
end	

function child:do_it(...)

	print("child do it ", ...)
end	

function child:do_it2(...)
	print("yer, i am in fsm222-> ", ...)
end	

function child:do_it3(...)
	print("yer, i am in fsm3333-> ", ...)
end	

function child:enter(...)

	print("fsm enter ", ...)
end	

function child:exit(...)

	print("fms exit ", ...)
end	

function child:update(...)

	print("fsm update ", ...)
end	

return child

