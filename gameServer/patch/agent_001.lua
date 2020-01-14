
if not _P then 
	
	print("hotfix fail, not _P")
	return
end

print("hot fix start")

local function get_up(f)
	
	local u = {}
	if not f then return u end
	
	local i = 1
	
	while true do
		
		local name, value = debug.getupvalue(f, i)
		if not name then return u end
		u[name] = value
		i = i +1
	end
end

--player _P.lua.object.player
local requests = _P.lua.object.requests
--testRequests _P.lua.object.testRequests
local testRequests = _P.lua.object.testRequests
mylog.info(" testRequests = %s addIngot = %s 2 = %s", testRequests, testRequests.addIngot, requests.addIngot)
local ups  = get_up(testRequests.addIngot)
local errorcode = ups.errorcode
requests.addIngot = function(args)

	local ingot = args.ingot
	if type(ingot) ~= "number" then
		return {errorcode = errorcode.param_error}
	end	

	--player:addIngot(ingot)
	--player.ingot = player.ingot + ingot
	print(" i am hot fit start...")
	player.ingot = player.ingot + 99
	print(" i am hot fit end...")
	return {errorcode = 0}
end	




--00000028
--local 00000026

--[[

--热更一个player身上的函数
function player:updateVigor(now)

	local cnf = self.xmls.soulmate.root
	local maxVigor = self.vipMan:getMaxVigor(cnf.maxVigor) 
	--if self.vigor >= maxVigor then return end
	--if true then

	--	local n = math.floor((now - self.vigorTime) / (cnf.vigorCd * 60))
	local n = 1
		self:addVigor(n, true)
	--end	
end	
]]
print('hot fix end')


