local skynet 	= require "skynet"
local gameproto = require "protos.parser"
local sproto 	= require "sproto"
local socket 	= require "client.socket"
local _robot 	= require "robot.robots"
local events 	= require "events"
local sends 	= require "sends"
local login 	= require "login"
local admin 	= require "admin"
local mylog 	= require "base.mylog"
local sharedata 	= require "sharedata"
local ParserRobot 	= require "robot.ParserRobot"
local host 			= sproto.new(gameproto.s2c):host "package"
local request 		= host:attach(sproto.new(gameproto.c2s))


commonconst 	= require "commonconst"
gameconst   	= require "const.gameconst"
require "skynet.manager"
require "const.activityConst"
require "ext.math"
require "ext.io"
require "ext.string"
require "ext.os"
require "ext.table"	
require "class.class"
local version 		= commonconst.version
local show = {}
local function addShow()

	local keys = {"showActivity", "showItem", "showPlayer"}
	for _, key in pairs(keys) do

		local module = require("show." .. key)
		for k, v in pairs(module) do

			assert(not show[k], string.format("error show k %s module %s.", k, key))
			show[k] = v
		end	
	end	
end	
addShow()
local error2str = {}
for line in io.lines("../common/errorcode.lua") do

	local code, msg = line:match("%w%s*=%s*(%d+)%s*,%s*%-%-%s*(.*)")
	if code and msg then
		error2str[tonumber(code)] = msg
	end	
end	

local userId,rxmls,player,xmls,robot

local sendTimes 	= {}
local session 		= 0
local session2res 	= {}
local isCreate 		= false
local cid, isRobot, create, slow, serverId = ...
if create == "1" then isCreate = true end
local isSlow = true
if slow == "0" then isSlow = false end
--登陆
local secret 
if isRobot then
	xmls = ParserRobot()
	secret = login({user = "jamaaac" .. cid,
		pass = "123456",
		server = serverId})
	local function timeout()	
		skynet.timeout(500, timeout)
		collectgarbage "collect"
	end	
	timeout()	
end

local fd = socket.connect("127.0.0.1", 8889)
assert(fd, "connect to 8889 error")
local function encoderequest(name, args)

	if robot and isSlow then
		slow = tonumber(slow)
		if slow < 0 then slow = -slow end
		skynet.sleep(slow)
		while true do
			skynet.sleep(100)
			if robot.state and robot.state == "send" then

			else
				break
			end	
		end	
	end	
	session = session + 1
	local p = request(name, args, session)
	session2res[session] = {name = name, args = args}
	if robot then 
		robot.session = session 
		robot.state = "send" 
	end
	return p
end

local function sendpackage(name, args)
	local p = string.pack(">s2", encoderequest(name, args))
	socket.send(fd, p)
end

local function print_response(session, args)


	local res = session2res[session]
	if res == nil then
		print("数据错误 session " .. session)
		return
	end

	if args.errorcode > 0 then
		return print(error2str[args.errorcode])
	end	

	local name = res.name	
	local f = show[name]
	assert(f, "function not exist : " .. name)

	if name == "entergame" or name == "createcharcter" then	
		args.rxmls = rxmls
		player = f(player, args)
		if isRobot then
			robot = _robot:new({player = player,xmls = xmls})
			robot.state = "received"
			player.robot = robot
			if isCreate then
				robot:robot_begin()		
			else
				robot:clearBegin()
				robot:startrandom()	
			end	
		end	
	else	
		f(player, args)
		if isRobot then
			if robot then robot.state = "received" end
			if name == "createcharcter" then
				assert(args.errorcode == 0)
				sends.entergame({"jamaaac" .. cid, serverId, secret, version})
			else
				if args.errorcode ~= 0 then
					robot:doError(session, args.errorcode)
				else	
					if args.battleResult and not args.battleResult.isWin then
						robot:toBeStrong()--机器人增强操作 为保证能测试到失败情况 每次只增强一点
					end	
					assert(robot)
					if robot:beginend() then
						robot:clearBegin()
						robot:startrandom()
					elseif robot:IsClearBegin() then
						robot:startrandom()	
					end
				end	
			end	
		end	
	end	
	session2res[session] = nil
	if player then
		if not player.userId then player.userId = userId end
		if not player.serverId then player.serverId = serverId end
	end

	if sendTimes[name] then
		print(name, "耗时:", skynet.time() - sendTimes[name])
		sendTimes[name] = nil
	end
end

local bigdata = {}
local function print_request(name, args)

	if args or name ~= "heartbeat" then
		local f = events[name]
		if f then
			if name == "bigdata_header" then
				f(bigdata, args)
			elseif name == "bigdata_content" then
				local bdata = f(bigdata, args)
				if bdata then--bigdata数据接收完整
					local type, _session, v =  host:dispatch(bdata.data)
					print_response(_session,v)
					bigdata[bdata.index] = nil
					print("大数据解析完整.")
				end	
			else	
				if not player then return end
				f(player,args)		
				if robot then robot:listenEvent(name, player, args) end	
			end
		end	
	end
end

local function print_package(t, ...)
	if t == "REQUEST" then
		print_request(...)
	else
		print_response(...)
	end
end

local last = ""

local function unpack_package(text)
	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte(1) * 256 + text:byte(2)
	if size < s+2 then
		return nil, text
	end

	return text:sub(3,2+s), text:sub(3+s)
end

local function recv_package(last)
	local result
	result, last = unpack_package(last)
	if result then
		return result, last
	end
	local r = socket.recv(fd)
	if not r then
		return nil, last
	end
	if r == "" then
		print("Server has closed.")
		skynet.exit()
		--error "Server closed"
	end
	return unpack_package(last .. r)
end

local function dispatch_package()
	while true do
		local v
		v, last = recv_package(last)
		if not v then
			break
		end

		print_package(host:dispatch(v))
	end
end

sends.sendpackage = sendpackage
sends.loginfunc = login
if isRobot then
	skynet.init(function ()
		if robot and not robot.sends then robot.sends = sends end
		rxmls = sharedata.query("XMLCONFIG")
		if isCreate then
			sends.createcharcter({"zhangsan" .. cid, 1, "jamaaac" .. cid, 2, serverId, secret, version})
		else
			sends.entergame({"jamaaac" .. cid, serverId, secret, version})
		end	
	end)
end	

local input_arr = {

	--"createcharcter ZHANGJIN15 1 ZHANGJIN15 10000 10005",
	--"additem 15000020 10",
	--"additem 15000021 11",
	--"addIngot 100",
	--"addGoldCoin 99"
	--"entergame ZHANGJIN15 10005",
	--"dkick 1009099 2 9 18",
	--"playeractivity 2 3 4",
	--"uniqueactivity 3 8 100",
	--"addIngot 100",
	--"mkick 12 19 118",
	--"debugtime 23 59 55",
	--"entergame ZHANGJIN2 10005",
	--"outgame"
}

local stop = false
skynet.start(
function ()
	if isRobot then
		local function timeout()	
			skynet.timeout(100, timeout)
			dispatch_package()
		end	
		timeout()
	else	
		while true do

			dispatch_package()
			local input 
			if #input_arr > 0 then
				input = table.remove(input_arr, 1)
			else
				input = socket.readstdin()	
			end	
			
			if input then
				local arr = string.split(input, " ")
				local cmd = table.remove(arr,1)
				local send = sends[cmd]
				if not send then
					local lshow = show[cmd]
					if not lshow then
						print("不支持的命令:",cmd)
					else
						if player then
							lshow(player, arr)
						else	
							print("还未进入游戏")
						end						
					end	
				else

					if cmd == "entergame" or cmd == "createcharcter" then
						if secret then 
							table.insert(arr, secret) 
							table.insert(arr, version)
						end
					end	
					if cmd == "login" then
						secret = sends.login(arr)
						userId = arr[1]
						serverId = arr[3]
					elseif cmd == "admin" then
						admin(arr)
					else					
						sendTimes[cmd] = skynet.time()
						send(arr)
					end	
				end
			else	
				socket.usleep(10)
			end	
			skynet.sleep(10)
		end	
	end	
end
	--socket.close(fd)
)

