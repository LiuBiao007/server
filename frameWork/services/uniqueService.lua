local skynet = require "skynet"
local assert = assert
local type   = type
local string = string

return function (module, ...)

	assert(type(module) == "string", string.format("uniqueservice module %s not found.", module))
	local u = skynet.localname(".uniqueservice")	
	if not u then
		u = skynet.newservice("serviced")
	end	
	assert(u, ".uniqueservice must be start first.")
	return skynet.call(u, "lua", module, ...)
end
