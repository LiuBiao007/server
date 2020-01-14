local skynet = require "skynet"
local XMLParser = require "parser.parser"
local mylog = require "base.mylog"
local n = 30044--最小id
local m = 30045--最大id
local isRobot = 1
local serverId = 10000
local create = 2--1创建角色并进入游戏 2直接进游戏(前提是已经创建过角色)
local slow = 100-- 0 无限制 其他数字为每隔多少秒匀速发协议 300代表3秒
skynet.init(function ()
	XMLParser()
end)

skynet.start(
	function ()		
		--skynet.newservice("debug_console",8002)
		for i = n,m do
			skynet.newservice("client", i,isRobot,create,slow, serverId)
		end	
		skynet.exit()
	end		
)