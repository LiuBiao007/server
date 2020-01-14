local skynet            = require "skynet"
require "skynet.manager"
local sharedata         = require "sharedata"
local cjson             = require "cjson"
local socket            = require "socket"
local websocket         = require "http.websocket"
local str_format        = string.format
local agentconn         = require "websocket.agentconn"
local serviceObject     = require "objects.serviceObject"
local wsserver          = class("wsserver", serviceObject)

SPROTO_PARAM_ERROR = 999
GAME_VERSION_ERROR = 998

local mf = math.floor
cjson.encode_sparse_array(true)
function wsserver:init(maxQuene, port)
    local maxQuene = maxQuene or 512
    wsserver.__father.init(self, maxQuene)
    --关闭消息锁
    self:closeLock()
    --关闭redis写入
    self:closeSyncToRedis()

    self.port   = tonumber(port)
    self.conns  = {}
    self.all_ws = {}

    local address = string.format("0.0.0.0:%s", port)
    mylog.info("websocket listening on ".. address)
    local id = assert(socket.listen("0.0.0.0", port))
    socket.start(id , function(id, addr)

        mylog.info("socket start id = %s addr = %s", id, addr)
        local protocol = skynet.getenv "protocol"
        assert(protocol == "ws" or protocol == "wss")
        websocket.accept(id, wsserver, protocol)
    end)    
    return self
end    

function wsserver:getconn(ws)

    return self.conns[ws.id]
end    

function wsserver:gen_ws(id)

    local ws = self.all_ws[id]
    if not ws then

        ws =  {
            id = id,
            close = function (...) handler.close(...) end,
            send_text = function (...) websocket.write(...) end,
        }
        self.all_ws[id] = ws
    end    
    return ws
end    

function wsserver.connect(id)
    mylog.info("ws connect from: " .. tostring(id))
    local ws = self:gen_ws(id)
    local conn = agentconn:new(ws)
    conn.on_close = wsserver.close
    self.conns[conn.id] = conn
    mylog.info("websocket on open connid = %s conn = %s", conn.id, conn)    
end

function wsserver.handshake(id, header)
    mylog.info("ws handshake from: " .. tostring(id))
    --mylog.info("header ====> %s", tool.dump(header))  
end

function wsserver.message(id, message)

    local ws = self:gen_ws(id)
    mylog.info("[WS] on_message ws.id:%s message:%s", ws.id, message)
    local conn = self:getconn(ws)    
    if not conn then

        mylog.info("ws id %s may be close before", ws.id)
        wsserver.close(ws, 21, 'ws may be close before')
        return 
    end    

    local err, p, session, cmd = conn:check(message)    
    if err == SPROTO_PARAM_ERROR then
        
        conn:print_response(self, session, {errorcode = errorcode.param_error})
        return
    end   

    if err == GAME_VERSION_ERROR then
        conn:print_response(self, session, {errorcode = errorcode.server_version_error})
        return
    end    

    if err ~= 0 then
        
        mylog.info(str_format('fd %s may be kicked', fd))
        wsserver.close(ws, 11, 'error happen')    
        return 
    end
    
    conn:send(p, session, cmd)    
end

function wsserver.ping(id)
    mylog.info("ws ping from: " .. tostring(id) .. "\n")
end

function wsserver.pong(id)
    mylog.info("ws pong from: " .. tostring(id))
end

function wsserver.close(id, code, reason)
    if not self.conns[id] then 
        return 
    end
    mylog.info("start ws close from: " .. tostring(id), code, reason)
    websocket.close(id, code, reason)
    local ws = self:gen_ws(id)
    local conn = self:getconn(ws)
    self.conns[ws.id] = nil    
    self.all_ws[id] = nil    
    if conn then
        conn:close()        
    end

    mylog.info("end ws close from: " .. tostring(id), code, reason)
end

function wsserver.error(id)
    mylog.info("ws error from: " .. tostring(id))
    wsserver.close(id, "1003", "websocket error")
end

function wsserver:close_server()
    
    mylog.info("web service start close...")    
    for id, conn in pairs(conns) do

        conn:close()
    end    

    self.conns = {}
    self.all_ws = {}
    mylog.info("web service has closed.")
end

function wsserver:exit()

    skynet.exit()
end    

return wsserver
