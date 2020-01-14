local skynet 		 = require "skynet"
local urllib 		 = require "http.url"
local cjson 		 = require "cjson"
local db 			 = require "coredb.query"
local savedb 		 = require "dbs.savedb"
local serviceTrigger = require "base.serviceTrigger"
local logMan 		 = require "log.logMan"
local businessObject = require "objects.businessObject"
local httpServer	 = require "http.httpServer"
local pay    		 = class("pay", businessObject)

local serverOrderHash = {}

function pay:getOrder(order)

	local o = serverOrderHash[order]
	if not o then  
		o = db:name('serverorder'):where('guid', order):find()
		if o then serverOrderHash[order] = o end
		return o
	end
	return o
end	

function pay:getOrderByPlatorder(order)

	local o = platOrderHash[order]
	if not o then return db:name('serverorder'):where('bid', order):find() end
	return o	
end	

function pay:payForGame(path, query, body)

	local code = 200
	local q = urllib.parse_query(body)
	mylog.info(body)
	if path == "/getAppleInfo" then--ios
		
		local order = self:getOrder(q.appleServerOrderId)
		if not order then
			return 1000--no order
		end	

		return code, cjson.encode({ret = {userid = order.userid, name = order.name, 
										  goodsId = order.goodsId, bid = order.bid
										  ,product_id = order.product_id, serverid = order.serverid}})

	elseif path == '/generateServerOrder' then

		local err = cjson.encode({err_code = -1, desc = '参数解析错误'})
		if not q.playerId then
			mylog.info("playerId is nil")
			return code, err
		end				

		local s = self:getPlayerInfoById(q.playerId)
		if not s then
			return code, cjson.encode({err_code = -2, desc = "角色ID错误"})
		end	

		local guid = self:generateServerOrder(s.userid, s.serverid, s.name, q.playerId, math.floor(q.goodsId), 
				q.bid, q.product_id,q.bid)

		return code, cjson.encode({err_code = 0, desc = guid})

	elseif path == '/getOrderByPlatorder' then	

		local order = self:getOrderByPlatorder(q.orderId)
		if not order then
			return code, cjson.encode({err_code = -1, desc = '订单不存在'})--no order
		end		

		local s = self:getPlayerInfoById(q.playerId)
		if not s then
			return code, cjson.encode({err_code = -2, desc = "角色ID错误"})
		end	

		return code, cjson.encode({err_code = 0, order = order, userid = s.userid})			
	else	

		if header.host then
			mylog.info('来自%s的充值',header.host)
		end				
		
		local ret = self:processPay(q)

		return code, string.format('%s', ret)
	end		
end	

function pay:processPay(q)

	--userid serverID是否存在
	if not q.userid or not q.serverid then return 6 end
	mylog.info('[1-------PAY] userid %s serverid %s', q.userid, q.serverid)
	if not self:call("player.userCenter", "checkUserExist", q.userid, q.serverid) then
		return 1
	end	

	mylog.info('[2-------PAY] userid %s serverid %s serverOrder %s', q.userid, q.serverid, q.serverOrder)
	--服务订单是否有效
	local order = self:getOrder(q.serverOrder)
	if not order then
		return 2
	end	

	mylog.info('[3-------PAY] userid %s serverid %s serverOrder %s', q.userid, q.serverid, q.serverOrder)
	if order.state == serverOrder_state_over then 
		return 3
	end	

	mylog.info('[4-------PAY] userid %s serverid %s serverOrder %s', q.userid, q.serverid, q.serverOrder)
	if order.userid ~= q.userid or q.serverid ~= q.serverid then
		return 4
	end	

	local stone 	 = tonumber(q.stone)
	local guid 		 = ret.guid
	local money 	 = tonumber(q.money)
	local chargeType = tonumber(q.chargeType)
	local chargegold = tonumber(q.chargegold)

    local o = self.playerMan:sendEvent(guid, "payIngot", stone, money, chargeType, chargegold, q.serverOrder, q.platform, q.serverid)
    if o then--process outline logic
    	mylog.info('[5-------PAY] guid %s 进入离线充值', guid)
		local function getNewVip(vipLevel, vipExp, addVipExp)

			local obj = {vipLevel = vipLevel, vipExp = vipExp}
			tool.addExp(obj, addVipExp, xmls.vip.levelUp, {level = "vipLevel", exp = "vipExp"})
			newVipLevel = obj.vipLevel
			newVipExp = obj.vipExp

			return newVipLevel, newVipExp
		end	

		o = o:name("player"):pk(playerId)
		local totalCharge = o:get("totalCharge")
		o:expr({{"ingot","+",ingot}, {"totalCharge", "+", money}, {"chargeNum", "+", 1}})
		local newVipLevel, newVipExp = getNewVip(o:get("vipLevel"), o:get("vipExp"), addVipExp)
		o:set({vipExp = newVipExp, vipLevel = newVipLevel})
		if totalCharge <= 0 then

			o:set({firstChargeLevel = o:get("official"), firstChargeTime = os.getCurTime()})
		end	
		
		serviceTrigger.send("onPayMoney", playerId, money, ingot, chargeType, chargegold)
	  
		logMan:new(playerId, "outlinePayIngot", platform, serverid):log(LOG_OP_BIGTYPE_PAY,{money, chargegold, ingot, chargeNum},{serverOrder})
	  	logMan:new(playerId, "outlinePayIngot", platform, serverid):log(LOG_OP_BIGTYPE_GETSTONE,{beforeingot, afteringot})
		mylog.info('结束玩家%s的离线充值 ingot:%s platform:%s', playerId, ingot, platform)		
    else
    	mylog.info('[5-------PAY] guid %s 进入在线充值', guid)   
    end
	
	local _data = serverOrderHash[q.serverOrder]
	if _data then
	
		serverOrderHash[q.serverOrder] = nil
		db:name('serverorder'):where('guid', q.serverOrder):delete()
	else

		platOrderHash[q.orderId] = nil
		db:name('serverorder'):where('bid', q.orderId):delete()
	end	
	mylog.info('[7-------PAY] userid %s serverid %s serverOrder %s 充值成功', q.userid, q.serverid, q.serverOrder)
	return 0
end	

function pay:init()

    pay.__father.init(self, "充值服务")
    httpServer(__cnf.payPort, self.payForGame, self)
end

return pay