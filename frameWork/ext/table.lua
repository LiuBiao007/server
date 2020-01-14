local string_format = string.format
local pairs = pairs
   
--复制对象可以带元表
function table.clone(t)

    local hash = {}
    local function _clone(obj)

        if type(obj) ~= "table" then
            return obj
        elseif hash[obj] then
            return hash[obj]    
        end 
        local newObj = {}
        hash[obj] = newObj
        for k, v in pairs(obj) do
            newObj[_clone(k)] = _clone(v)
        end 

        return setmetatable(newObj, getmetatable(obj))
    end 

    local t  = _clone(obj)
    print("t = ", t)
    return t
end    

--复制对象不带元表
function table.copy(t)

    local function clone(t, lookup)

        if type(t) ~= "table" then
            return t
        elseif lookup[t] then
            return lookup[t]
        end
        local n = {}
        lookup[t] = n
        for key, value in pairs(t) do
            n[clone(key, lookup)] = clone(value, lookup)
        end
        return n      
    end    
    local lookup = {}
    return clone(t, lookup)
end

function table.random(arr2, num)

    assert(type(arr2) == "table")
    assert(type(num) == "number" and num >= 1)
    local arr = table.copy(arr2)
    if num >= #arr then
        return arr
    end 
    --math.randomseed(os.time())
    local targets = {}
    while #targets < num do
        local index = math.myrand(#arr)
        local item = table.remove(arr, index)
        table.insert(targets, item)
    end 
    return targets
end 

function table.keys(hashtable)
    local keys = {}
    for k, v in pairs(hashtable) do
        keys[#keys + 1] = k
    end
    return keys
end

function table.values(hashtable)
    local values = {}
    for k, v in pairs(hashtable) do
        values[#values + 1] = v
    end
    return values
end

function table.merge(dest, src)
    for k, v in pairs(src) do
        dest[k] = v
    end
end

function table.map(t, fn)
    local n = {}
    for k, v in pairs(t) do
        n[k] = fn(v, k)
    end
    return n
end

function table.walk(t, fn)
    for k,v in pairs(t) do
        fn(v, k)
    end
end

function table.filter(t, fn)
    local n = {}
    for k, v in pairs(t) do
        if fn(v, k) then
            n[k] = v
        end
    end
    return n
end

function table.length(t)
    local count = 0
    for _, __ in pairs(t) do
        count = count + 1
    end
    return count
end

function table.readonly(t, name)
    name = name or "table"
    setmetatable(t, {
        __newindex = function()
            error(string_format("<%s:%s> is readonly table", name, tostring(t)))
        end,
        __index = function(_, key)
            error(string_format("<%s:%s> not found key: %s", name, tostring(t), key))
        end
    })
    return t
end
