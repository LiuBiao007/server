local fieldCheck = class("fieldCheck")
local json 			= require "ext.json"
local assert		= assert
local string_format = string.format
local type 			= type
local pairs			= pairs
local table_insert  = table.insert
local table_unpack  = table.unpack

function fieldCheck:check(expr,v) 

	local t = type(v)
	if t ~= "string" and t ~= "number" and t ~= "table" then
		assert(false, string_format("in db '%s' filed '%s' type is '%s'", self.name, expr, t))
	end	
end

function fieldCheck:pcallFunc(func, field, data)

	local ok, r = pcall(func, data)
	if not ok then

		error(string_format("error dbname '%s' field '%s' data:'%s' message: %s", 
				self.name, field, string.dump(data), r))
	end	
	return r
end	

function fieldCheck:checkField(data)

	local r = {}
	local fields = assert(dbField[self.name], string_format("error save dbname %s", self.name))
	
	for field, fieldType in pairs(fields) do

		self:check(field, data[field])

		if fieldType == 'J' then

			r[field] = self:pcallFunc(json.decode, field, data[field])
		elseif fieldType == 'D' then
			r[field] = self:pcallFunc(os.stringToDateTime, field, data[field])
		elseif fieldType == 'I' then
			r[field] = self:pcallFunc(function (n) return assert(tonumber(n)) end, field, data[field])	
		else	
			r[field] = data[field]
		end	
	end	

	assert(next(r), string_format("%s result is empty.", self.name))
	return r
end

function fieldCheck:checkSetField(data)

	local r = {}
	local fields 	= assert(dbField[self.name], 
						string_format("error save dbname %s.", self.name))
	local checklen 	= checklen_db[self.name] or {}
	for k, v in pairs(data) do

		table_insert(r, k)
		local fieldType = fields[k]
		if fieldType == "J" then

			assert(type(v) == "table" and not getmetatable(v), string_format("dbname %s k %s error.", self.name, k))
			local jd = self:pcallFunc(json.encode, k, v)
			local len = checklen[k]	
			if len then
				assert(#jd <= len, string_format("json type %s over defined len[%s].", k, len))	
			end
			table_insert(r, jd)
		elseif fieldType == 'D' then
			
			table_insert(r, self:pcallFunc(os.dateTimeToString, k, v))
		elseif fieldType == 'S' then
			
			local len = checklen[k]
			if len then
				v = tostring(v)
				assert(#v <= len, string_format("string type %s v %s over defined len[%s].", k, v, len))	
			end
			table_insert(r, v)	
		else
			table_insert(r, v)
		end				
	end	

	assert(next(r), string_format("%s result is empty.", self.name))
	return table_unpack(r)
end	
return fieldCheck

