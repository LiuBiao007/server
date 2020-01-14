local clientsocket  = require "myclient"
local sharedata 	= require "skynet.sharedata"
local mylog 		= require "base.mylog"
local sproto 		= require "sproto"
local gameproto 	= require "protos.parser"
local cjson 		= require "cjson"
local crypt 		= require "crypt"
local websocket 	= require "http.websocket"
local skynet 		= require "skynet"
local commonconst   = require "commonconst"

local handler = {}

local type = type
local pcall = pcall
local math_floor = math.floor
local assert = assert
local cnf
local str_gsub = string.gsub
local str_format = string.format
local base64decode = crypt.base64decode
local base64encode = crypt.base64encode
cjson.encode_sparse_array(true)
function handler:new(ws)
	
	local t = {}	
	setmetatable(t, self)
	self.__index = self

	t:init(ws)
	cnf = sharedata.query("cnf")
	return t
end

function handler:init(ws)

    local fd = clientsocket.connect("127.0.0.1", cnf.watchdog.port)
    mylog.info("[WS] connect to watchdog 127.0.0.1:%s fd = %s", cnf.watchdog.port, fd)
	self.fd = fd
    self.ws = ws
	self.id = ws.id
	self.session = 0
	self.bigjsonindex = 1
	self.bigjson = {}
	self.session2cmd = {}
	self.last = ''
	self.bigdata = {}
	self.host = sproto.new(gameproto.s2c):host "package"
	self.request = self.host:attach(sproto.new(gameproto.c2s))
	skynet.fork(function () 
		while true do

			if not self.fd then break end
			self:dispatch_package()
			skynet.sleep(1)
		end	
	end)
end

function handler:getSession()
	
	self.session = self.session + 1
	return self.session
end

function handler:check(message)
	
	local fd = self.fd
	local function check(message)

		if type(message) ~= 'string' or #message <= 0 then
			
			mylog.info(str_format('fd %s message is error', fd))
			return 1
		end

		local origin = message
		local ok, data

		ok, data = pcall(cjson.decode, message)
		if not ok then
			
			mylog.info(str_format('fd %s json decode error, reason: %s', fd, string.dump(data)))
			return 1
		end
		
		local cmd = data.cmd
		local param = data.param
		local session = data.session
		if not cmd or type(cmd) ~= 'string' or type(param) ~= 'table' or type(session) ~= "number" then
			mylog.info(str_format('fd %s json format is error', fd))
			return 1
		end

		if cmd == 'entergame' or cmd == 'createcharcter' then

        	if type(param.version) ~= "string" or param.version ~= commonconst.version then
        		return GAME_VERSION_ERROR, nil, session, cmd
        	end	
    	end    

		session = math_floor(session)			
		local request = self.request

		local ok, p = pcall(request, cmd, param, session)
		if not ok then 
			return SPROTO_PARAM_ERROR, nil, session, cmd 
		end

		return 0, p, session, cmd
	end
	
	return check(message)
end

local function unpack_package(text)
    local size = #text
    if size < 2 then
        return nil, text
    end
    local s = text:byte(1) * 256 + text:byte(2)
    if size < s+2 then
        return nil, text
    end

    return text:sub(3,2+s), text:sub(3+s)
end

function handler:recv_package(last, fd)

    local result
    result, last = unpack_package(last)
    if result then
        return result, last
    end
    local r = clientsocket.recv(fd)
    if not r then
        return nil, last
    end

    if r == "" then
        local ws = self.ws
        if ws then
		
			mylog.info('[WS]=============>fd %s may be kicked', fd)
            self.on_close(ws.id, 777, 'server kick fd')
        else
            mylog.info("[WS]=============>fd %s miss ws.", fd)
        end    
    end 
    return unpack_package(last .. r)
end

function handler:send_package(data, cmd, session)

	local maxSize = 32768--59304--32768
	local len = #data
	if len <= maxSize then

		self.ws.send_text(self.ws.id, data)
	else

		if self.bigjsonindex > 2 ^ 25 then self.bigjsonindex = 1 end
		local index = self.bigjsonindex

		data = crypt.base64encode(data)
		len = #data
		self.bigjsonindex = self.bigjsonindex + 1
		local header_param = {bigdata_header =  {name = cmd, len = len, index = index, session = session}}
		local header_data = self:pcall_encodejson(header_param)
		if not header_data then return end
		self.ws.send_text(self.ws.id, header_data)
		local newMax = 10240
		local i = 0
		while len > 0 do

			local _start = 1 + newMax * i
			local _end = newMax  * (i + 1)
			local ss = data:sub(_start,_end)
			len = len - newMax
			i = i + 1
			self.ws.send_text(self.ws.id, ss)
		--end 
		end		
	end	
end

function handler:pcall_encodejson(args)

   local ok, data = pcall(cjson.encode, args)
   if not ok then
		
		mylog.info('json encode error %s', data)
		self.on_close(ws.id, 13, 'json encode err')
		return false
   end	

   return data
end	

function handler:print_response(ws, session, args)
     
   args.session = session 	
   local data = self:pcall_encodejson(args)
   if not data then return end
   --may need compress and encrypt
   self:send_package(data, self.session2cmd[session], session)
end

function handler:bigdata_header(bigdata, args)

	local name = args.name
	local index = args.index
	local len = args.len
	bigdata[index] = {
		name = name,
		len = len,
		data = "",
		index = index,
	}
end

function handler:bigdata_content(bigdata, args)

	local index = args.index
	local data = args.data
	local d = bigdata[index]
	assert(d, string.format("error bigdata index %s", index))
	d.data = d.data .. data

	if #d.data >= d.len then
		return d, index
	end    
	return nil
end    

function handler:print_request(ws, fd, name, args)
	
	local bigdata = self.bigdata
	local id = ws.id
	local host = self.host
	if name ~= 'heartbeat' then
		mylog.debug('fd %s start game event %s', fd, name)
	end	
	args = args or {}
	if name == 'bigdata_header' then
		self:bigdata_header(bigdata, args)
	elseif name == 'bigdata_content' then
		local bdata, index = self:bigdata_content(bigdata, args)
		if bdata then
			
			local type, session, v = host:dispatch(bdata.data)
			self:print_response(ws, session, v)
			bigdata[index] = nil
			mylog.info('fd %s big data process ok.', fd)
		end
	else
		local r = {}
		r[name] = args
		local data = self:pcall_encodejson(r)
		if not data then return end

		ws.send_text(ws.id, data)
	end
	if name ~= 'heartbeat' then
    	mylog.debug("fd %s end game event %s", fd, name)
    end	
end    

function handler:print_package_ex(ws, fd, t, ...)
    if t == "REQUEST" then
        self:print_request(ws, fd, ...)
    else
        self:print_response(ws, ...)
    end
end

function handler:print_package(fd, v)

	local ws = self.ws
	local fd = self.fd
	local host = self.host
	self:print_package_ex(ws, fd, host:dispatch(v))
end

function handler:dispatch_package()
	
	local fd = self.fd
	if not fd then
		return
	end
	local last = self.last
    while true do
        local v
        v, self.last = self:recv_package(self.last, fd)
        if not v then
            break
        end
		self:print_package(fd, v)
    end
end

function handler:send(p, session, cmd)
	
	local fd = self.fd
	p = string.pack('>s2', p)
	clientsocket.send(fd, p)
	assert(not self.session2cmd[session])
	self.session2cmd[session] = cmd
end

function handler:close()
	
	self.request = nil
	self.session = nil
	self.host = nil
	self.last = ''
	self.id = nil
	clientsocket.close(self.fd)
	self.ws.close(self.ws.id)
	--websocket.close(self.ws.id)
	self.ws = nil
	self.fd = nil
	self.bigdata = {}
	self.session2cmd = {}
end
return handler