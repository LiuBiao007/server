
local playerActivity = require "afw.playerActivity"
local demo = class("playerDemo1", playerActivity)
--可重载
function demo:onCreate()


end	
--可重载
function demo:onEnterGameEx(activityState)

end	
--可重载
function demo:buildTimerEx(activityState)

end	
--必须重载 0点重置
function demo:onResetState(activityState)

	activityState.data = {
		test1 = 0,
		test2 = "a",
		test3 = {
			a = 0,
			b = 0,
			c = {m = 0, n = "n"}
	}
	}
	self.subjectActivityStateChanged:notify(activityState)	
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
			n = "james"
	}
	}
end	

------------------------协议操作-----------------------
function demo:demokick(a, b, c)

	print(" player playerActivity ", self.player.id, a, b, c)
	local activityState = self:checkAndNewState()
	activityState.data.test3.c.m = 101
	activityState.data.test2 = "hello"
	self.subjectActivityStateChanged:notify(activityState)

	return {errorcode = 0}
end	

return demo