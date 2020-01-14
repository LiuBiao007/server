local mail = require "mail.mail"
local mailMan = class("mailMan")

local push  = table.insert
local mails = {}
function mailMan:init(player)

    -- 邮箱
    player.loadGameDataSuccess:attach(self.onDataLoaded, self)

    --for test
    player.onSendPlayerData:attach(self.sendEnterData, self)
    self.player = player
    return self
end

function mailMan:sendEnterData(player, result)

    local data = {}    
    for _, mail in pairs(mails) do

        data[mail.id] = mail
    end    
    result.mails = data
end
local timer = require "commonService.timer"
function mailMan:onDataLoaded(data, player)

    local items = data.mail
    for _, item in pairs(items or {}) do

        local inst = mail:load(item)
        self:attachMail(inst)
        if inst.type == 0 and inst.state == 0 then player.unreadMails = player.unreadMails + 1 end
        if inst.type == 1 and inst.state ~= 2 then player.unreadMails = player.unreadMails + 1 end
    end   
end    

function mailMan:getMails()
    return mails
end

function mailMan:getMailById(id)
    return mails[id]
end

function mailMan:checkDeleteMail(mail)
    if mail:needDelete() then
        mail:setPreDelete()
        timer.onceTimer(mail, mail.delete, "createTime", 24*60*60) 
    end 
end    

function mailMan:attachMail(mail)

    assert(not mails[mail.id])
    mail.man = self
    mails[mail.id] = mail
    self:checkDeleteMail(mail)  
end

function mailMan:removeMail(mail)
    
    self:detachMail(mail)
    mail:delete()
end

function mailMan:detachMail(mail)

    mails[mail.id] = nil
end    

function mailMan:insertMail(item)

    local m = mail:create(item)
    self:attachMail(m)
    self.player:sendUnreadMailsEvent(1)
end

function mailMan:updateMailState(mail)
    mails[mail.id] = mail
    self:checkDeleteMail(mail) 
end

return mailMan