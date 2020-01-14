local skynet	= require "skynet"
local md5 		= require "md5"
local sharedata	= require "skynet.sharedata"
local XMLParser = require "base.parser"
local mylog		= mylog
local codecache = require "skynet.codecache"

local string_gsub = string.gsub
local path = "../common/xmls/"
local md52file 	= {}
local serverStop = false
local function trim(s)

    return string_gsub(s, "^%s*(.-)%s*$", "%1")
end

local function getFileMd5(name)

	local filename = path .. name .. ".xml"
	local f = assert(io.open(filename))
	local source = f:read "*a"
	f:close()
	return md5.sumhexa(source)
end	

local function hotUpdateXml()

	--关闭缓存
	codecache.clear()
	--更新文件
	sharedata.update("XMLCONFIG", XMLParser(path))
end	

local function collectFilesMd5(func)

	local needHotUpdate = false
	local list = io.popen("ls " .. path):read("*all")
	list:gsub("(.-).xml", function (name)
		
		if serverStop then return end
		name = trim(name)
		if not md52file[name] then
			md52file[name] = getFileMd5(name)
		else
			
			local before = 	md52file[name]
			local after	 =  getFileMd5(name)
			if before ~= after then
				needHotUpdate = true
				mylog.info("%s xml file has changed.", name)
			end	
			md52file[name] = after
		end	
	end)

	if needHotUpdate and type(func) == "function" then

		mylog.info("start xml hot update...")
		func()
		mylog.info("end xml hot update...")
	end	
end	

local serviceObject = require "objects.serviceObject"
local monitorXml 	= class("commonService.monitorXml", serviceObject)
function monitorXml:init()

	monitorXml.__father.init(self, 4)
	self:closeLock()
	self:closeSyncToRedis()
	collectFilesMd5()

	skynet.fork(function ()

		while not serverStop do

			skynet.sleep(1000)
			collectFilesMd5(hotUpdateXml)
		end	
	end)	
end

function monitorXml:shut()

	serverStop = true
	return true
end	

return monitorXml
