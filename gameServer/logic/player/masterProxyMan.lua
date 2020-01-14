local masterProxy    = require "commonService.masterProxy"
local masterProxyMan = class("masterProxyMan", masterProxy)

--重新连接上跨服后的处理
function masterProxyMan:reconnectMasterBroadEx()

end

--可以增加一些跨服的事件处理接口

return masterProxyMan
