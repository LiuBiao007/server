local skynet 			= require "skynet"
local math_randomseed   = math.randomseed
local math_random       = math.random

local randomseed = 1
function math.myrand(min, max)

    assert(min)
    randomseed = randomseed + 10000
    if randomseed > 2^30 then
        randomseed = 1
    end

    math_randomseed(skynet.time()+ randomseed)
    if max then
        return math_random(min, max)
    else
        return math_random(min)
    end    
end	

function math.randarr(num, arr2)

    if num >= #arr2 then
        return arr2
    end 
    local arr = {}
    for k, v in pairs(arr2) do table.insert(arr, v) end
    local targets = {}
    while #targets < num do
        local item = table.remove(arr, tools.random(#arr))
        table.insert(targets, item)
    end 
    return targets
end 

function math.tonumber(num)

    return assert(tonumber(num), string.format("error num %s.", num))
end    
