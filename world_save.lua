local tostring = tostring
local pairs = pairs
local table = table
function ser(obj, indent, tables)
	local tables = tables or {}
	print("indent: "..tostring(indent))
	local indent = indent or 1
	local indentStr = string.rep("  ", indent)
	local s = string.rep("  ", indent-1)..'{'..NEWL
	for k,v in pairs(obj) do
		if type(v) ~= "function" then				
			s = s .. indentStr
			if type(k) == "string" then
				if k:match("do_[^_]+_str") then
					k = k:match("(do_[^_]+)")
				end
				
				if not k:match("^[%a_][%w_]*$") then
					k = '["'..k..'"]'
				end
			elseif type(k) == "number" then
				k = "["..k.."]"
			end
			
			s = s ..k..' = '
			
			if type(v) == "string" then
				v = '"'..v..'"'
			elseif type(v) == "table" then
				if v.identifier then
					v = '"'..v.identifier..'"'
				elseif not contains(tables, v) then
					table.insert(tables, v)
					v = ser(v, indent+1, tables)
				end
			end
			
			s = s .. tostring(v) .. ","
			s = s..NEWL
		end
	end
	s = s..string.rep("  ",indent-1).."}"
	return s
end