local skynet         = require "skynet"
local subject 		 = require "base.subject"
local uniqueActivity = require "afw.uniqueActivity"
local timer 		 = require "commonService.timer"
local json			 = require "ext.json"
local sharedata      = require "skynet.sharedata"
local dynamicParam   = require "afw.dynamicParam"
local serviceTrigger = require "base.serviceTrigger"
local dynamicActivity = class("dynamicActivity", uniqueActivity)

function dynamicActivity:init(_, param, proxyService)

	local id = param.id
    self.param = param

    self.subjectDynamicActivityInsert       = subject:new()
    self.subjectDynamicActivityRemove       = subject:new()
    self.subjectDynamicActivitySortIndex    = subject:new()
    self.subjectDynamicActivityStateChanged = subject:new()

    self.subjectDynamicActivityInsert:attach(self.onDynamicActivityInsert, self)
    self.subjectDynamicActivityRemove:attach(self.onDynamicActivityRemove, self)
    self.subjectDynamicActivitySortIndex:attach(self.onDynamicActivitySortIndex, self)
    self.subjectDynamicActivityStateChanged:attach(self.onDynamicActivityStateChanged, self)
 
    self.proxyService = assert(tonumber(proxyService), string.format("dynamicActivity proxyService %s.", proxyService))
    dynamicActivity.__father.init(self, nil, id)
end

function dynamicActivity:startDynamic(isLoad)

    local err, errDesc = self:checkParam()
    if err ~= 0 then return err, errDesc end

    if isLoad then
        self.param = dynamicParam:load(self.param)
    else    
        self.param = dynamicParam:create(self.param)
    end
    if self.param.state < DYNAMICACTIVITYSTATE_VISIBLE then
        self.param.state = DYNAMICACTIVITYSTATE_VISIBLE
    end    
    self:startDynamicEx(isLoad)
      
    return 0,""
end    

function dynamicActivity:buildKeys()

    local clasz = self.param.clasz
    assert(ACTIVITY_CONFIG[clasz], string.format("error clasz %s.", clasz))
    self.__statekey     = ACTIVITY_CONFIG[clasz].statekey    
    self.__globalkey    = ACTIVITY_CONFIG[clasz].globalkey    
end    

function dynamicActivity:startDynamicEx(isLoad)

    local now = timer.time()

    if not isLoad then
	   self.subjectDynamicActivityInsert:notify()
    end   
	--先做一个简单的支持 后面若有复杂的定时器需求再定制自己的定时器
	skynet.fork(function ()

        if self.param.startTime <= now then
            self:onDynamicRun()
        else
            timer.submit(self.param.timerStart)
            self:onDynamicRun()        
        end    

        if self.param.endTime <= now then
            self:onDynamicExpired()
        else
            timer.submit(self.param.timerEnd)
            self:onDynamicExpired()
        end
	end)
end	

function dynamicActivity:isOpened()

    return self.param.state == DYNAMICACTIVITYSTATE_RUNNING
end    

function dynamicActivity:setState(state)

	self.param.state = state
	self.param.updateTime = os.getCurTime()
	self.subjectDynamicActivityStateChanged:notify()
end	

function dynamicActivity:onDynamicRun()

	self:setState(DYNAMICACTIVITYSTATE_RUNNING)
end

function dynamicActivity:onDynamicExpired()

	self:setState(DYNAMICACTIVITYSTATE_EXPIRED)
	self:removeDynamicActivity()
end	

function dynamicActivity:getParam()

	return self.param:packet()
end	

function dynamicActivity:onDynamicActivityInsert()

	self.playerMan:broadcast("sendEvent", {}, 'dynamicActivityInsert', 
		{dynamicActivityParam = self.param:packet()})
end	

function dynamicActivity:onDynamicActivityRemove()

	self.playerMan:broadcast("sendEvent", {}, 'dynamicActivityRemove', 
		{id = self.param.id})    
end	

function dynamicActivity:onDynamicActivitySortIndex()

	self.playerMan:broadcast("sendEvent", {}, 'dynamicActivitySortIndex', 
		{id = self.param.id, sortIndex = self.param.sortIndex})
end	

function dynamicActivity:onDynamicActivityStateChanged()

	self.playerMan:broadcast("sendEvent", {}, 'dynamicActivityStateChanged',
		{id = self.param.id, state = self.param.state})
end	

function dynamicActivity:getNode(id)

	return self.param
end	

function dynamicActivity:runOk()
	mylog.info(" 运营活动【%s】[id:%s] [clasz:%s] 启动成功.", self.name, self.id, self.param.clasz)
end	

function dynamicActivity:removeDynamicActivity()

    self:send("commonService.admin", "removeActivityId", self.id)
    serviceTrigger.onServiceExit()
   
    -- 移除玩家活动数据及全局数据
    self:onRemove()

    -- 移除Redis  mysql
    self.param:delete()

    -- 通知在线玩家动态活动移除
    self.subjectDynamicActivityRemove:notify(self)

    -- 活动下架 服务退出
    self:exit()
end

function dynamicActivity:onRemove()

    for _, activityState in pairs(self.activityStates) do

    	self:removeActivityState(activityState)
    end	
    if self.activityGlobalState then
        self.activityGlobalState:delete()
    end    
    self.activityGlobalState = nil

    if type(self.onRemoveEx) == "function" then
    	self:onRemoveEx()
    end	
end	

function dynamicActivity:exit()

	skynet.sleep(100)
	dynamicActivity.__father.shut(self)
	mylog.info(" %s [id:%s]运营活动下架.", self.name, self.id)
	skynet.exit()
end	

function dynamicActivity:setDynamicActivitySortIndex(index)
    
    self.param.sortIndex = index
    self.subjectDynamicActivitySortIndex:notify(self)
end

function dynamicActivity:isParamHash(desc, param)
    if type(param) ~= "table" then
        return errorcode.activity_not_table, string.format("%s not hash", desc)  -- 不是table
    end

    return 0
end

function dynamicActivity:isParamArray(desc, param, min, max)
    if type(param) ~= "table" then
        return errorcode.activity_not_table, string.format("%s not array", desc)  -- 不是table
    end

    local len = #param
    if len <= 0 then
        return errorcode.activity_not_array, string.format("%s not array", desc)  -- 不是 Array
    end

    if len > max or len < min then
        return errorcode.activity_array_len_error, string.format("%s array range not %d~%d", desc, min, max)  -- 数组长度不在取值范围内
    end

    return 0
end

function dynamicActivity:isParamString(desc, param)
    if type(param) ~= "string" then
        return errorcode.activity_not_string, string.format("%s not string", desc)  -- 不是字符串
    end

    return 0
end

function dynamicActivity:isParamText(desc, param)
    if type(param) ~= "string" then
        return errorcode.activity_not_string, string.format("%s not string", desc)  -- 不是字符串
    end

    return 0
end

function dynamicActivity:isParamInt(desc, param)
    if type(param) ~= "number" then
        return errorcode.activity_not_number, string.format("%s not number", desc)  -- 不是数字
    end

    return 0
end

function dynamicActivity:isParamIntRange(desc, param, min, max)
    if type(param) == "number" then
        if param < min or param > max then
            return errorcode.activity_number_error, string.format("%s number range not %d~%d", desc, min, max)  -- 不在取值范围内
        end
    else
        return errorcode.activity_not_number, string.format("%s not number", desc)  -- 不是数字
    end

    return 0
end

return dynamicActivity