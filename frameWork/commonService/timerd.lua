local skynet        = require "skynet"
local serviceObject = require "objects.serviceObject"
local timerd        = class("commonService.timerd", serviceObject)

local task = {session = 0, difftime = 0}
function timerd:init()

    local maxQuene = 102400
    timerd.__father.init(self, maxQuene)
    --关闭消息锁
    self:closeLock()
    --关闭redis写入
    self:closeSyncToRedis()    
end    

local function next_time(now, ti)
    local nt = {
        year = now.year ,
        month = now.month ,
        day = now.day,
        hour = ti.hour or 0,
        min = ti.min or 0,
        sec = ti.sec or 0,
    }
    if ti.wday then
        -- set week
        assert(ti.day == nil and ti.month == nil)
        nt.day = nt.day + ti.wday - now.wday
        local t = os.time(nt)
        if t < now.time then
            nt.day = nt.day + 7
        end
    else
        -- set day, no week day
        if ti.day then
            nt.day = ti.day
        end
        if ti.month then
            nt.month = ti.month
        end
        local t = os.time(nt)
        if t < now.time then
            if ti.month then
                nt.year = nt.year + 1   -- next year
            elseif ti.day then
                nt.month = nt.month + 1 -- next month
            else
                nt.day = nt.day + 1     -- next day
            end
        end
    end

    return os.time(nt)
end

local function changetime(ti)

    local ct = math.floor(os.getCurTime())
    local current = os.date("*t", ct)
    current.time = ct
    ti.hour = ti.hour or current.hour
    ti.min = ti.min or current.min
    ti.sec = ti.sec or current.sec
    local nt = next_time(current, ti)
    task.difftime = os.difftime(nt,ct)
    for k,v in pairs(task) do
        if type(v) == "table" then
            skynet.wakeup(v.co)
        end
    end
    print(" ---->changetime ", string.dump(nt))
    return nt
end

function timerd:timerd(source, ti)

    --获取调的时间差 
    if not ti then
        
        return task.difftime
    end
    --修改任务到期时间
    if ti.changetime then
   
        return changetime(ti)
    end

    --注册新的定时器
    local session = task.session + 1
    task.session = session
    repeat
        local ct = math.floor(os.getCurTime()) + task.difftime
        local current = os.date("*t", ct)
        current.time = ct
        local nt = next_time(current, ti)
        task[session] = {time = nt, co = coroutine.running(), address = source}
        local diff = os.difftime(nt , ct)
        print("===========>sleep", diff)
    until skynet.sleep(diff * 100) ~= "BREAK"
    task[session] = nil
    return nil
end    

function timerd:do_cmd_rewrite(session, source, cmd, ti)

    return self[cmd](self, source, ti)
end   

local function collectInfo()

    local info = {}
    for k, v in pairs(task) do
        if type(v) == "table" then
            table.insert( info, {
                time = os.date(nil, v.time),
                address = skynet.address(v.address),
            })
            return info
        end
    end
    return info
end    

function timerd:onServiceStarted()

    skynet.info_func(function()
        return collectInfo()
    end)
end    

function timerd:debug()

    print(string.dump(collectInfo()))
end    

return timerd
