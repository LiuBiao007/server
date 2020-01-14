local handler = {}

function handler.trainplayer(actor)
	local __params = string.split(actor.param,",")
	actor.__params = __params
end	

function handler.additem_allawake(actor)
	local __params = string.split(actor.param,"-")
	actor.__params = __params
	assert(#__params == 2)
	local cmds = string.split(actor.cmd, "_")
	assert(#cmds > 0)
	actor.oldCmd = actor.cmd
	actor.cmd = cmds[1]
end	

function handler.trainhero(actor)
	local __params = string.split(actor.param,",")
	actor.__params = __params
end	

function handler.additem_treasurePiece(actor)
	local __params = string.split(actor.param, "-")
	actor.__params = __params
	assert(#__params == 2)
	local cmds = string.split(actor.cmd, "_")
	assert(#cmds > 0)
	actor.oldCmd = actor.cmd
	actor.cmd = cmds[1]
end

function handler.additem_treasure(actor)
	local __params = string.split(actor.param, "-")
	actor.__params = __params
	assert(#__params == 2)
	local cmds = string.split(actor.cmd, "_")
	assert(#cmds > 0)
	actor.oldCmd = actor.cmd
	actor.cmd = cmds[1]
end

return handler