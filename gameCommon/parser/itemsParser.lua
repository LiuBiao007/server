local mylog = require "base.mylog"
local gameconst = require "const.gameconst"

local push = table.insert
function parserData(xmlData)

	local tonumber = math.tonumber
	local types = gameconst.itemtype

	local function parserRandom(data)

		local r = {arr = {}}
		local totalRate = 0
		local arr = data:split(";")
		for _, item in pairs(arr) do

			local c = item:split(",")
			assert(#c == 2)
			local v = tonumber(c[1])
			local rate = tonumber(c[2])
			local ch = {v = v, rate = rate}
			push(r.arr, ch)
			totalRate = totalRate + rate
		end	
		r.totalRate = totalRate
		return r
	end	

	local items = {}
	items.booksstar = {}
	for k,v in ipairs(xmlData) do

		if v.exp then
			assert(false)--exp字段被金龙宝宝箱使用了
		end	
		local id = tonumber(v.id)
		local subType = tonumber(v.subType)
		local expires = #v.expires > 0 and os.stringToDateTime(v.expires) or 0
		local proto = {
			id = id,
			type = tonumber(v.type),
			color = tonumber(v.color),
			name = v.name,
			subType = subType,
			price = tonumber(v.price),
			maxCount = tonumber(v.maxCount),
			data = v.data,
			extraType = tonumber(v.extraType),
		}
		items[id] = proto
		if subType == types.scrollForce then 							--武力卷轴
			items.scrollForce = proto
		elseif subType == types.scrollWit then 							--智力卷轴
			items.scrollWit = proto
		elseif subType == types.scrollPolitics then 					--政治卷轴
			items.scrollPolitics = proto
		elseif subType == types.masterHorn then							--跨服喇叭
			items.masterHornProto = proto
		elseif subType == types.scrollCharm then 						--魅力卷轴
			items.scrollCharm = proto
		elseif subType == types.book1star 
			or subType == types.book2star 								--五星宝典
			or subType == types.book3star 
			or subType == types.book4star 
			or subType == types.book5star then
			proto.data = tonumber(proto.data)
			push(items.booksstar, proto)
		elseif subType == types.politicsBall then						--政治丸
			proto.data = tonumber(proto.data)
		elseif subType == types.bosomItem then							--亲密度道具
			proto.data = tonumber(proto.data)
		elseif subType == types.charmItem then							--魅力道具
			proto.data = tonumber(proto.data)
		elseif subType == types.physicalItem then						--体力丸
			proto.data = tonumber(proto.data)
		elseif subType == types.vigorItem then							--精力丸
			proto.data = tonumber(proto.data)
		elseif subType == types.energyItem then							--活力丸
			proto.data = tonumber(proto.data)	

		elseif subType == types.heroBookExpPack then					--书籍经验包
			proto.data = tonumber(proto.data)	
		elseif subType == types.heroSkillExpPack then					--技能经验包
			proto.data = tonumber(proto.data)	
		elseif subType == types.heroBookExpRandom or subType == types.heroSkillExpRandom then					--书籍经验包
			local arr = {}
			local totalRate = 0	
			assert(#proto.data > 0)
			local arr1 = proto.data:split(";")
			for _, item in pairs(arr1) do

				local arr2 = item:split(",")
				local num, rate = tonumber(arr2[1]), tonumber(arr2[2])
				totalRate = totalRate + rate
				push(arr, {num = num, rate = rate})
			end	
			proto.fcnf = {totalRate = totalRate, arr = arr}	

		elseif subType == types.forceBall then							--武力丸
			proto.data = tonumber(proto.data)	
		elseif subType == types.charmBall then							--魅力丸
			proto.data = tonumber(proto.data)	
		elseif subType == types.witBall then							--智力丸
			proto.data = tonumber(proto.data)	
		elseif subType == types.randomBosomItem or subType == types.randomCharmItem then	
			proto.data = parserRandom(proto.data)
		elseif subType == types.titleItem then							--称号物品
			proto.data = tonumber(proto.data)		
		elseif subType == types.addLearnTimeItem then					--增加学习时间道具
			proto.data = tonumber(proto.data)					
		elseif subType == types.randomBall then							--随机散
			local arr = proto.data:split(",")
			assert(#arr == 2)
			proto._min = tonumber(arr[1])
			proto._max = tonumber(arr[2])
		elseif subType == types.battlePlate then						-- 出使令
			items.battlePlateProto = proto
		elseif subType == types.challengePlate then						-- 挑战令
			items.challengePlateProto = proto
		elseif subType == types.manhuntPlate then						-- 追捕令
			items.manhuntPlateProto = proto
		elseif subType == types.stageBattlePlate then					-- 关卡出战令
			items.stageBattlePlateProto = proto
		end
	end

	table.sort(items.booksstar, function (a, b) return a.data < b.data end)
	assert(items.masterHornProto)
	assert(items.battlePlateProto)
	assert(items.manhuntPlateProto)
	assert(items.challengePlateProto)
	assert(items.stageBattlePlateProto)
	return items
end	
return parserData	 