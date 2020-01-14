local _actor_set = require "robot.actor_set"
local _actor = require "robot.actor"
local _actor_param = require "robot.actor_param"
-- local myrand = require "base.myrand"
local skynet = require "skynet"
local sharedata = require "sharedata"
local robot_event = require "robot.robot_event"
local mylog = require "base.mylog"
local sends = require "sends"
local handler = {}
function handler:new(param)

	local t = {}	
	setmetatable(t, self)
	self.__index = self
	t:init(param)	

	return t
end

function handler:init(param)

	assert(param.player)
	assert(param.xmls)
	self.player = param.player
	self.xmls = param.xmls
	self.begin = param.xmls.begin
	self.sendId = 0
	self.randtime = 100 * 3
	self.session = 0
	self.sessions = {}
	self.rand = myrand:new()
	self.rxmls = sharedata.query("XMLCONFIG")
	self.actors = self:createActor(self.rand)
end

function handler:createActor(rand)

	local data = self.xmls.actor
	local actors = {}
	for _, item in pairs(data.normal) do
		local actor = _actor:new(item.id, self.player,{cmd = item.cmd, arr = item.arr, 
			errorcode = item.errorcode, rand = rand, rxmls = self.rxmls, robot = self})
		actors[actor.id] = actor
	end	
	for _, item in pairs(data.param) do
		local actor = _actor_param:new(item.id, self.player,{cmd = item.cmd, arr = item.arr, param = item.param,
			errorcode = item.errorcode, rand = rand, rxmls = self.rxmls, robot = self})
		actors[actor.id] = actor
	end	
	for _, item in pairs(data.set) do	
		local actor = _actor_set:new(item.id, self.player,{cmd = item.cmd, arr = item.arr,
			errorcode = item.errorcode,rand = rand, rxmls = self.rxmls, robot = self})
		actors[actor.id] = actor
	end			
	return actors
end	

function handler:robot_begin()

	for _, actorId in pairs(self.xmls.begin) do

		local actor = self.actors[actorId]
		assert(actor, string.format("error actorId %d.", actorId))
		actor:send()
		--self.actor = actor
		self.sendId = actorId
	end	
end	

function handler:beginend()
	return self.sendId == self.xmls.lastBeginId
end

function handler:IsClearBegin()

	return self.sendId == -1
end	

function handler:clearBegin()
	self.sendId = -1
end	

function handler:needStop()

	local randoms = self.xmls.random
	for _,actorId in pairs(randoms) do
		local actor = self.actors[actorId]
		assert(actor, "2 error " .. actorId)
		if not actor:IsOver() then
			return false
		end	
	end	
	return true
end

function handler:startrandom()

	local s = self.rand:rand(self.randtime)
	skynet.sleep(s)
	if self:needStop() then
		print("机器人正常退出.")
		skynet.exit()
	else	
		local randoms = self.xmls.random
		local index = math.myrand(#randoms)
		local actorId = randoms[index]
		assert(actorId, "error " .. actorId)
		local actor = self.actors[actorId]
		assert(actor, "2 error " .. actorId)
		if actor:IsOver() then
			self:startrandom()
		else	
			actor:send()
			--self.actor = actor
		end	
	end	
end	

function handler:doError(session, err)

	if err == 10 then 
		print("服务器停止服务.")
		skynet.exit()
	end	
	--skynet.sleep(100)
	local actor = self.sessions[session]
	if actor then
		if actor.errorcode then
			local actorId = actor.errorcode[err]
			if not actorId then
				--print("actorId = ",actorId,type(actorId),err,actor.id)
				assert(false, string.format("actorId %s type_actorId %s err %s actor.id %s",actorId,type(actorId),err,actor.id))
			end	

			if type(actorId) == "number" then
				if actorId == 0 then
					assert(false, string.format("error %d",err))
				elseif actorId == -1 then
					self:startrandom()
				else	
					local actor = self.actors[actorId]
					assert(actor, "2 error " .. actorId)
					actor:send()
				end	
			else--arr
				for _, id in pairs(actorId) do
					local actor = self.actors[id]
					assert(actor, "2 error " .. id)
					actor:send()				
				end	
			end	
		else
			self:startrandom()	
		end	
	else
		--部分发送操作没有遵循actor规则 没有session对应的actor 在toBeStrong接口中
		self:startrandom()	
	end	
end	

function handler:toBeStrong()

	--skynet.sleep(100)
	--没有卡牌则增加卡牌 然后上阵
	local player = self.player
	if player.battleCount < 6 then
		local heroes = player.herobag:getItems()
		local i = 2
		for _, hero in pairs(heroes) do
			if hero.battleSlot < 0 then 
				sends.herobattle({hero.id, i})
				i = i + 1
				if i >= 6 then break end
			end	
		end	
	end	

	--skynet.sleep(100)
	sends.addexp({1000000})
	local actorCount, actors = 3,{}
	local addTalent = function () 
		for _, hero in pairs(player.battleHeroes) do--增加天命等级
			if hero.proto then
				sends.talenthero({hero.id})
			else
				sends.talent({})
			end	
		end	
	end

	local addBreak = function ()
		for _, hero in pairs(player.battleHeroes) do--增加天命等级
			if hero.proto then
				sends.breakhero({hero.id})
			else
				sends.breakplayer({})
			end	
		end		
	end

	local addHeroExp = function ()

		local canSend = false
		for _, hero in pairs(player.battleHeroes) do--增加天命等级
			if hero.proto then
				sends.addheroexp({hero.id,100000})
				canSend = true
			end	
		end
		if not canSend then addTalent() end
	end

	table.insert(actors, addTalent)
	table.insert(actors, addBreak)
	table.insert(actors, addHeroExp)
	local cmds = math.myrand(actorCount, actors)
	for _,cmd in pairs(cmds) do  cmd() end

	--穿戴装备
	self.actors[1020]:send()

	--强化装备
	self.actors[1021]:send()

	--升星装备
	self.actors[1022]:send()
end

function handler:listenEvent(name, player, args)
	--skynet.sleep(100)
	robot_event.listenEvent(name, player, args)
end	
--[[
function handler:doEvent_Activity(activityState)
	
	robot_event.doEvent_Activity(self.player, activityState)
end	]]
return handler