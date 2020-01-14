local skynet = require "skynet"

return function (url, get)

	return skynet.call(skynet.uniqueservice("webcurl"), "lua", "request", url,
	get, nil, false)
end	