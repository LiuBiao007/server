
local t =  loadfile("./test7.lua") --require("test7", 99)

local z = t(99)
z.a()
print("test 8 start")



print(string.gsub("a.b.c", "%.", "/"))
function dump(obj)
    local getIndent, quoteStr, wrapKey, wrapVal, dumpObj
    getIndent = function(level)
        return string.rep("\t", level)
    end
    quoteStr = function(str)
        return '"' .. string.gsub(str, '"', '\\"') .. '"'
    end
    wrapKey = function(val)
        if type(val) == "number" then
            return "[" .. val .. "]"
        elseif type(val) == "string" then
            return "[" .. quoteStr(val) .. "]"
        else
            return "[" .. tostring(val) .. "]"
        end
    end
    wrapVal = function(val, level)
        if type(val) == "table" then
            return dumpObj(val, level)
        elseif type(val) == "number" then
            return val
        elseif type(val) == "string" then
            return quoteStr(val)
        else
            return tostring(val)
        end
    end
    dumpObj = function(obj, level)
        if type(obj) ~= "table" then
            return wrapVal(obj)
        end
        level = level + 1
        local tokens = {}
        tokens[#tokens + 1] = "{"
        for k, v in pairs(obj) do
            tokens[#tokens + 1] = getIndent(level) .. wrapKey(k) .. " = " .. wrapVal(v, level) .. ","
        end
        tokens[#tokens + 1] = getIndent(level - 1) .. "}"
        return table.concat(tokens, "\n")
    end
    return dumpObj(obj, 0)
end

local a = "2019-12-03&nbsp;11:00:00"
local b = "2019-12-30&nbsp;12:00:00"

local year,month,day,hour,min,sec = a:match("(%d+)%-(%d+)%-(%d+)&nbsp;(%d+):(%d+):(%d+)")

print(year,month,day,hour,min,sec)

for i = 1,12 do
	print(dump(os.date("*t", os.time()+86400 * (i - 1) * 30).month))
end


