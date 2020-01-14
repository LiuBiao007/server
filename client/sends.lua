local httpc = require "http.httpc"
local mylog = require "base.mylog"
local sends = {}

function sends.login(param)
	local token = {
		user = param[1],
		pass = param[2],
		server = param[3],
	}

	return sends.loginfunc(token)
end

function sends.debugtime(param)
	
	local t = {hour = param[1], min = param[2], sec = param[3]}
	if param[4] then t.day = param[4] end
	sends.sendpackage("debugtime", t)	
end

function sends.dkick(param)
	
	local t = {activityId = param[1], a = param[2], b = param[3], c = param[4]}
	sends.sendpackage("dkick", t)
end

function sends.mkick(param)
	
	local t = {a = param[1], b = param[2], c = param[3]}
	sends.sendpackage("mkick", t)
end

function sends.playeractivity(param)
	sends.sendpackage("playeractivity", {a = param[1], b = param[2], c = param[3]})
end

function sends.uniqueactivity(param)
	sends.sendpackage("uniqueactivity",  {a = param[1], b = param[2], c = param[3]})
end

function sends.admin(param)
end

function sends.sendsoulmate(param)
	sends.sendpackage("sendsoulmate",{power = param[1]})	
end


function sends.createaccount(param)

	local userId = param[1]
	local password = param[2]
	local phoneNumber = param[3]
	local mac = param[4]
	local newparam = {
		userId = userId,
		password = password,
		phoneNumber = phoneNumber,
		mac = mac,
	}

	httpc.dns()
	httpc.timeout = 300

	local status, body = httpc.post("127.0.0.1:8455", "/createaccount", newparam, {})	
	print("createaccount:")
	print(status)
	print(body)
end

function sends.quickcreateaccount(param)
	
	local phoneNumber = param[1]
	local mac = param[2]
	local newparam = {mac = mac, phoneNumber = phoneNumber}

	httpc.dns()
	httpc.timeout = 300

	local status, body = httpc.post("127.0.0.1:8455", "/quickcreateaccount", newparam, {})	
	print("quickcreateaccount:")
	print(status)
	print(body)	
end

function sends.createcharcter(param)

	local newparam = {name = param[1],sex = param[2], userid = param[3], platform=param[4],
		serverid = param[5], serverName = "默认服务器", icon="aaa", token="1111111111"}
	if param[6] then
		newparam = {name = param[1],
		sex = param[2], userid = param[3], platform=param[4],serverid = param[5],token = param[6], 
		version = param[7], serverName = "默认服务器", icon="aaa"}
		--version = 100, serverName = "默认服务器"}
	end	
	if not newparam.version then newparam.version = "1.0.22" end
	sends.sendpackage("createcharcter",newparam)	
end

function sends.applyServerOrder(param)

	sends.sendpackage("applyServerOrder")	
end

function sends.entergame(param)
	local newparam = {userid = param[1],serverid = param[2], serverName = '默认服务器',token = "zzzzz",version = "1.0.22",serverName = '默认服务器'}
	if param[3] then
		newparam = {userid = param[1],serverid = param[2],token = param[3],version = param[4],serverName = '默认服务器'}
	end	

	sends.sendpackage("entergame",newparam)		
end

function sends.outgame()
	sends.sendpackage("outgame")		
end

function sends.addIngot(param)
	sends.sendpackage("addIngot", {ingot = param[1]})
end

function sends.addGoldCoin(param)
	sends.sendpackage("addGoldCoin", {goldCoin = param[1]})
end

function sends.additem(param)
	sends.sendpackage("additem", {protoId = param[1], count = param[2]})
end

function sends.useItem(param)
	sends.sendpackage("useItem", {instId = param[1], count = param[2], id = param[3]})
end

function sends.testPayIngot(param)
	sends.sendpackage("testPayIngot", {money = param[1]})
end

function sends.chat(param)
	sends.sendpackage("chat", {channelId = param[1],content = param[2], targetPlayerName = param[3]})		
end

function sends.addchatblack(param)
	sends.sendpackage("addchatblack", {id = param[1]})		
end

function sends.decchatblack(param)
	sends.sendpackage("decchatblack", {id = param[1]})		
end 

function sends.sendMsgMail(param)
	sends.sendpackage("sendMsgMail", {receiverId = param[1], title = param[2], content = param[3]})
end

function sends.sendSystemMail(param)
	sends.sendpackage("sendSystemMail", {senderName = param[1], receiverId = param[2], title = param[3], content = param[4], attaches = param[5]})
end

function sends.readMail(param)
	sends.sendpackage("readMail", {mailId = param[1]})
end

function sends.takeMailBonuses(param)
	sends.sendpackage("takeMailBonuses", {mailId = param[1]})
end

function sends.deleteMail(param)
	sends.sendpackage("deleteMail", {mailId = param[1]})
end

return sends