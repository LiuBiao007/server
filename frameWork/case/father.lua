require "class.class"

local father = class("father")

function father:init(...)

	print("father init ", ...)
end	

function father:do_it(...)
	print("father do it ", ...)
end	

function father:check(...)
	print("father check  ", ...)
end	

return father


