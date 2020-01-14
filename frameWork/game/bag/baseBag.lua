local object  = require "objects.object"
local baseBag = class("baseBag", object)

local push 	  = table.insert
function baseBag:init(player)

	assert(type(player) == "table" and getmetatable(player))
	assert(player.__classname == "player")
	self.player = player
	self.owner  = player
	self.ownerId = player.id
	self.items   = {}
	self.count 	 = 0	
	self.binding = 1
	return self
end	

function baseBag:getCount()

	return self.count
end

function baseBag:attachItem(item)

	local id = item.id
	assert(self.items[id] == nil, id .. " exist");
	self.items[item.id] = item
	self.count = self.count + 1
	self:attachItemEx(item)
	if item.attachItemChanged then
		item.attachItemChanged:notify(item)
	end
end

function baseBag:detachItem(item)

	local id = item.id
	assert(self.items[id], id .. " not exist")

	self.items[id] = nil
	self.count = self.count - 1
	self:detachItemEx(item)
	if item.detachItemChanged then
		item.detachItemChanged:notify(item)
	end	
end

function baseBag:getItemById(id)

	return self.items[id]
end

function baseBag:getItems()

	return self.items
end	

function baseBag:getItemCountByProtoId(protoId, binding,filter)
	
	local count = 0
	local hasBindItem = false
	for _, item in pairs(self.items) do
		
		assert(type(item) == "table")
		assert(type(item.proto) == "table")

		if item.proto.id == protoId and (binding == nil or
			item.binding == binding) then
			if filter == nil or filter(item) then

				assert(type(item.count) == "number", "item.count is not number type.")
				count = count + item.count
				if item.binding == 1 then
					hasBindItem = true
				end		
			end		
		end
	end

	return {count = count, binding = hasBindItem}
end

function baseBag:getItemsByProtoId(protoId)
	
	local t = {}
	for _, item in pairs(self.items) do
		
		if item.proto ~= nil and item.proto.id == protoId then
			push(t, item)
		end		
	end

	return t
end

function baseBag:getItemByProtoId(protoId)
	
	for _, item in pairs(self.items) do
		
		if item.proto ~= nil and item.proto.id == protoId then
			
			--if item.binding == 0 then
				--unbindingItem = item
			--end
			return item
		end
	end

	return nil
end

function baseBag:isSpaceFull(removes, inserts, forcebinding)
	
	if self.maxCount <= 0 then
		return false
	end
	if self.count >= self.maxCount then
		return true
	end
	return false 
end

function baseBag:clearAllMemory()

	self.items = {}
	self.count = 0
	self:clearAllEx()
end

function baseBag:destroyItem(itemInst)
	
	local id = itemInst.id
	assert(self.items[id], id .. "not exist") 
	self:detachItem(itemInst)
	itemInst:delete()
	self:notifyItemDisappeared(itemInst, itemInst.count, 1)
end

function baseBag:setContainerMax(maxCount)
	--assert(maxCount > self.maxCount, string.format("maxCount %s self.maxCount %s", maxCount, self.maxCount))
	self.maxCount = maxCount
end

function baseBag:attachItemEx(item)

	assert(nil, "need implement!")
end

function baseBag:detachItemEx(item)
	assert(nil, "need implement!")
end

function baseBag:clearAllEx()
	assert(nil, "need implement!")
end


return baseBag