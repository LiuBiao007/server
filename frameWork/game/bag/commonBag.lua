local bag = require "bag.bag"
local commonBag = class("commonBag", bag)

function commonBag:init(player, param)

	commonBag.__father.init(self, player)
	self.itemsBySlot = {}
	if type(param) == "table" then

		assert(not getmetatable(param), string.format("error param %s.", param.__classname))
		self:setData(param)
	end	
	return self
end	

function commonBag:clearAllEx()
	self.itemsBySlot = {}
end

function commonBag:attachItemEx(item)

	local slot = item.slot
	assert(self.itemsBySlot[slot] == nil, "error item slot " .. slot)
	self.itemsBySlot[slot] = item
end

function commonBag:detachItemEx(item)

	local slot = item.slot
	assert(self.itemsBySlot[slot] ~= nil, "error item slot " .. slot)
	self.itemsBySlot[slot] = nil
end

function commonBag:setOrder()
	assert(nil, "setOrder")
end

function commonBag:neaten()
	assert(nil, "neaten")
end
	
function commonBag:getFirstEmptySlot()
	
	local i = 0
	while true do
		
		if self.itemsBySlot[i] == nil then
			break
		end
		i = i + 1
	end

	if self.maxCount > 0 then
		if i >= self.maxCount then
			return -1
		else	
			return i
		end
	end
	return i
end

function commonBag:generateItemInst(buffer)

	local slot = self:getFirstEmptySlot()
	return self:generateItemInstHasSlot(buffer, slot)
end

function commonBag:generateItemInstHasSlot(buffer,slot)
	
	local proto 	= buffer[1]
	local count 	= buffer[2]
	local binding 	= self.isToBinding(proto, buffer[3])
	local data 		= buffer[4]
	local ownerId 	= self.ownerId
	local owner 	= self.owner
	assert(owner ~= nil, "owner in herobag is nil.")
	local container = self.type
	local inst 		= self.itemMan:generateItemInst(proto, owner, container, count, slot, binding, data)
	return inst 
end

function commonBag:commonBagSub()
	assert(nil, "need implement!") 
end

function commonBag:notifyItemDisappeared(itemInst,decCount,isDestory)

	local player = assert(self.player)
	local type = guidMan.reverseGuidType(itemInst.id)
	self.itemMan:notifyItemDisappeared(itemInst, decCount, isDestory)
	player.logMan:log(LOG_OP_BIGTYPE_ITEMDISAPPEAR,{type,decCount,isDestory},{itemInst.id,itemInst.proto.id})
end

function commonBag:notifyItemAppeared(itemInst,addCount,isCreate)

	local player = assert(self.player)
	local type = guidMan.reverseGuidType(itemInst.id)
	self.itemMan:notifyItemAppeared(itemInst, addCount, isCreate)
	player.logMan:log(LOG_OP_BIGTYPE_ITEMAPPEAR,{type,addCount,isCreate},{itemInst.id,itemInst.proto.id})	
end

return commonBag
