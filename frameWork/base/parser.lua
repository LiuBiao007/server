local sharedata = require "skynet.sharedata"
local mylog = require "base.mylog"
local xmlToTable = require "base.xmlParser"

function parserXmls(filePath, settingsConfig)
    local checkHash = {}

    xmls = {}
    for _, cfg in ipairs(settingsConfig) do
        local key = assert(cfg.key)
        local loader = assert(cfg.parserFile)
        local fileName = assert(cfg.fileName)

        if checkHash[key] then
            mylog.error("sharedata key[%s] repetition", key)
        end

        checkHash[key] = true
        mylog.info("load parser %s", fileName)
        local file = assert(io.open(filePath .. fileName))
        local xmlData = xmlToTable(file:read('*a'))
        file:close()

        local data = loader(xmlData, xmls)
        xmls[key] = data
    end
    return xmls
end

return parserXmls