local mylog = require "base.mylog"
local function demo(node)
    local config = {
        id                  = node.id,
        icon                = node.icon,
        name                = node.name,
        desc                = node.desc,
        time                = node.time,
        type                = 4,
        needLevel           = node.needLevel,
    }
    return config
end    

function parserData(xmlData, xmls)
    local activitys = {}

    for k, node in ipairs(xmlData) do
        local activity = {}
        local id = tonumber(node.id)
        if id == ACTIVITYID_DEMO4 then
            activitys[id] = demo(node)
        else
            mylog.error("Activities.xml id[%s] data error!", node.id or -1)
            assert(false)
        end
    end
    
    return activitys
end

return parserData