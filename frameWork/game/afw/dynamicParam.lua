local skynet		= require "skynet"
local fieldObject 	= require "objects.fieldObject"
local cjson 	 	= require "cjson"
local dynamicParam = class("dynamicParam", fieldObject)

function dynamicParam:init()

	dynamicParam.__father.init(self, 'dynamicactivityparams', true)	
end

function dynamicParam:packet()

	local param = self
    local d = param.segmentsPerDay
    return {
        id              = param.id,
        name            = param.name,
        icon            = param.icon,
        desc            = param.desc,
        detail          = param.detail,
        needLevel       = param.needLevel,
        sortIndex       = param.sortIndex,
        startTime       = param.startTime,
        endTime         = param.endTime,
        segmentsPerWeek = param.segmentsPerWeek[1] .. "-" .. param.segmentsPerWeek[2],
        segmentsPerDay  = string.gsub(string.format("%2s:%2s-%2s:%2s", d[1][1], d[1][2], d[2][1], d[2][2]), " ", "0"),
        clasz           = param.clasz,
        data            = cjson.encode(param.data),
        state           = param.state,
        updateTime      = param.updateTime,
    }
end	

return dynamicParam	
