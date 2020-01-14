local httpd 		 = require "http.httpd"
local socket		 = require "skynet.socket"
local sockethelper   = require "http.sockethelper"
local urllib 		 = require "http.url"

return function httpsServer(port, cb, obj)

	local id = socket.listen("0.0.0.0", port)
	mylog.info("Listen httpsServer port %s", port)

	local crossorigin = {}
	local key1 = "Access-Control-Allow-Origin"
	local key2 = "Access-Control-Allow-Method"
	crossorigin[key1] = "*"
	crossorigin[key2] = "POST,GET"

	local SSLCTX_SERVER = nil
	local function gen_interface(protocol, fd)
		if protocol == "http" then
			return {
				init = nil,
				close = nil,
				read = sockethelper.readfunc(fd),
				write = sockethelper.writefunc(fd),
			}
		elseif protocol == "https" then
			local tls = require "http.tlshelper"
			if not SSLCTX_SERVER then
				SSLCTX_SERVER = tls.newctx()
				-- gen cert and key
				-- openssl req -x509 -newkey rsa:2048 -days 3650 -nodes -keyout server-key.pem -out server-cert.pem
				local certfile = skynet.getenv("certfile") or "./server-cert.pem"
				local keyfile = skynet.getenv("keyfile") or "./server-key.pem"
				SSLCTX_SERVER:set_cert(certfile, keyfile)
			end
			local tls_ctx = tls.newtls("server", SSLCTX_SERVER)
			return {
				init = tls.init_responsefunc(fd, tls_ctx),
				close = tls.closefunc(tls_ctx),
				read = tls.readfunc(fd, tls_ctx),
				write = tls.writefunc(fd, tls_ctx),
			}
		else
			error(string.format("Invalid protocol: %s", protocol))
		end
	end

	local function response(id, write, ...)
		local ok, err = httpd.write_response(write, ...)
		if not ok then
			-- if err == sockethelper.socket_error , that means socket closed.
			mylog.info(string.format("fd = %d, %s", id, err))
		end
	end

	socket.start(id , function(id, addr)

		mylog.info('msg come id = %s addr = %s', id, addr)
		socket.start(id)

		local protocol = "https"
		local interface = gen_interface(protocol, id)
		if interface.init then
			interface.init()
		end		

		local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
		if code then
			if code ~= 200 then
				response(id, interface.write, code, crossorigin)
			else
				local path, query = urllib.parse(url)
				response(id, interface.write, 
					obj and cb(obj, path, query, body, url) or cb(path, query, body, url), 
					crossorigin)	
			else
		else
			if url == sockethelper.socket_error then
				mylog.info("socket closed.")
			else
				mylog.info(url)
			end		
		end	

		if interface.close then
			interface.close()
		end

		socket.close(id)				
	end)
end
