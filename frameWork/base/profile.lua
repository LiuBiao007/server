local skynet  = require "skynet"
local profile = require "skynet.profile"
local mylog	  = require "base.mylog"
local ctime    = require "time"


local push    = table.insert
local start
local needProfile = true--cnf.profile
local ti = {}
local handler = {}
function handler.start(name)

	if needProfile then
		profile.start()
		local p = ti[name]
		if not p then
			p = {n = 0, time = 0, total = 0, diff = 0}
			ti[name] = p
		end	
		assert(not start)
		start = ctime.gettime()
	end	
end	

function handler.stop(name)

	if needProfile then

		local time = profile.stop()
		local p = ti[name]
		assert(p)
		p.n    = p.n + 1
		p.time = p.time + time--second
		assert(start)
		local diff = (ctime.gettime() - start) / 10000
		start = nil
		p.total = p.total + diff--0.01second
		p.diff = p.diff + diff - time
	end	
end	

local function accurate4digits(n)

	n = tostring(n)
	if n:match("%.") then

	else
		
		n = n .. ".0000"
	end	

	return tonumber(n)
end	

function handler.dump(log)

	local info = {}
	for name, t in pairs(ti or {}) do

		local str = string.format("protocol:%s rawtime(no co):%s totaltime:%s cotime:%s",
			name, t.time / t.n, t.total / t.n, t.diff / t.n)
		push(info, str)
		if log then mylog.info(str) end
	end 	
	return info
end	

function handler.setMode(mode)

	assert(mode == "boolean")
	needProfile = mode
end	

function handler.showProfile()
	skynet.info_func(function ()
		return handler.dump()
	end)
end	

return handler