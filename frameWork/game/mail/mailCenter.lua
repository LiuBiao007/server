local skynet        = require "skynet"
require "skynet.manager"
local type          = type
local assert        = assert
local string_gsub   = string.gsub
local string_format = string.format
local db            = require "coredb.query"
local businessObject = require "objects.businessObject"
local mailCenter    = class("mailCenter", businessObject)

local sendMaxCountByPlayerId = {} -- 当天玩家发送邮件上限
local lastCheckTime = os.getCurTime()
local function processExpireMails()

    local curTime = os.getCurTime()
    -- 已读且无附件(2天)
    local expireTime = os.dateTimeToString(curTime - (2 * 24 * 3600))
    db:name('mail'):where('type', 0):where('state', 1):where('createTime', '<', expireTime):delete()

    -- 未读且无附件(3天)
    expireTime = os.dateTimeToString(curTime - (3 * 24 * 3600))
    db:name('mail'):where('type', 0):where('createTime', '<', expireTime):delete()

    -- 已领取附件(3天)
    expireTime = os.dateTimeToString(curTime - (3 * 24 * 3600))
    db:name('mail'):where('type', 1):where('state', 2):where('createTime', '<', expireTime):delete()

    -- 未领取附件(7天)
    expireTime = os.dateTimeToString(curTime - (7 * 24 * 3600))
    db:name('mail'):where('type', 1):where('createTime', '<', expireTime):delete()
end

function mailCenter:init()

    mailCenter.__father.init(self, "邮件服务")

    processExpireMails()

    skynet.fork(function ()
        while true do
     
            local now = os.getCurTime()
            if os.getSameDayEndTime(now, 0) ~= os.getSameDayEndTime(lastCheckTime, 0) then
                lastCheckTime = now
                sendMaxCountByPlayerId = {}
            end

            skynet.sleep(600) -- 十分钟
        end 
    end)    

    return self
end    

function mailCenter:sendSystemMailEx(sourceType, senderName, receiverId, title, content, attaches)
    local mail = {
        id          = guidMan.createGuid(gameconst.serialtype.mail_guid),
        type        = attaches and (#attaches > 0 and 1 or 0) or 0,    -- 0:消息邮件  1:奖励邮件
        senderId    = "0",
        senderName  = senderName,
        receiverId  = receiverId,
        state       = 0,           -- 0:未读  1:已读
        sourceType  = sourceType,
        title       = string_gsub(title, "'", "\""),
        content     = string_gsub(content, "'", "\""),
        createTime  = os.getCurTime(),
        attaches    = attaches,
    }

    local o = self.playerMan:sendEvent(receiverId, "insertMail", mail)
    if o then--process outline logic
       o:name("mail"):set(mail)
    end
    if mail.type == 1 then
        mylog.info("sendSystemMail mailId:%s sourceType:%d content:%s receiverId:%s attaches:%s", mail.id, sourceType, content, receiverId, attaches)
    end

    return 0
end
                        
function mailCenter:sendSystemMail(params)

    if type(params) ~= "table" or #params < 4 then
        return errorcode.param_error
    end

    local senderName = #params[1] > 0 and params[1] or "system"
    local receiverId = params[2]
    local title = params[3]
    local content = params[4]
    local attaches = params[5] or ""

    local isExist = tool.isExistPlayerId(receiverId, redisdb)
    if not isExist then
        return errorcode.user_login_nochar
    end

    -- 检测邮件标题长度是否合法
    if #title < 4 or #title > 32 then
        return errorcode.mail_title_length_error
    end

    -- 检测邮件内容长度是否合法
    if #content < 4 or #content > 1024 then
        return errorcode.mail_content_length_error
    end

    -- 默认消息邮件
    if attaches and #attaches > 0 then
        local err = tool.checkMailAttaches(attaches, errorcode, gameconst, xmls)
        if err ~= 0 then
            return err
        end
    end
 
    self:sendSystemMailEx(gameconst.mailSourceType.system, senderName, receiverId, title, content, attaches)

    return 0
end

function mailCenter:sendMsgMail(senderId, senderName, receiverId, title, content)

    senderId = tostring(senderId)
    if sendMaxCountByPlayerId[senderId] then
    	if sendMaxCountByPlayerId[senderId] > 30 then
    		return errorcode.mail_send_max_count_error
    	end
    	sendMaxCountByPlayerId[senderId] = sendMaxCountByPlayerId[senderId] + 1
    else
    	sendMaxCountByPlayerId[senderId] = 1
	end

	local mail = {
        id          = _guidMan:createguid(gameconst.serialtype.mail_guid),
        type        = 0,    -- 0:消息邮件  1:奖励邮件
        senderId    = senderId,
        senderName  = senderName,
        receiverId  = receiverId,
        state       = 0,    -- 0:未读  1:已读
        sourceType	= 0,	-- 0:玩家
        title       = string_gsub(title, "'", "\""),
        content     = string_gsub(content, "'", "\""),
        createTime  = tool.getCurTime(),
        attaches    = "",
    }


end

return mailCenter