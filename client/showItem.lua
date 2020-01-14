local showItem = {}

local function updateItem(player, insert)
	local containers = player.gameconst.container

	local itemid 	= insert.itemid
	local addCount 	= insert.addCount
	local create 	= insert.create

	if create == 1 then

		local inst = insert.itemInst
		if inst.item then
			print("item id = ", inst.item.id)
			if inst.item.container == containers.item_container then
				player.itemBag:attachItem(inst.item)	
			end	
		end
	else
		
		local item = player:getclientitem(itemid)	
		assert(item ~= nil, "item is nil.")
		item.count = item.count + addCount	
		-- print("物品数量叠加: " .. item.count)
	end
end

function showItem.additem(player, args)
	for _,insert in pairs(args.itemInserts or {}) do
		updateItem(player, insert)
	end		
end

function showItem.removeitem(player, args)
	
	for _,remove in pairs(args.itemRemoves) do

		local itemid = remove.itemid
		local count = remove.count
		local destory = remove.destory
		local item = player:getclientitem(itemid)
		assert(item)		
		if destory == 1 then
			local bag = player:getclientbag(item)
			bag:detachItem(item)
		else
			item.count = item.count - count
		end	
		print("itemid = ", itemid, "count = ",count, "destory = ",destory)
	end	
end	

function showItem.removeinst(player, args)

	local instId = args.instId
	local item  = player:getclientitem(instId)
	assert(item)
	local bag = player:getclientbag(item)
	assert(bag)
	bag:detachItem(item)
	print(string.format("物品[%s]移除成功.",instId))
end	

function showItem.bonusesResult(player, bonusesResult)
	for key, value in pairs(bonusesResult) do
		if key == "inserts" then
			for _, insert in pairs(value) do
				updateItem(player, insert)
			end
		else
			print(key .. ":" .. value)
		end
	end
end

function showItem.drawResult(player, drawResult)
	print("翻牌数据:")
	for index, info in pairs(drawResult) do
		if info.type == gameconst.bonusType.item then
			print(string.format("数据%d: type:%d protoId:%d count:%d", index, info.type, info.protoId, info.count))
		else
			print(string.format("数据%d: type:%d point:%d", index, info.type, info.point))
		end
	end
end

function showItem.openChest(player, args)

	local bonusesResult = args.bonusesResult
	if bonusesResult and bonusesResult.inserts and bonusesResult.inserts[1] then
		for _, insert in pairs(bonusesResult.inserts) do
			updateItem(player, insert)
		end
		print(tool.dump(bonusesResult))
	end

	showItem.removeitem(player, args)
end	

function showItem.useItem(player, args)
	showItem.removeitem(player, args)

	print(tool.dump(args))
end

function showItem.testTakeBonuses(player, args)
	local bonusesResult = args.bonusesResult
	if bonusesResult and bonusesResult.inserts and bonusesResult.inserts[1] then
		for _, insert in pairs(bonusesResult.inserts) do
			updateItem(player, insert)
			
		end
		print(tool.dump(bonusesResult))
	end
end	

function showItem.costResult(player, args)
	for key, value in pairs(args.costResult) do
		if key == "itemRemoves" then
			showItem.removeitem(player, {itemRemoves = value})
		else
			print(key .. ":" .. value)
		end
	end
end

function showItem.sellItem(player, args)

	showItem.removeitem(player, args)
end


return showItem