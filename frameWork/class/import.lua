local skynet = require "skynet"

function import(loadname, ...)
	
	loadname = string.gsub(loadname, "%.", "/")
	local path = skynet.getenv("lua_path")
	local main
	local err = {}
	for pat in string.gmatch(path, "([^;]+);*") do
		local filename = string.gsub(pat, "?", loadname)
		
		local f, msg = loadfile(filename)
		if not f then
			table.insert(err, msg)
		else
			pattern = pat
			main = f
			break
		end
	end

	if not main then
		error(table.concat(err, "\n"))
	end

	return main(...)
end	