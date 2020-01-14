local push 	  = table.insert
local guidMan = guidMan
local xmls    = xmls
local mylog   = mylog
local gameconst = gameconst
local errorcode = errorcode
local subject   = require "base.subject"
local itemInst  = require "item.itemInst"

local itemMan = class("baseItemMan")

function itemMan:init(player)

	 player.loadGameDataSuccess:attach(self.onDataLoaded, self)
	 player.onSendPlayerData:attach(self.sendEnterData, self)
	 self.player = assert(player)
	 --序列化itemInsert下发数据
	 self.itemSerializeInsert = subject:new()

	 return self
end	

function itemMan:onDataLoaded(data)

	local player = assert(self.player)
	for _, item in pairs(data.item or {}) do

		item.man   = self
		item.proto = self:getProtoById(item.protoId)
		local inst = itemInst:load(item)
		assert(inst.container == player.itemBag.type, string.format("container %s type %s.",
			inst.container, player.itemBag.type))
		player.itemBag:attachItem(inst)
	end	
end	

function itemMan:sendEnterData(player, result)
	
	local data = {}	
	for _, item in pairs(player.itemBag:getItems()) do
		data[item.id] = item:serialize()
	end	
	result.items = data
end

function itemMan:getProtoById(protoId)

	error("implement in child.")
end	

function itemMan:generateItemInst(proto,owner,container,count,slot,forceBinding,data)

	local gp = gameconst.container
	if proto.type == gp.item_container  then
		
		return self:createItemInst(proto, owner, container, count,slot, forceBinding,data)
	else
		return self:generateItemInstEx(proto,owner,container,count,slot,forceBinding,data)
	end		
end	

function itemMan:createItemInst(proto, owner, container, count,slot, forceBinding,data)

	local item = {}
	item.id 		= guidMan.createGuid(gameconst.serialtype.item_guid)
	item.protoId 	= proto.id
	item.binding 	= forceBinding or 1
	item.ownerId 	= owner.id
	item.owner 		= owner
	item.count 		= count
	item.container 	= container
	item.slot 		= slot
	item.data		= ""
	item.proto      = proto
	item.man 		= self

	local inst = itemInst:create(item)

	return inst
end	

function itemMan:serializeRemove()

	local removes = {}
	for _,remove in pairs(itemRemoves) do

		local item,count,destory = remove[1],remove[2],remove[3]
		local r 	= {}
		r.itemid 	= item.id
		r.count 	= count
		r.destory 	= destory
		push(removes, r)
	end	
	return removes
end	

function itemMan:serializeInsert(itemInserts)

	local tps = gameconst.insttype
	local results = {}
	for _,insert in pairs(itemInserts) do

		local result = {}
		local item,count,create = insert[1],insert[2],insert[3]
		result.itemid 	= item.id
		result.addCount = count
		result.create 	= create
		if create == 1 then

			result.itemInst = {}
			assert(item.type ~= nil, "item.type is nil.")
			result.itemInst.type = item.type
			self.itemSerializeInsert:notify(item.type, count, result.itemInst)
		end	
		push(results, result)
	end	

	return results
end	

function itemMan:decItemCount(player, item, decCount)
	
	if decCount > item.count then
		decCount = item.count
		mylog.warn("error item %s protoId %s decCount %s count %s", item.id, item.proto.id,decCount,item.count)
	end	
	if decCount < item.count then

		item.count = item.count - decCount
		local bag = player:getBagContainerByProto(item.proto)
		bag:notifyItemDisappeared(item, decCount, 0)

		return 0
	else
		player:destroyInst(item)
		return 1
	end	
end

--------------------------- 奖励结构 ---------------------------------

function itemMan:decodeBonusesEx(data)
	local bonusType = self.gameconst.bonusType

	local bonuses = {allRate = 0, type = 2, count = 1}
	for _, info in pairs(data) do
		local bonus
		if info.type == bonusType.item then
			local proto = self:getProtoById(info.protoId)
			if proto then
				bonus = {
					type 		= info.type,
					proto 		= proto,
					protoId		= info.protoId,
					count 		= info.count,
					rate 		= 10000,
					maxCount 	= 0,
				}
			else
				mylog.warn("impossible")
			end
		else
			bonus = {
				type 		= info.type,
				point 		= info.count,
				rate 		= 10000,
				maxCount 	= 0,
			}
		end

		if bonus then
			push(bonuses, bonus)
		end
	end

	return bonuses
end

function itemMan:decodeBonuses(data)
	local bonuses = self:decodeBonusesBegin(data)
	self:decodeBonusesEnd(bonuses)

	if #bonuses > 0 then
		return bonuses
	end
	return nil
end

function itemMan:decodeBonusesEnd(bonuses)
	local bonusType = gameconst.bonusType

	for _, bonus in ipairs(bonuses) do
		if bonus.type == bonusType.item then
			local proto = self:getProtoById(bonus.protoId)
			if proto then
				bonus.proto = proto
			else
				mylog.warn("impossible protoId:%s", bonus.protoId)
			end
		end
	end
end

function itemMan:decodeBonusesBegin(data)
	local bonusType = gameconst.bonusType

	local bonuses = {}
	local tonumber = math.tonumber
	local data1 = data:split(":")
	if #data1 ~= 3 then
		mylog.warn("impossible [%s]", data)
	else
		bonuses.allRate = 0
		bonuses.type =  tonumber(data1[1])
		bonuses.count = tonumber(data1[2])

		-- 累计随机(1)
		-- 独立随机(2)
		local items = data1[3]:split(";")
		for _, item in ipairs(items) do

			local info = item:split(",")
			local type1 = tonumber(info[1])
			if type1 < bonusType.min or type1 > bonusType.max then
				mylog.warn("impossible [%s]", data)
			else
				local bonus
				if type1 == bonusType.item then
					if #info ~= 5 then
						mylog.warn("impossible [%s]", data)
					else
						bonus = {
							type 		= type1,
							protoId		= tonumber(info[2]),
							count 		= tonumber(info[3]),
							rate 		= tonumber(info[4]),
							maxCount 	= tonumber(info[5]) or 0,
						}
					end
				else
					if #info < 4 then
						mylog.warn("impossible [%s]", data)
					else
						bonus = {
							type 		= type1,
							point 		= tonumber(info[2]),
							rate 		= tonumber(info[3]),
							maxCount 	= tonumber(info[4]) or 0,
						}
					end
				end

				if bonus then
					push(bonuses, bonus)
					bonuses.allRate = bonuses.allRate + bonus.rate
				end
			end
		end
	end

	return bonuses
end

function itemMan:checkTakeBonuses(bonuses)
	local dropType = gameconst.dropType
	local bonusType = gameconst.bonusType
	
	local addWingProtoIds = {}
	local addFashionProtoIds = {}
	local needBagCountByContainerType = {}
	for i = 1, bonuses.count do
		for _, bonus in ipairs(bonuses) do

			if bonus.type == bonusType.item then
				if not bonus.proto then return errorcode.bonus_proto_not_exist end

				local protoId = bonus.protoId
				local protoType = bonus.proto.type
				local needBagCount = needBagCountByContainerType[protoType] or 0
				local count = bonus.count > bonus.maxCount and bonus.count or bonus.maxCount
				count = math.ceil(count / bonus.proto.maxCount)
				if bonuses.type == dropType.totalRate then
					if needBagCount < count then
						needBagCountByContainerType[protoType] = count
					end
				else
					needBagCountByContainerType[protoType] = needBagCount + count
				end
			end
		end
	end


	local containerTypes = gameconst.container
	for containerType, count in pairs(needBagCountByContainerType) do
		local bag = player:getContainerByType(containerType)
		if bag then
			local space = bag.maxCount - bag.count
			if count > space then
				local aa = errorcode[gameconst.containerErr[bag.type]] or errorcode.space_no_enough
				return aa
			end
		end
	end

	return 0
end

function itemMan:takeBonuses(bonuses)
	local results, temp = self:getRandBonuses(bonuses)
	return self:processBonusesResults(results)
end

function itemMan:processBonusesResults(results)

	local player = assert(self.player)
	local bonusesResult = {
		inserts 		= {},
	}
	local bonusType = gameconst.bonusType
	local type1 = bonus.type
	for _, bonus in ipairs(results) do

		if type1 == bonusType.item then 			-- 物品
			push(bonusesResult.inserts, {bonus.proto, bonus.count})
		else	
			player:attachBonuses(bonus, bonusesResult)
		end	
	end

	bonusesResult.inserts = player:insertItems(bonusesResult.inserts)

	return bonusesResult
end

function itemMan:getRandBonuses(bonuses)
	local dropType = gameconst.dropType
	local bonusType = gameconst.bonusType

	-- 轮回次数
	local allBonuses = {}
	local count = bonuses.count

	local function randomNewCount(bonus)
		if bonus.maxCount > 0 then
			if bonus.type == bonusType.item then
				if bonus.maxCount > bonus.count then
					bonus.count =  math.myrand(bonus.count, bonus.maxCount)
				end
			else
				if bonus.maxCount > bonus.point then
					bonus.point =  math.myrand(bonus.point, bonus.maxCount)
				end
			end
		end
	end

	for i = 1, count do
		-- 累计随机(一轮固定掉落一次)
		if bonuses.type == dropType.totalRate then
			local rate = math.myrand(1, bonuses.allRate)

			for _, bonus in ipairs(bonuses) do
				if rate <= bonus.rate then
					randomNewCount(bonus)
					push(allBonuses, bonus)
					break
				else
					rate = rate - bonus.rate
				end
			end
		-- 独立计算随机(一轮掉落次数不固定)
		else
			for _, bonus in ipairs(bonuses) do
				local rate = math.myrand(1, 10000)
				if rate <= bonus.rate then
					randomNewCount(bonus)
					push(allBonuses, bonus)
				end
			end
		end
	end

	return self:mergeBonuses(allBonuses)
end

function itemMan:mergeBonuses(bonuses)
	local arr = {}
	local hash = {}
	local items = {}
	
	local bonusType = self.gameconst.bonusType

	for _, bonus in ipairs(bonuses) do
		if bonus.type == bonusType.item then
			local protoId = bonus.proto.id
			if items[protoId] then
				items[protoId].count = items[protoId].count + bonus.count
			else
				items[protoId] = bonus
			end
		else
			if hash[bonus.type] then
				hash[bonus.type].point = hash[bonus.type].point + bonus.point
			else
				hash[bonus.type] = bonus
			end
		end
	end

	local results = {}
	local itemInserts = {}
	for _, bonus in pairs(items) do
		push(results, bonus)
		push(itemInserts, bonus)
	end

	for _, bonus in pairs(hash) do
		push(results, bonus)
	end

	return results, itemInserts
end

function itemMan:joinBonusesResults(bonusesResults)
	local bonusesResult = {inserts = {}}

	local inserts = {}
	local typeName = {"item"}
	for _, result in ipairs(bonusesResults) do
		if result then
			for k, v in pairs(result or {}) do
				if k == "inserts" then
					for _, info in ipairs(v) do
						-- 目前只有物品有叠加数
						local itemId = info.itemid
						local re = inserts[itemId]
						if re then
							re.addCount = re.addCount + info.addCount
							if re.create == 1 or info.create == 1 then
								re.create = 1
								for _, n in ipairs(typeName) do
									if re.itemInst[n] then
										re.itemInst[n].count = re.itemInst[n].count + info.addCount
									end
								end
							end
						else
							inserts[itemId] = info
						end
					end
				else
					if bonusesResult[k] then
						bonusesResult[k] = bonusesResult[k] + v
					else
						bonusesResult[k] = v
					end
				end
			end
		end
	end

	for _, insert in pairs(inserts) do
		push(bonusesResult.inserts, insert)
	end

	return bonusesResult
end

function itemMan:changeBonusesCount(bonuses, count)
	if type(count) ~= "number" or count <= 0 then
		mylog.warn("changeBonusesCount count:%s error!", count or -1)
		return bonuses
	end

	for _, bonus in ipairs(bonuses) do
		if bonus.type == self.gameconst.bonusType.item then
			bonus.count = bonus.count * count
		else
			bonus.point = bonus.point * count
		end
		bonus.maxCount = bonus.maxCount * count
	end
	
	return bonuses
end

function itemMan:takeDrawBonuses(bonuses)
	local results = self:getThreeRandBonuses(bonuses)
	local bonusesResult = self:processBonusesResults({results[1]})

	return bonusesResult, results
end

function itemMan:getThreeRandBonuses(bonuses)
	local dropType = gameconst.dropType
	local bonusType = gameconst.bonusType

	-- 轮回次数
	local allBonuses = {}
	for i = 1, 3 do
		local rate = math.myrand(1, bonuses.allRate)

		for _, bonus in ipairs(bonuses) do
			if rate < bonus.rate then
				if bonus.maxCount > 0 then
					if bonus.type == bonusType.item then
						if bonus.maxCount > bonus.count then
							bonus.count = math.myrand(bonus.count, bonus.maxCount)
						end
					else
						if bonus.maxCount > bonus.point then
							bonus.point = math.myrand(bonus.point, bonus.maxCount)
						end
					end
				end

				push(allBonuses, bonus)
				break
			else
				rate = rate - bonus.rate
			end
		end
	end

	return allBonuses
end

--------------------------- 消耗结构 ---------------------------------
function itemMan:decodeCosts(str, number)
	number = number or 1
	local costType = gameconst.costType

	local items = {}
	local values = {}
	local data1 = str:split(";")
	if #data1 <= 0 then
		mylog.warn("impossible [%s]", str)
	else
		for _, str2 in ipairs(data1) do
			local info = str2:split(",")
			local type1 = tonumber(info[1])
			if type1 < costType.min or type1 > costType.max then
				mylog.warn("impossible [%s]", str)
			else
				if type1 == costType.item then
					if #info ~= 3 then
						mylog.warn("impossible [%s] error!", data1)
					else
						local count = tonumber(info[3]) * number
						local protoId = tonumber(info[2])
						local proto = self:getProtoById(protoId)
						if proto == nil then
							mylog.warn("impossible [%s] protoId error!", data1)
						else
							if items[protoId] then
								items[protoId] = items[protoId] + count
							else
								items[protoId] = count
							end
						end
					end
				else
					if #info ~= 2 then
						mylog.warn("impossible [%s] error!", data1)
					else
						local count = tonumber(info[2]) * number

						if values[type1] then
							values[type1] = values[type1] + count
						else
							values[type1] = count
						end
					end
				end
			end
		end
	end

	local mergeCosts = {}
	for protoId, count in pairs(items) do
		local proto = self:getProtoById(protoId)
		push(mergeCosts, {
			type 	= costType.item,
			protoId = protoId,
			proto 	= proto,
			count 	= count,
		})
	end

	for type1, count in pairs(values) do
		push(mergeCosts, {
			type 	= type1,
			count 	= count,
		})
	end

	return mergeCosts
end

function itemMan:mergeCosts(data)
	local items = {}
	local values = {}
	local costType = self.gameconst.costType
	
	for _, arr in ipairs(data) do
		for _, cost in ipairs(arr) do
			local type1 = tonumber(cost.type)
			local point = tonumber(cost.count)

			if type1 == costType.item then
				local protoId = tonumber(cost.protoId)
				if items[protoId] then
					items[protoId] = items[protoId] + point
				else
					items[protoId] =  point
				end
			else
				if values[type1] then
					values[type1] = values[type1] + point
				else
					values[type1] =  point
				end
			end
		end
	end

	local mergeCosts = {}
	for protoId, count in pairs(items) do
		local proto = self:getProtoById(protoId)
		push(mergeCosts, {
			type 	= costType.item,
			protoId = protoId,
			proto 	= proto,
			count 	= count,
		})
	end

	for type1, count in pairs(values) do
		push(mergeCosts, {
			type 	= type1,
			count 	= count,
		})
	end

	return mergeCosts
end

function itemMan:checkCosts(data)

	local player = assert(self.player)
	local errorcode = errorcode
	local costType  = gameconst.costType

	local items = {}
	local values = {}
	for _, cost in ipairs(data) do
		local type1 = tonumber(cost.type)
		local point = tonumber(cost.count)

		if type1 == costType.item then
			local protoId = tonumber(cost.protoId)
			if items[protoId] then
				items[protoId] = items[protoId] + point
			else
				items[protoId] =  point
			end
		else
			if values[type1] then
				values[type1] = values[type1] + point
			else
				values[type1] =  point
			end
		end
	end

	for protoId, count in pairs(items) do
		local proto = self:getProtoById(protoId)
		local result = player:getItemCountByProto(proto)

		if result.count < count then
			return errorcode.item_num_no_enough
		end
	end

	for type1, point in pairs(values) do

		local err = player:checkCostsEx(type1, costType, point)
		if err > 0 then return err end
	end

	return 0
end

function itemMan:costs(costs)

	local player = assert(self.player)
	local costType = gameconst.costType

	local removes = {}
	local costResult = {itemRemoves = {}}
	for _, bonus in ipairs(costs or {}) do
		local type1 = tonumber(bonus.type)
		local point = tonumber(bonus.count)
		if type1 == costType.item then 				-- 物品
			push(removes, {bonus.proto, point})
		else						
			player:costsEx(type1, costType, costResult, point)
		end
	end

	costResult.itemRemoves = player:removeItems(removes)

	return costResult
end

function itemMan:update(now, isSend)
	
	local player = assert(self.player)
	local items = player.itembag:getItems()

	local removes = {}
	for _, item in pairs(items) do
		if type(item.proto.expires) == "number" and item.proto.expires > 0 and item.proto.expires <= now then
			push(removes, {item.proto, item.count})
		end
	end

	if #removes > 0 then
		local itemRemoves = player:removeItems(removes)
		if isSend then
			self.player:sendEvent("itemRemoves", {itemRemoves = itemRemoves})
		end
	end
end

return itemMan