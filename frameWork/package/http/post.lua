local skynet = require "skynet"

return function (url, post)

	return skynet.call(skynet.uniqueservice("webcurl"), "lua", "request", url,
	nil, post, false)
end	