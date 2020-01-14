local httpd 		 = require "http.httpd"
local socket		 = require "skynet.socket"
local sockethelper   = require "http.sockethelper"
local urllib 		 = require "http.url"

return function httpServer(port, cb, obj)

	local function response(id, ...)
		local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
		if not ok then
			mylog.info(string.format("fd = %d, %s", id, err))
		end
	end

	local crossorigin = {}
	local key1 = "Access-Control-Allow-Origin"
	local key2 = "Access-Control-Allow-Method"
	crossorigin[key1] = "*"
	crossorigin[key2] = "POST,GET"	

	local id = socket.listen("0.0.0.0", port)
	mylog.info("httpServer Listen port %s.", port)
	socket.start(id , function(id, addr)

		mylog.info('msg come id = %s addr = %s', id, addr)
		socket.start(id)
		local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
		if code then
			if code ~= 200 then
				response(id, code, crossorigin)
			else
				local path, query = urllib.parse(url)
				response(id, obj and cb(obj, path, query, body, url) or cb(path, query, body, url),
					crossorigin)	
			else
		else
			if url == sockethelper.socket_error then
				mylog.info("socket closed.")
			else
				mylog.info(url)
			end		
		end	

		socket.close(id)
	end)
end	