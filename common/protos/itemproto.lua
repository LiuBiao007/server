local types = [[
.item {
	id 1 : string
	protoId 2 : integer
	ownerId 3 : string
	container 4 : integer
	slot 5 : integer
	binding 6 : integer
	count 7 : integer
	data  8 : string
}

.itemInst {
	type 0 : integer
	item 2 : item
}

.itemInsert {
	itemid 1 : string
	addCount 2 : integer
	create 3 : integer
	itemInst 4 : itemInst 	
}

.itemRemove {
	itemid 1 : string
	count 2 : integer
	destory 3 : integer
}

.bonusesResult {
	inserts 0 : *itemInsert 	# 新物品
}

.drawResult {
	type 1 : integer 			# 显示的类型
	protoId 2 : integer 		# 原型ID(物品)
	count 3 : integer 			# 个数(物品)
	point 4 : integer 			# 数量(非物品)
}

.costResult { 					# 消耗结果
	itemRemoves 0 : *itemRemove # 消耗物品
}


]]

local c2s =[[


openChest %d {
	request {
		instId 0 : string 		# 宝箱实例ID
		count 1 : integer 		# 开启宝箱个数
		order 2 : string 		# 选择宝箱的序号
	}
	response {
		errorcode 0 : integer
		itemRemoves 1 : *itemRemove
		bonusesResult 2 : bonusesResult
	}
}

useItem %d { 					# 可以直接使用的物品
	request {
		instId 0 : string 		# 物品实例ID
		count 1 : integer 		# 使用个数
		id 2: string 			# 政治丸 属性散传门客ID，密度道具 魅力道传红颜ID
								# 使用征收令时id是类型 1商产 2农产 3士兵
	}
	response {
		errorcode 0 : integer
		itemRemoves 1 : *itemRemove
		bonusesResult 2 : bonusesResult
	}
}

# 道具合成
itemsCompound %d {
	request {
		protoId 1 : integer 				# 合成道具原型ID
		count 2 : integer 					# 合成个数
	}
	response {
		errorcode 0 : integer
		protoId 1 : integer 				# 合成道具原型ID
		count 2 : integer 					# 合成个数
		costResult 3 : costResult           # 消耗
		itemInserts 4 : *itemInsert         # 合成道具
	}
}

]]

local s2c =[[

itemInserts %d {
	request {
		itemInserts 0 : *itemInsert
	}
}

itemRemoves %d {
	request {
		itemRemoves 0 : *itemRemove
	}
}

]]

return {
    types = types,
    c2s = c2s,
    s2c = s2c,
}