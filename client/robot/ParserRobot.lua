local sharedata = require "sharedata"
local mylog = require "base.mylog"


local escapes = {
    amp = '&',
    quot = '"',
    apos = '\'',
    gt = '>',
    lt = '<',
}

local function helper(s)
    local num = string.match(s, '^#(%d+)$')
    if num then return string.char(tonumber(num)) end
    return escapes[s]
end

local function strip_escapes(s)
    s = string.gsub(s, '&(#?[%a%d]+);', helper)
    --s = string.gsub(s, '&amp;', '&')
    return s
end

local function parseargs(s)
    local arg = {}
    string.gsub(s, "([%w_]+)%s*=%s*([\"'])(.-)%2", function (w, _, a)
        arg[strip_escapes(w)] = strip_escapes(a)
    end)
    return arg
end

local function xmlToTable(s)
    local i = 1
    local top = {}
    local stack = {top}

    while true do
        local tb,te, close,tag,xarg,empty = string.find(s, "<(%/?)(%w+)(.-)(%/?)>", i)
        if not tb then break end

        --local text = string.sub(s, i, tb - 1)
        --if not string.match(text, "^%s*$") then
            --table.insert(top, strip_escapes(text))
        --end

        if empty == "/" then  -- empty element tag
            local elem = parseargs(xarg)
            elem.tagName = tag
            table.insert(top, elem)

        elseif close == "" then   -- start tag
            top = parseargs(xarg)
            top.tagName = tag
            table.insert(stack, top)   -- new level

        else  -- End tag
            local toclose = assert(table.remove(stack))  -- remove top
            top = stack[#stack]
            if #stack < 1 then
                error("nothing to close with "..label)
            end
            if toclose.tagName ~= tag then
                error("trying to close "..toclose.tagName.." with "..tag)
            end
            table.insert(top, toclose)
        end
        i = te + 1
    end

    --local text = string.sub(s, i)
    --if not string.match(text, "^%s*$") then
        --table.insert(top, strip_escapes(text))
    --end

    if #stack > 1 then
        error("unclosed "..stack[#stack].label)
    end
    return stack[1][1]
end

function parserXmls()
  
    local tonumber = tonumber
    local file = assert(io.open("./robot/robot.xml"))
    local xmlData = xmlToTable(file:read('*a'))
    file:close()
    local data = {}
 
    for k,v in pairs(xmlData) do

        if v.tagName == "begin" then
            data.begin = {}
            local lastBeginId
            for _,item in ipairs(v) do
                local id = tonumber(item.id)
                table.insert(data.begin, id)
                lastBeginId = id
            end    
            data.lastBeginId = lastBeginId
        elseif v.tagName == "random" then
            data.random = {}
            for _,item in ipairs(v) do
                table.insert(data.random, tonumber(item.id))
            end                
        elseif v.tagName == "actor" then
            data.actor = {
                normal = {},
                param = {},
                set = {}
            }
            for _,child in ipairs(v) do  

                local id = tonumber(child.id)
                local type = tonumber(child.type)
                local input = child.input
                local arr = string.split(child.input, " ")
                local cmd = table.remove(arr,1)
                local errorcode
                for _, subChild in ipairs(child) do
                    if subChild.tagName and subChild.tagName == "errorcode" then    
                        if not errorcode then errorcode = {} end                 
                        local err = tonumber(subChild.error)
                        local ids = string.split(subChild.actorId,",")
                        if #ids > 1 then
                            local newt = {}
                            for _, newid in pairs(ids) do table.insert(newt, tonumber(newid)) end
                            errorcode[err] = newt
                        else    
                            local actorId = tonumber(subChild.actorId)
                            errorcode[err] = actorId
                       end     
                    end  
                end

                local newdata = {
                    id = id,
                    type = type,
                    input = input,
                    cmd  = cmd,
                    arr = arr,
                    errorcode = errorcode
                }  
                
                if type == 1 then--普通类
                    table.insert(data.actor.normal, newdata)
                elseif type == 2 then--param类
                    newdata.param = child.param
                    table.insert(data.actor.param, newdata)
                elseif type == 3 then--set类
                    table.insert(data.actor.set, newdata)
                else
                    error(string.format("error type %d",type))
                end      
            end 
        end     
    end  

    return data
end

return parserXmls