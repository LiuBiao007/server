local skynet = require "skynet"
require "skynet.manager"
local businessObject = require "objects.businessObject"
local logManager     = class("logManager", businessObject)

local os = os
local io = io
local table = table
local string = string

local send_state_unfinished = 0 -- 警告邮件未发送
local send_state_finished   = 1 -- 警告邮件已发送

local packLogRecords = {} -- 记录所有打包日志
local packTimingTime = 3600 * 2 -- 2小时之前log打包
local processTimingTime = 100 * 60 * 0.5 -- 5分钟定时处理log
local lastCheckTime = os.getCurTime()

local path = "./log/"
local foundErrorFileName = "foundError.txt"
local logErrorMap = {}

local function getLogNameByTime(time)
    return string.format("%04d_%02d_%02d_%02d_game.log", os.date("%Y", time), os.date("%m", time), os.date("%d", time), os.date("%H", time))
end

local function findLogError(fileName)
    local file = io.open(path .. fileName)
    if file then
        file:close()
        local order = string.format("grep -n \"stack traceback:\" %s%s > %s%s", path, fileName, path, foundErrorFileName)
        local ok = os.execute(order)
        if ok then
            local errorFile = io.open(path .. foundErrorFileName)
            if errorFile then
                local text = errorFile:read('*a')
                errorFile:close()

                local arr = string.split(text, "\n")
                local foundErrorCount = #arr
                if foundErrorCount > 0 then
                    redisdb:hmset("serconf", fileName, foundErrorCount)
                    mylog.info("%s foundErrorCount:%d", fileName, foundErrorCount)

                    local i = 0
                    if not logErrorMap[fileName] then
                        logErrorMap[fileName] = {}
                        logErrorMap[fileName].lineMap = {}
                        logErrorMap[fileName].errDescMap = {}
                    end

                    for _, errorDesc in ipairs(arr) do
                        local errArr = string.split(errorDesc, ":")
                        local lineNum = tonumber(errArr[1])

                        if not logErrorMap[fileName].lineMap[lineNum] then
                            local key
                            local errDesc = ""
                            local startLine = lineNum > 1 and lineNum - 1 or lineNum
                            ok = os.execute(string.format("sed -n \"%s,%sp\" %s%s > %s%s", startLine, lineNum + 20, path, fileName, path, foundErrorFileName))
                            if ok then
                                errorFile = io.open(path .. foundErrorFileName)
                                if errorFile then
                                    i = 0
                                    for line in errorFile:lines() do
                                        i = i + 1

                                        if i <= 1 then
                                            errDesc = line
                                        elseif i == 3 then
                                            if logErrorMap[fileName].errDescMap[line] then
                                                break
                                            end
                                            key = line
                                            errDesc = string.format("%s\n%s", errDesc, line)
                                        elseif string.sub(line, 1, 3) ~= "[:0" then
                                            errDesc = string.format("%s\n%s", errDesc, line)
                                        else
                                            break
                                        end
                                    end
                                end
                                errorFile:close()
                            end
                            logErrorMap[fileName].lineMap[lineNum] = true
                            if key and errDesc ~= "" then
                                logErrorMap[fileName].errDescMap[key] = {lineNum = lineNum, state = send_state_unfinished, errDesc = errDesc}
                            end
                        end
                    end
                end
            end
        end
        os.execute(string.format("rm -f %s%s", path, foundErrorFileName))
    end
end

local findFileName = "find.txt"
local function init()
    os.execute(string.format("find %s*.log > %s%s", path, path, findFileName))

    local function str2Time(str)
        local year, month, day, hour = string.match(str, "(%d+)_(%d+)_(%d+)_(%d+)_game.log")
        return os.time({year = tonumber(year), month = tonumber(month), day = tonumber(day), hour = tonumber(hour)})
    end

    local prev2Time = os.getCurTime() - packTimingTime
    local file = io.open(path .. findFileName)
    if file then
        local str = file:read('*a')
        file:close()

        local data = string.split(str, "\n")
        for _, fileName in ipairs(data or {}) do
            local time = str2Time(fileName)
            if prev2Time > time then
                os.execute(string.format("gzip -f %s", fileName))
            end
        end
    end

    -- 记录当前服务器打包的日志文件
    os.execute(string.format("find %s*.log.gz > %s%s", path, path, findFileName))
    local file = io.open(path .. findFileName)
    if file then
        local str = file:read('*a')
        file:close()

        local data = string.split(str, "\n")
        for _, str2 in ipairs(data or {}) do
            local _, fileName = string.match(str2, string.format("(%s)(.*)", path))
            -- mylog.info("fileName:%s", fileName)
            table.insert(packLogRecords, fileName)
        end
    end
    os.execute(string.format("rm -f %s%s", path, findFileName))
end

local function process()
    local now = os.getCurTime()

    -- 检测当前小时的logErrorCount
    findLogError(getLogNameByTime(now))

    -- 隔小时处理日志(延迟30s)
    if os.date("%H", now - 30) ~= os.date("%H", lastCheckTime) then
        -- 检测上一小时的logErrorCount
        findLogError(getLogNameByTime(lastCheckTime))

        --  打包压缩日志
        local prev2Time = now - packTimingTime
        local fileName = getLogNameByTime(prev2Time)
        mylog.info("gzip -f %s%s", path, fileName)
        logErrorMap[fileName] = nil
        os.execute(string.format("gzip -f %s%s", path, fileName))

        lastCheckTime = now
        table.insert(packLogRecords, fileName .. ".gz")
    end

    skynet.timeout(processTimingTime, process)
end

function logManager:getServerInfo()
    return 0, __cnf.serverId
end

function logManager:getPackLogRecords()
    return 0, table.concat(packLogRecords, " ")
end

function logManager:removeLog(fileNames)
    for _, fileName in ipairs(fileNames) do
        os.execute(string.format("rm -f %s%s", path, fileName))
        for i, _fileName in ipairs(packLogRecords) do
            if fileName == _fileName then
                table.remove(packLogRecords, i)
                break
            end
        end

        mylog.info("removeLog => [%s]", fileName)
    end
    return 0, ""
end

function logManager:getServerAndLogInfo()
    local errDesc = ""
    local lineNumArr = {}
    local now = os.getCurTime() - 60 * 5
    local fileName = getLogNameByTime(now)
    local results = {fileName = fileName, serverName = string.format("%s(%s)", __cnf.serverName, __cnf.serverId), lineNumStr = "", errDesc = ""}

    if logErrorMap[fileName] then
        for _, info in pairs(logErrorMap[fileName].errDescMap) do
            if info.state == send_state_unfinished then
                table.insert(lineNumArr, info.lineNum)
                errDesc = string.format("%s\n\n%s", errDesc, info.errDesc or "")
            end
        end
    end

    if #lineNumArr > 0 then
        results.errDesc = errDesc
        results.lineNumStr = table.concat(lineNumArr, " ")
    end

    return 0, "", results
end

function logManager:setLogErrorState(params)
    local fileName = table.remove(params, 1)
    if fileName and logErrorMap[fileName] then
        for _, lineNum in ipairs(params or {}) do
            for _, info in pairs(logErrorMap[fileName].errDescMap) do
                if tonumber(lineNum) == tonumber(info.lineNum) then
                    info.errDesc = nil
                    info.state = send_state_finished
                    break
                end
            end
        end
    end
    
    return 0, ""
end

function logManager:init()

    self:closeTrigger()
    logManager.__father.init(self, "日志管理.")
    init()
    process()
end   

return logManager