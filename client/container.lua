local container = class("container")

function container:init(type)
	self.items = {}
	self.type = type
end	

function container:attachItem(item)
	
	assert(not self.items[item.id], string.format("error id %s.", item.id))
	self.items[item.id] = item
end

function container:detachItem(item)

	assert(self.items[item.id], string.format("error id %s.", item.id))
	self.items[item.id] = nil
end	

function container:getItemById(id)
	return self.items[id]
end	
return container
