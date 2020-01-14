
local uniqueActivity = require "afw.uniqueActivity"
local demo = class("playerDemo1", uniqueActivity)

--可重载
function demo:onCreateEx()
	--下面是一个处理排行榜的示例
	--装载所有的activityStates 一般用于排行榜 注意只用有用的字段以节省内存
	--self.rankObj = zrank:new()
	--local data = self:loadAllActivityStates()
	--for _, item in pairs(data) do
	--	if item.data.score > 0 then
	--		self.rankObj:add(item.id, item.data.score)		
	--
	--	end
	--end
end	
--可重载
function demo:initGlobalData(activityGlobalState)

end	

--可重载
function demo:onEnterGameEx(activityState)

	mylog.info("uniqueActivity--------onEnterGameEx %s", activityState.id)
end	

--必须重载 0点重置
function demo:onResetState(activityGlobalState)

	activityGlobalState.data = {}
	self.subjectActivityGlobalStateChanged:notify(activityGlobalState)	
end	
--必须重载
function demo:initStateData(data)

	data.test1 = 1
	data.test2 = "abc"
	data.test3 = {
		a = 1,
		b = 2,
		c = {
			m = 1,
			n = "global"
		}
	}
end	

------------------------协议操作-----------------------
function demo:gkick(playerId, a, b, c)

	print("global ", a, b, c)
	local activityState = self:checkAndNewState(playerId)
	activityState.data.test3.c.m = 101
	activityState.data.test2 = "hello"
	self.subjectActivityStateChanged:notify(activityState)

	return {errorcode = 0}
end	

return demo