local skynet = require "skynet"
require "skynet.manager"
local assert = assert
local select = select
local string = string
local table  = table
local json   = require "ext.json"

mylog        = require "base.mylog"
guidMan      = require "guid.guidMan"

require "class.import"
require "class.class"
assert(select("#", ...) > 0, string.format("param count must more then one."))
local input = {...}
local name = input[1]
local param = table.pack(select(2, ...))
assert(type(name) == "string", string.format("module name [%s] must be string type.", name))
local obj = require(name)
local object 

SERVICE_CLASS  = name

local function unserialize(lua)
    local t = type(lua)
    if t == "nil" or lua == "" then
        return nil
    elseif t == "number" or t == "string" or t == "boolean" then
        lua = tostring(lua)
    else
        error("can not unserialize a " .. t .. " type.")
    end
    lua = "return " .. lua
    local func = load(lua)
    if func == nil then
        return nil
    end
    return func()
end

function savehash(tab)
    local pack = function (ta)

        local t = {}
        for k,v in pairs(ta) do
            table.insert(t,k) 
            table.insert(t,v)
        end
        return t
    end

    return table.unpack(pack(tab))
end	

skynet.init(function ()

    local mc = 0
	local c = {}
	for i = 1, param.n do

		local p = param[i]

		if type(p) == "string" and p:match("{")  then
            
            local ok, r = pcall(json.decode, p)
            if ok then
                table.insert(c, r)
            else
                mc = mc + 1
                local s = p

                while true do
                    i = i + 1

                    local tmp = tostring(param[i])
                    s = s .. tmp             
                    if tmp:match("}") then
                        mc = mc - 1
                    elseif tmp:match("{")  then  
                        mc = mc + 1
                    end
        
                    if mc == 0 then break end
                end 
                table.insert(c, unserialize(s))
            end    
		else
			table.insert(c, p)	
		end	
	end	

    assert(type(obj) == "table" and getmetatable(obj), string.format("error obj %s.", name))
    assert(type(obj.new) == "function", string.format("error obj %s less new function.", name))

	object = obj:new(table.unpack(c))

    assert(not SERVICE_OBJECT, string.format("SERVICE_OBJECT [%s] just can be init once.", name))
    SERVICE_OBJECT = object
   
    if type(object.initTriggers) == "function" then
        object:initTriggers()
    end      
end)

skynet.start(function ()

	skynet.dispatch("lua", function (session, source, cmd, ...)

        assert(type(object.do_cmd) == "function", 
            string.format("error class %s shoud inherit serviceObject.", object.__classname)) 
        --for service debug message
        if type(object.traceMsg) == "function" then
            object:traceMsg(session, source, cmd, ...)
        end    

		return skynet.retpack(object:do_cmd(session, source, cmd, ...))
	end)
	
	skynet.register("." .. name)
	object:onServiceStarted()
    object:_gc_()
end)
