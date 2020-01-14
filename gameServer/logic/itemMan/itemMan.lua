local gameconst 	= gameconst
local xmls			= xmls
local baseItemMan 	= require "item.baseItemMan"
local itemMan 		= class("itemMan", baseItemMan)

function itemMan:getProtoById(protoId)

	if protoId >= 15000001 and protoId <= 15999999 then
		return self:getItemProtoById(protoId)
	else	
		return nil
	end	
end	

function itemMan:getItemProtoById(protoId)
	return xmls.items[protoId]
end

function itemMan:notifyItemAppeared(itemInst, addCount, isCreate)

	local player = assert(self.player)

	mylog.info("notifyItemAppeared playerId %s itemInst:%s protoId:%s addCount:%s isCreate:%s", 
		player.id, itemInst.id, itemInst.proto.id, addCount, isCreate)
end

function itemMan:notifyItemDisappeared(itemInst, decCount, isDestory)

	local player = assert(self.player)

	mylog.info("notifyItemAppeared playerId %s itemInst:%s protoId:%s decCount:%s isDestory:%s", 
		player.id, itemInst.id, itemInst.proto.id, decCount, isDestory)
end

function itemMan:generateItemInstEx(proto,owner,container,count,slot,forceBinding,data)

	local gp = gameconst.container
	error("implete here.")
end

return itemMan