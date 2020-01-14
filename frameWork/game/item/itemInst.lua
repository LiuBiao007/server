local fieldObject = require "objects.fieldObject"
local itemInst = class("itemInst", fieldObject)

function itemInst:init()

	self.dbname = "item"
	itemInst.__father.init(self, self.dbname)

	return self
end	

function itemInst:initGameData()

	self.type = gameconst.insttype.iteminst_type
	if not self.proto then
		assert(self.protoId, "item proto id is nil.")
		self.proto = self.man:getProtoById(self.protoId)
	end

	self.man.itemSerializeInsert:attach(self.itemSerializeInsert, self)
end	

function itemInst:itemSerializeInsert(type, count, r)

	if type == self.type then
		r.item = self:serialize(count)
	end	
end	

function itemInst:serialize(count)

	local data = self--self:copyFields()
	data.count = (type(count) == "number" and count or self.count)

	return data
end	

function itemInst:canSell()

	return false
end	
return itemInst

