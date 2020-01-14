local handler = {}
local brain_send_player = require "robot.brain_send_player"
local brain_send_item = require "robot.brain_send_item"
local brain_send_mail = require "robot.brain_send_mail"
local brain_send_activity = require "robot.brain_send_activity"
local brain_send_dynamicActivity = require "robot.brain_send_dynamicActivity"


local function constructHandler(protos)

	for name, func in pairs(protos) do
		assert(not handler[name], string.format("error name %s", name))
		handler[name] = func
	end	
end	


constructHandler(brain_send_player)
constructHandler(brain_send_item)
constructHandler(brain_send_mail)
constructHandler(brain_send_activity)
constructHandler(brain_send_dynamicActivity)

return handler