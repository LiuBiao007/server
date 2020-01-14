local skynet = require "skynet"
local socket = require "client.socket"

function admin(param)
	if _VERSION ~= "Lua 5.3" then
		error "Use lua 5.3"
	end

	local last = ""
	local function recv_package(last)
		local r = socket.recv(fd)
		if not r then
			return nil, last
		end
		if r == "" then
			print("Server has closed.")
		end
		return last .. r
	end

	local function dispatch_package()
		while true do
			local v
			v, last = recv_package(last)
			if not v then
				break
			end

			print(v)
		end
	end

	-- 直接发送
	local fd = socket.connect("127.0.0.1", 7666)
	assert(fd)
    socket.send(fd, table.concat(param, " ") .. "\n")

	local r
	local timeout = os.time()
	while true do
		r = socket.recv(fd, "\n")
		if r then
			if r == "" then
				print("Server has closed.")
			else
				print(r)
			end
			
			break
		end

		socket.usleep(100)

		if os.time() - timeout > 10 then
			print("socket recv timeout > 10s")
			break
		end
	end
end

return admin