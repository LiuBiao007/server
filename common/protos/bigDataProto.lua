local types = [[

]]

local c2s = [[

]]

local s2c = [[

	bigdata_header %d {
		request {
		name 0 : string #协议名
		index 1 : integer #编号
		len 2 : integer #长度
		}
	}

	bigdata_content %d {
	request {
		index 1 : integer
		data 2 : string
	}
	}	
]]

return {
    types = types,
    c2s = c2s,
    s2c = s2c,
}