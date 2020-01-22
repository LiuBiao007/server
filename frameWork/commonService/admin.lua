local skynet		 = require "skynet"
local businessObject = require "objects.businessObject"
local json			 = require "ext.json"
local cjson			 = require "cjson"
local socket 		 = require "skynet.socket"
local dynamicMan	 = require "afw.dynamicMan"
local codecache      = require "skynet.codecache"
local adminCnf       = require "const.adminCnf"
local clientsocket   = require "myclient"
local admin    		 = class("admin", businessObject)

function admin:init()

    admin.__father.init(self, "管理后台")
	self.dynamicMan = dynamicMan:new()
	self:startAdmin()
end	

function admin:startAdmin()

	local host = __cnf.admin.host
	local port = tonumber(__cnf.admin.port)
    local listen_socket = socket.listen(host, port)
    mylog.info("AdministratorService listen at %s:%d ", host, port)

    socket.start(listen_socket , function(fd, addr)
        socket.start(fd)
        skynet.fork(self.admin_main_loop, self, fd, addr)
    end)
end	

function admin:getActivityById(id)

    return self.dynamicMan:getDynamicActivityById(id)
end    

function admin:removeActivityId(id)

    self.dynamicMan:removeDynamicId(id)
end    

function admin:admin_main_loop(fd, addr)

    mylog.info("AdministratorService new client from %s:%s", fd, addr)

    local ok, msg = xpcall(function()
        while true do
            local msg = socket.readline(fd, "\n")
            if not msg then
                break
            end
            if msg ~= "" then
                self:protocolSkip(fd, msg)
            end
        end
    end, debug.traceback)
    if  not ok then mylog.info(string.dump(msg)) end
    mylog.info("AdministratorService disconnect %s:%s", fd, addr)

    socket.close(fd)
end	

local function recvFromConsole(fd)

    local out = ""
    while true do

        local r = clientsocket.recv(fd)
        if r then
            out = out .. r
            if out:find("<CMD OK>") then
                break
            elseif out:find("<CMD Error>") then
                break
            end    
        end
        if r == "" then 
            mylog.info("admin server shut down.")
            break
        end    
        skynet.sleep(10)
    end
    return out
end    
--记得做权限鉴定
function admin:protocolSkip(fd, msg)

    local results = {errorcode = 0, errDesc = ""}

    if type(msg) == "string" and #msg > 0 then
        
        local data = msg:split(" ")
        local protocolName = table.remove(data, 1)
        mylog.info("admin protocol:%s", protocolName or "")
        if type(self.dynamicMan[protocolName]) == "function" then

        	 local err, errDesc, result = self.dynamicMan[protocolName](self.dynamicMan, data)
             results = {errorcode = err, errDesc = errDesc and errDesc or "", results = result}
        elseif protocolName == "debug" then--函数级热更新
--1.放补丁到patch目录
--2.原文件同步修改
            local patchFile = ""
            local r = {}
            local mode = data[1]
            if mode == "agent" then

                codecache.clear()
                r = self:call("conn.connMan", "getAllAgent")
                patchFile = data[2]
            elseif mode == "activity" then
                
                local activityId = tonumber(data[2])    
                local s = self:getActivityById(activityId)
                if s then

                    codecache.clear()
                    table.insert(r, s)
                else

                    local cnf = assert(ACTIVITY_CONFIG[activityId], 
                        string.format("error activityId %s.", activityId))
                    if cnf.type == ACTIVITYTYPE_PLAYER then
                        r = self:call("conn.connMan", "getAllAgent")
                    else

                        local uniqueService = require "services.uniqueService"
                        local s = uniqueService(string.format("activity.%s", cnf.name))
                        table.insert(r, s)
                    end    
                end   
                patchFile = data[3] 
            else
                local uniqueService = require "services.uniqueService"
                local s = uniqueService(data[2])
                table.insert(r, s)
                patchFile = data[3]
            end    

            if #r == 0 then
                results = {errorcode = 0, errDesc = "未找到服务."}
            else

                if #patchFile <= 0 then
                    results = {errorcode = 0, errDesc = "请正确输入补丁文件."}
                else

                    if not patchFile:find("%.lua") then
                        patchFile = patchFile .. ".lua"
                    end    

                    patchFile = string.format("./patch/%s", patchFile)
                    local fd = clientsocket.connect("127.0.0.1", __cnf.debug_port)
                   -- recvFromConsole(fd)

                    for _, s in pairs(r) do

                        local p = string.format("inject :%08x %s\n", s, patchFile)
                        clientsocket.send(fd, p)
                        mylog.info(p)
                        local out = recvFromConsole(fd)
                        mylog.info(out)
                    end    
                    clientsocket.close(fd)
                    results = {errorcode = 0, errDesc = "执行完成."}                          
                end               
            end    
        else    

            local mailModule    = "mail.mailCenter"
            local logModule     = "commonService.logManager"
            local rewardModule  = "commonService.globalReward"

            local map = {
                --邮件
                sendSystemMail               = mailModule,

                --全服补偿
                insertGlobalReward           = rewardModule,
                deleteGlobalReward           = rewardModule,
                getCurMaxRewardId            = rewardModule,

                -- 日志转移工具
                removeLog                    = logModule,
                getServerInfo                = logModule,
                getPackLogRecords            = logModule,
                getServerAndLogInfo          = logModule,
                setLogErrorState             = logModule,
            }

            for cmd, module in pairs(adminCnf) do

                assert(not map[cmd], string.format("error cmd %s.", cmd))
                map[cmd] = module
            end    

            if map[protocolName] then
                local err, errDesc, result  = self:call(map[protocolName], protocolName, data)
                results = {errorcode = err, errDesc = errDesc or "", results = result}
            else    
        	   results = {errorcode = errorcode.admin_protocol_not_exist, errDesc = "admin protocol not exist!"}
            end
        end	

    else
        results = {errorcode = errorcode.admin_param_error, errDesc = "admin protocol params error!"}
    end

    socket.write(fd, cjson.encode(results) .. "\n")
end	

function admin:isProxyFullData(playerId)

    return self.playerMan:isFullData(playerId)
end    

function admin:isPlayerLoadOrInGame(playerId)

    local player = self.playerMan:getPlayerById(playerId)
    if player and (player.state == PLAYER_STATE_LOADING or player.state == PLAYER_STATE_INGAME) then
        return player.agent
    end    
    return false
end    

function admin:proxyBroadcast(cmd, ...)

    self.playerMan:broadcast(cmd, ...)
end    
return admin