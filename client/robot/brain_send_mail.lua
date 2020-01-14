local gameconst = require "const.gameconst"
local handler = {}

function handler.sendMsgMail(actor, send)
    local playerIds = {}
    if actor.player.fameHallTopRanks then
        local fameHallTopRanks = actor.player.fameHallTopRanks
        for _, topRanks in pairs(fameHallTopRanks or {}) do
            for _, info in pairs(topRanks) do
                table.insert(playerIds, info.playerId)
            end
        end
    end

    local playerId = #playerIds > 0 and playerIds[math.myrand(#playerIds)] or actor.player.guid
    local title = actor.player.name .. "的邮件"
    local content = actor.player.name .. "发送的邮件"

    send({playerId, title, content})
end

function handler.readMail(actor, send)
    local mailIds = {}
    for mailId, _ in pairs(actor.player.mails or {}) do
        table.insert(mailIds, mailId)
    end

    local mailId = #mailIds > 0 and mailIds[math.myrand(#mailIds)] or actor.player.guid

    send({mailId})
end

function handler.takeMailBonuses(actor, send)
    local mailIds = {}
    for mailId, _ in pairs(actor.player.mails or {}) do
        table.insert(mailIds, mailId)
    end

    local mailId = #mailIds > 0 and mailIds[math.myrand(#mailIds)] or actor.player.guid

    send({mailId})
end

function handler.deleteMail(actor, send)
    local mailIds = {}
    for mailId, _ in pairs(actor.player.mails or {}) do
        table.insert(mailIds, mailId)
    end

    local mailId = #mailIds > 0 and mailIds[math.myrand(#mailIds)] or actor.player.guid

    send({mailId})
end

return handler