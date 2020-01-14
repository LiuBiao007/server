
local serviceProxy = require "player.serviceProxy"
local proxy = class("proxy", serviceProxy)
--联盟 联盟活动 以及其他服务数据整理
function proxy:onEnterGameEx(uniqueData)

	local sendData = self.sendData
end
--联盟 联盟活动 以及其他服务数据下发
function proxy:sendEnterDataEx(player, result)
	
	local sendData = self.sendData
end	

return proxy
