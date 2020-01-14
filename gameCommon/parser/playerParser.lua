local mylog = require "base.mylog"

function parserData(xmlData)
	local string = string
	local tonumber = function (num) return assert(tonumber(num)) end
	local push = table.insert
	local config = {
		root = {},
		official_level = {},
		allAffairs = {},
		title = {},
		power2soulmate = {},
	}

	local function decodeInteger(data)

		local r = {}
		local arr = string.split(data, ",")
		for _, i in pairs(arr) do
			push(r, tonumber(i))
		end	
		return r
	end

	local groupData = {}
	for k, v in pairs(xmlData) do

		if v.tagName == "govAffairsGroup" then

			for _, v1 in ipairs(v) do

				local groupId = tonumber(v1.group)
				groupData[groupId] = {}
				if v1.tagName == "affairs" then

					for _, item in ipairs(v1) do
						local id = tonumber(item.id)
						local bonusesTypeA = tonumber(item.bonusesTypeA)
						local bonusesValueA = tonumber(item.bonusesValueA)
						local bonusesTypeB = tonumber(item.bonusesTypeB)
						local bonusesValueB = tonumber(item.bonusesValueB)		
						local _item = {

							id = id,
							bonusesTypeA = bonusesTypeA,
							bonusesValueA = bonusesValueA,
							bonusesTypeB = bonusesTypeB,
							bonusesValueB = bonusesValueB,							
						}				
						push(groupData[groupId], _item)
						assert(not config.allAffairs[id])
						config.allAffairs[id] = _item
					end	
				end	
			end	
		end	
	end	

	local maxOfficial = -1
	for k,v in pairs(xmlData) do

		if v.tagName == "officialLevel" then

			for _, item in ipairs(v) do

				local official = tonumber(item.official)
				if official > maxOfficial then maxOfficial = official end
				local trackRecord = tonumber(item.trackRecord)
				local gov_affairs_max = tonumber(item.gov_affairs_max)
				local gov_affairs_group = tonumber(item.gov_affairs_group)
				local propertyMax = tonumber(item.propertyMax)
				local salary = tonumber(item.salary)
				local maleIcon = item.maleIcon
				local femaleIcon = item.femaleIcon

				--local force = tonumber(item.force)
				--local wit = tonumber(item.wit)
				--local politics = tonumber(item.politics)
				--local charm = tonumber(item.charm)
				--local grownForce = tonumber(item.grownForce)
        		--local grownWit = tonumber(item.grownWit)
        		--local grownPolitics = tonumber(item.grownPolitics)
        		--local grownCharm = tonumber(item.grownCharm)				

        		local gov_affairs = assert(groupData[gov_affairs_group], string.format("error gov_affairs_group %s", gov_affairs_group))
				config.official_level[official] = {
					trackRecord = trackRecord,
					gov_affairs_max = gov_affairs_max,
					propertyMax = propertyMax,
					salary = salary,
					maleIcon = maleIcon,
					femaleIcon = femaleIcon,
					officialName = item.officialName,
					bonuses = item.bonuses,
				--	force = force,
				--	wit = wit,
				--	politics = politics,
				--	charm = charm,
					gov_affairs = gov_affairs,
				--	grownForce = grownForce,
				--	grownWit = grownWit,
				--	grownPolitics = grownPolitics,
				--	grownCharm = grownCharm,				
				}
			end		
			config.maxOfficial = maxOfficial	
		elseif v.tagName == "title" then	
			for _, item in ipairs(v) do

				local id = tonumber(item.id)
				local time = tonumber(item.time)
				local ingot = tonumber(item.ingot)
				local priority = tonumber(item.priority)
				config.title[id] = {
				id = id,
				time = time,
				ingot = ingot,
				priority = priority,
				name = item.name,
			}
			end		
		elseif v.tagName == 'power2soulmate' then
			for _, item in ipairs(v) do

				local power = tonumber(item.power)
				local soulmateId = tonumber(item.soulmateId)
				push(config.power2soulmate, {power = power, soulmateId = soulmateId})
			end	
			table.sort( config.power2soulmate, function (a,b) return a.power < b.power end )
		else 	

			if type(k) == "string" then
				if k ~= "tagName" then
					if k == "propertyCd" or k == "createBonuses" or k == "learnSkillExp" or k == "learnBookExp" 
						or k == "titleMailTitle" or k == "titleMailContent" or k == "officialTitle" 
						or k == "officalContent" or k == "vipTitle" or k == "vipContent"
						or k == "codeMailTitle" or k == "codeMailContent" then
						config.root[k] = v
					elseif k == "learnslotIngot" then
						config.root[k] = decodeInteger(v)	
					else	
						config.root[k] = tonumber(v)
					end	
				end
			end	
		end	
	end

	return config
end	
return parserData