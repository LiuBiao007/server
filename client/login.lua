local socket = require "client.socket"
local crypt = require "crypt"

function login(token)
	if _VERSION ~= "Lua 5.3" then
		error "Use lua 5.3"
	end

	local fd = assert(socket.connect("127.0.0.1", 8004))
	--local fd = socket.connect("120.26.6.154", 8004)
	--local fd = socket.connect("118.178.125.53",8004)
	--local fd = socket.connect("118.178.88.254",8004)
	local function writeline(fd, text)
		socket.send(fd, text .. "\n")
	end

	local function unpack_line(text)
		local from = text:find("\n", 1, true)
		if from then
			return text:sub(1, from-1), text:sub(from+1)
		end
		return nil, text
	end

	local last = ""

	local function unpack_f(f)
		local function try_recv(fd, last)
			local result
			result, last = f(last)
			if result then
				return result, last
			end
			local r = socket.recv(fd)
			if not r then
				return nil, last
			end
			if r == "" then
				error "Server closed"
			end
			return f(last .. r)
		end

		return function()
			while true do
				local result
				result, last = try_recv(fd, last)
				if result then
					return result
				end
				socket.usleep(100)
			end
		end
	end

	local readline = unpack_f(unpack_line)

	local challenge = crypt.base64decode(readline())

	local clientkey = crypt.randomkey()
	writeline(fd, crypt.base64encode(crypt.dhexchange(clientkey)))
	local secret = crypt.dhsecret(crypt.base64decode(readline()), clientkey)

	local hmac = crypt.hmac64(challenge, secret)
	writeline(fd, crypt.base64encode(hmac))

	local function encode_token(token)
		return string.format("%s@%s:%s",
			crypt.base64encode(token.user),
			crypt.base64encode(token.server),
			crypt.base64encode(token.pass))
	end

	local etoken = crypt.desencode(secret, encode_token(token))
	local b = crypt.base64encode(etoken)
	writeline(fd, crypt.base64encode(etoken))

	local result = readline()
	local code = tonumber(string.sub(result, 1, 3))
	assert(code == 200)
	socket.close(fd)

	local secret = crypt.base64decode(string.sub(result, 5))

	print("login ok, subid=", crypt.hexencode(secret))
	return secret
end

return login