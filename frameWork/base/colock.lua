local skynet 	= require "skynet"
local mylog		= require "base.mylog"
local table 	= table
local push   	= table.insert
local pop    	= function (arr) return table.remove(arr, 1) end
local coroutine = coroutine

local colock 	= class("colock")

function colock:init()

	self.check = true
	self.locks = {}
	skynet.fork(function ()

		while self.check do
	
			skynet.sleep(300)
			for _, r in pairs(self.locks) do
				if os.getCurTime() - r.now >= 3 then
					mylog.info("[@lock@] service [%08X] serviceName [%s] oprate [%s] may deadlock.",
						skynet.self(), SERVICE_CLASS, r.name)
					r.now = os.getCurTime()
				end	
			end	
		end	
	end)
end	

function colock:lock(name)

	if #self.locks == 0 then
		push(self.locks, {now = os.getCurTime(), name = name})
	else
		
		local co = coroutine.running()
		push(self.locks, {co = co, now = os.getCurTime(), name = name})
		skynet.wait(co)
	end	
end

function colock:unlock()

	pop(self.locks)
	local r = self.locks[1]
	if r and r.co  then
		skynet.wakeup(r.co)
	end	
end

function colock:getCount()
	return #self.locks
end	

function colock:clear()

	while #self.locks > 0 do self:unlock() end
	self.check = nil
	self.locks = {}
end	

return colock	