
local dynamicActivity = require "afw.dynamicActivity"
local demo = class("dynamicDemo1", dynamicActivity)

function demo:checkParam()

	local param = self.param
	local err, errDesc = self:isParamHash("data", param.data)
    if err ~= 0 then return err, errDesc end
    return 0,""		
end	

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

function demo:onRemoveEx()

end	

--必须重载 0点重置
function demo:onResetState(activityGlobalState)
	print(" dynamicActivity demo onResetState==========>>>>")
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
--充值通知
function demo:onPayMoney(playerId, money, ingot, chargeType, chargegold)

end	

------------------------协议操作-----------------------
function demo:dkick(playerId, a, b, c)

	if not self:isOpened() then
		return {errorcode = errorcode.activity_not_open}
	end	
	print("dynamic ", playerId, a, b, c)
	local activityState = self:checkAndNewState(playerId)
	activityState.data.test3.c.m = 101
	activityState.data.test2 = "hello"
	self.subjectActivityStateChanged:notify(activityState)

	return {errorcode = 0}
end	

return demo