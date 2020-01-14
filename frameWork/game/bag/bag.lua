local errorcode = errorcode
local table 	= table
local push  	= table.insert
local pairs		= pairs
local table_remove = table.remove
local pop   	= function (arr) return table_remove(arr, 1) end

local isToBinding = function (proto,forceBinding)

	return 1
end

local filterProtoGet = function (item, forceBinding)
	
	local proto = item[1]
	local count = item[2]
	local binding = item[3] == nil and 1 or isToBinding(proto, forceBinding)
	local data = item[4]
	
	return {proto, count, binding, data}
end

local filterInstGet = function (item,forceBinding)
	
	local proto = item.proto
	local count = item.count
	local binding = item.binding == 1 or isToBinding(proto, forceBinding)
	local data = item.data
	
	return {proto, count, binding, data}
end

local filterProtoNew = function (item,count,binding)

	--可能有改变引用的情况
	local tempBuffer = {}
	for k,v in pairs(item) do

		if k == 2 then
			push(tempBuffer, count)
		elseif k == 3 then	
			push(tempBuffer, binding)
		else	
			push(tempBuffer, v)	
		end
		
	end
	
	return tempBuffer
end

local filterInstNew = function (item,count,binding)

	
	item.count = count
	item.container = self.type
	item.ownerId = self.ownerId
	item.binding = binding
	return item
end

local baseBag = require "bag.baseBag"
local bag = class("bag", baseBag)

function bag:init(player)

	bag.__father.init(self, player)
	self.isToBinding 	= isToBinding
	self.filterProtoGet = filterProtoGet
	self.filterInstGet 	= filterInstGet
	self.filterProtoNew = filterProtoNew
	self.filterInstNew 	= filterInstNew
	return self
end	

function bag:removeItemEx(buffers,items)
	
	local grep = function (buffers,proto,b)

		local t = {}
		for _, v in pairs(buffers) do

			if v.proto.id == proto.id and v.binding == b then
				push(t, v)
			end
		end
		return t
	end

	local ret = {}
	local itemRemovesEx = {}
	local binds = {1,0}
	for _,item in pairs(items) do
		
		local proto = item[1]
		local count = item[2]

		for t, b in pairs(binds) do
			
			if item[3] ~= nil and item[3] ~= b then
				
			else	

				local tempBuffers = grep(buffers, proto, b)
				table.sort(tempBuffers, function (a, b) 
					return a.count < b.count
				end)

				while count > 0 do
					if #tempBuffers <= 0 then
						break
					end	

					local buffer = tempBuffers[1]
					if count >= buffer.count then

						count = count - buffer.count
						pop(tempBuffers)
						local bid = buffer.id
						itemRemovesEx[bid] = {
							itemId = bid, 
							isDestroy = 1
						}
						buffers.bid = nil						
					
					else	
						buffer.count = buffer.count - count
						count = 0
						local bid = buffer.id
						itemRemovesEx[bid] = {
							itemId = bid, 
							count = buffer.count, 
							isDestroy = 0
						}

					end
				end	
			end
		end
	end
	
	for _, v in pairs(itemRemovesEx) do
		push(ret, v)
	end

	return ret
end

function bag:insertItemsEx(buffers,items,forceBinding,getfilter,newFilter)

	local grep = function (buffers,proto,b,maxCount)

		local t = {}
		for _, v in pairs(buffers) do

			if v.proto.id == proto.id and v.binding == b and v.count < maxCount then
				push(t, v)
			end
		end
		return t
	end

	local itemInsertsEx = {}
	local insertsExArr  = {}
	local removesExArr  = {}
	for _, item in pairs(items) do
		
		local tmp = getfilter(item, forceBinding)
		local proto,count,binding,data = tmp[1],tmp[2],tmp[3],tmp[4]
		if count > 0 then
			
			local maxCount = proto.maxCount or 1
			local tmp2 = grep(buffers,proto,binding,maxCount)
			table.sort(tmp2, function (a,b) 
				return a.count < b.count
			end)

			for _,buffer in pairs(tmp2) do
				
				if buffer.count + count <= maxCount then
					buffer.count = buffer.count + count
					count = 0
					local bid = buffer.id
					itemInsertsEx[bid] = {itemId = bid, 
					count = buffer.count, 
					isNew = 0,
					}
					push(removesExArr,item)
					break
				else
					count = count - (maxCount - buffer.count)
					buffer.count = maxCount
					local bid = buffer.id
					itemInsertsEx[bid] = {itemId = bid, 
					count = buffer.count, 
					isNew = 0
					}	
				end	
			end

			while count > 0 do
				local c = count < maxCount and count or maxCount
				local tempItem = newFilter(item, c, binding)
				push(insertsExArr, {item = tempItem, isNew = 1})
				count = count - c
			end		
		end
	end

	for _,v in pairs(itemInsertsEx) do
		push(insertsExArr, v)
	end
	
	return insertsExArr, removesExArr
end

function bag:generateBuffers()

	local hash = {}
	local count = 0
	for _,v in pairs(self.items) do
		
		local id = v.id
		hash[id] = {id = id, proto = v.proto, count = v.count,binding = v.binding,filteritem = v}
		count = count + 1
	end

	return hash,count
end

function bag:getNeedSpace(removes,inserts,forceBinding)

	local newInserts = {}
	local buffers,count = self:generateBuffers()
	
	self:removeItemEx(buffers, removes)
	local insertsExArr = self:insertItemsEx(buffers, inserts, forceBinding, filterProtoGet, filterProtoNew)
	
	for _,v in pairs(insertsExArr) do
		if v.isNew == 1 then
			push(newInserts, v)
		end
	end

	return count + #newInserts
end

function bag:isSpaceFull(removes,inserts,forceBinding)

	if self.maxCount <= 0 then
		return false
	end
	local removes = removes or {}
	if self:getNeedSpace(removes, inserts, forceBinding) > self.maxCount then
		return true
	end
	return false
end

function bag:actInsertItemsByEx(insertsExArr)
	
	local itemInserts = {}

	for _,actMode in pairs(insertsExArr) do
		
		local results,itemInst
		if actMode.isNew == 1 then
			
			itemInst = self:generateItemInst(actMode.item)
			self:attachItem(itemInst)
			results = {itemInst, itemInst.count, 1}
			self:notifyItemAppeared(itemInst, itemInst.count, 1)
		else

			local itemid = actMode.itemId
			itemInst = self.items[itemid]
			local addCount = actMode.count - itemInst.count
			results = {itemInst, addCount, 0}
			
			itemInst.count = actMode.count
			self:notifyItemAppeared(itemInst, addCount, 0)	
		end
		push(itemInserts, results)
	end

	return itemInserts
end

function bag:insertItems(items,forceBinding)

	--是否有特殊插入需求，比如只允许唯一的protoId存在
	if type(self.filterInsertItems) == "function" then

		items = self:filterInsertItems(items, forceBinding)
	end	

	if #items <= 0 then return {} end
	local buffers = self:generateBuffers()
	local insertsExArr = self:insertItemsEx(buffers, items, forceBinding, filterProtoGet, filterProtoNew);
	local results = self:actInsertItemsByEx(insertsExArr)
	return results	
end

function bag:insertItemInsts(items,forceBinding)
	
	local buffers = self:generateBuffers()
	local insertsExArr, removesExArr = self:insertItemsEx(buffers, items, forceBinding, filterInstGet, filterInstNew)
	local results = self:actInsertItemInstsByEx(insertsExArr)
	for _,v in pairs(removesExArr) do
		v:delete()
	end

	return results
end

function bag:generateBuffersEx(filter)

	local hash = {}
	local count = 0
	for _,v in pairs(self.items) do
		if filter(v) then
			local id = v.id
			hash[id] = {id = id, proto = v.proto, count = v.count,binding = v.binding}
			count = count + 1
		end
	end

	return hash,count
end

function bag:removeItems(items,filter)
	assert(type(filter) == "function")
	local buffers = self:generateBuffersEx(filter)
	local itemRemovesEx = self:removeItemEx(buffers, items)
	local results = self:actRemoveItemsByEx(itemRemovesEx)
	return results
end

function bag:actRemoveItemsByEx(itemRemovesEx)

	local itemRemoves = {}
	for _, actMode in pairs(itemRemovesEx) do
		
		local results
		local itemid = actMode.itemId
		local itemInst = self.items[itemid]
		if actMode.isDestroy == 1 then
		
			results = {itemInst, itemInst.count, 1}
			self:destroyItem(itemInst)
		else
			local decCount = itemInst.count - actMode.count
			results = {itemInst, decCount, 0}
			
			itemInst.count = actMode.count
			self:notifyItemDisappeared(itemInst, decCount, 0)
		end
		push(itemRemoves, results)
	end
	
	return itemRemoves
end

function bag:actInsertItemInstsByEx(insertsExArr)
	
	local itemInserts = {}
	for _, actMode in pairs(insertsExArr) do

		local results, itemInst
		if actMode.isNew == 1 then

			itemInst = actMode.item
			self:attachItem(itemInst)
			results = {itemInst, itemInst.count, 1}
			self:notifyItemAppeared(itemInst, itemInst.count, 1) 
		else

			local itemid = actMode.itemId
			itemInst = self.items[itemid]
			local addCount = actMode.count - itemInst.count
			results = {itemInst, addCount, 0}
			
			itemInst.count = actMode.count
			self:notifyItemAppeared(itemInst, addCount, 0)
		end	
		push(itemInserts, results)			
	end

	return itemInserts
end

function bag:checkCanSplitItem(item,splitCount,data)
	
	local itemid = item.id
	if self.items[itemid] == nil then
		return errorcode.item_not_exist
	end	

	if splitCount < 1 then
		return errorcode.item_split_num_err 
	end
	
	if self.count + 1 > self.maxCount then
		return errorcode.space_no_enough 
	end

	if item.count < splitCount + 1 then
		return errorcode.item_split_num_no_enough 
	end

	return 0
end

function bag:splitItem(item,splitCount,data)
	
	item.count = item.count - splitCount
	local removes = {{item, splitCount, 0}}
	
	local buffer = {item.proto, splitCount, item.binding or 0, data}
	local newItem = self:generateItemInst(buffer)
	self:attachItem(newItem)
	local inserts = {{newItem, newItem.count, 1}}
	return removes, inserts
end

function bag:generateItemInst(buffer)
	assert(nil, "need implement!")
end

function bag:notifyItemDisappeared(itemInst, decCount, isDestory)
	assert(nil, "need implement!")
end

function bag:notifyItemAppeared(itemInst, addCount, isCreate)
	assert(nil, "need implement!")
end

return bag
