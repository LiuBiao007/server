local mylog = require "base.mylog"
local gameconst = require "const.gameconst"
require "const.activityConst"

local table_sort = table.sort
local tonumber = function (num) return assert(tonumber(num)) end
local table_insert = table.insert
local table_remove = table.remove
local string_format = string.format

local function demo(node)
    local activity = 
    {
        id = tonumber(node.id),
        name = node.name,
        desc = node.desc,
        detail = node.detail,
        time = node.time,
        type = tonumber(node.type),
        needLevel = tonumber(node.needLevel),
    }

    return activity
end
            

function parserData(xmlData, xmls)
    local activitys = {}

    for k, node in ipairs(xmlData) do
        local activity = {}

        local id = tonumber(node.id)
        if id == ACTIVITYID_DEMO1 then
            activitys[id] = demo(node)
        elseif id == ACTIVITYID_DEMO2 then
            activitys[id] = demo(node)
        else
            mylog.error("Activities.xml id[%s] data error!", node.id or -1)
            assert(false)
        end
    end
    
    return activitys
end

return parserData