local string_gsub   = string.gsub
local table_insert  = table.insert

function string.trim(s, char)
    if io.empty(char) then
        return (string_gsub(s, "^%s*(.-)%s*$", "%1"))
    end
    return (string_gsub(s, "^".. char .."*(.-)".. char .."*$", "%1"))
end


function string.ltrim(s, char)
    if io.empty(char) then
        return (string_gsub(s, "^%s*(.-)$", "%1"))
    end
    return (string_gsub(s, "^".. char .."*(.-)$", "%1"))
end


function string.rtrim(s, char)
    if io.empty(char) then
        return (string_gsub(s, "^(.-)%s*$", "%1"))
    end
    return (string_gsub(s, "^(.-)".. char .."*$", "%1"))
end

function string.split(dest, sep)


    local rt= {}
    --
    string_gsub(dest, '[^'..sep..']+', function(w)
        table_insert(rt, string.trim(w))
    end)

    return rt
end

function string.invalid(str, maxLen)

    return type(str) ~= "string" or #str <= 0  
            or str:match("['|-|\\|\"|,|;|:|%s]") 
            or (type(maxLen) == "number" and maxLen > 0 and #str > maxLen)
end    

function string.serialize(obj, lvl, isFeed)
    local lua = ""
    local feed1 = isFeed and "{" or "{\n"
    local feed2 = isFeed and "," or ",\n"
    local t = type(obj)
    if t == "number" then
        lua = lua .. obj
    elseif t == "boolean" then
        lua = lua .. tostring(obj)
    elseif t == "string" then
        lua = lua .. string.format("%q", obj)
    elseif t == "table" then
        lvl = lvl or 0
        local lvls = ('  '):rep(lvl)
        local lvls2 = ('  '):rep(lvl + 1)
        lua = lua .. feed1
        for k, v in pairs(obj) do
            lua = lua .. lvls2
            lua = lua .. "[" .. string.serialize(k, lvl + 1) .. "]=" .. string.serialize(v, lvl + 1) .. feed2
        end
        local metatable = getmetatable(obj)
        if metatable and type(metatable.__index) == "table" then
        for k, v in pairs(metatable.__index) do
            lua = lua .. "[" .. string.serialize(k, lvl + 1) .. "]=" .. string.serialize(v, lvl + 1) .. feed2
        end
    end
        lua = lua .. lvls
        lua = lua .. "}"
    elseif t == "nil" then
        return
    elseif t == "function" then
        return      
    else
        error("can not serialize a " .. t .. " type.")
    end
    return lua
end

function string.dump(obj)
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