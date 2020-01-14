local handler = {}
function handler.trainplayer(actor, send)

	local num = #actor.__params
	local index = actor.rand:rand(num)
	local trainId = actor.__params[index]
	send({trainId})
end

local nameIndex = 1
function handler.changename(actor, send)
	
	local name = "newname" .. nameIndex
	nameIndex = nameIndex + 1
	send({name})
end

function handler.addlifestar(actor, send)
	send()
end
return handler