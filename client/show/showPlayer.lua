local httpc 	 	= require "http.httpc"
local clientPlayer	= require "clientPlayer"
local showPlayer 	= {}

function showPlayer.createcharcter(player,args)

	print("创建角色成功.")
	return showPlayer.entergame(player, args)
end	

function showPlayer.outgame(player,args)

	print("退出游戏成功.")
end	

function showPlayer.entergame(player, args)

	print("登陆游戏成功")
	local info = args.info
	assert(info ~= nil, "info is nil")
	player = clientPlayer:new(info,args.rxmls)	
	local time = args.time
	print("服务器当前时间 " .. time)
	return player
end

function showPlayer.testPayIngot(player, args)

	print("测试充值成功")
end	

function showPlayer.takeProperty(player, args)
	print("经营资产成功")
end	

function showPlayer.takemaintaskbonuses(player, args)

	player.show.bonusesResult(player, args.bonusesResult)
end	

function showPlayer.applyServerOrder(player, args)

	local order = args.order
	httpc.dns()
	httpc.timeout = 300
	local respheader = {}
	local param = {
		serverId = player.serverId,
		ucid = player.userId,
		serverOrder = order,
		callbackInfo = string.format('%s-%s-%s-%s-%s-%s',
		player.userId, player.name, player.serverId, 2, 3, order),--zhangsan01-zhangsan01-10005-2-600-12
	}
	local status, body = httpc.post("127.0.0.1:9021", "/", param, respheader)		
	print("[status] =====>", status)
end	

function showPlayer.addIngot(player, args)

	player.ingot = args.ingot
	print(" ingot = ", args.ingot)
end	
return showPlayer