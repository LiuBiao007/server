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

function xmlToTable(s)
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

return xmlToTable