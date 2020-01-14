local mylog 	= mylog
local push		= table.insert
local guidMan	= guidMan
local commonBag = require "bag.commonBag"
local uniqueBag = class("uniqueBag", commonBag)

function uniqueBag:init(...)

	uniqueBag.__father.init(self, ...)
	self.itemByProtoId = {}
	assert(self.itemMan)
	return self
end

function uniqueBag:getItemByProtoId(protoId)

	return self.itemByProtoId[protoId]
end	

function uniqueBag:filterInsertItems(items, forceBinding)

	local r = {}
	for _, item in pairs(items) do
		if not self:getItemByProtoId(item[1].id) then
			push(r, {item[1], 1})
		end	
	end	
	return r
end

function uniqueBag:attachItemEx(item)

	uniqueBag.__father.attachItemEx(self, item)
	local protoId = item.proto.id
	assert(not self.itemByProtoId[protoId], string.format("protodId %s repeat", protoId))
	self.itemByProtoId[protoId] = item
end

function uniqueBag:detachItemEx(item)

	uniqueBag.__father.detachItemEx(self, item)
	local protoId = item.proto.id
	assert(self.itemByProtoId[protoId], string.format("error protoId %s", protoId))
	self.itemByProtoId[protoId] = nil
end

function uniqueBag:clearAllEx()

	uniqueBag.__father.clearAllEx(self)
	self.itemByProtoId = {}
end	


return uniqueBag