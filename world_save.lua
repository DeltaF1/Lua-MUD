local tostring = tostring
local pairs = pairs
local table = table

-- Serialize a table
function ser(obj, indent, tables)
	-- Previously serialized tables, to prevent stack overflows
	local tables = tables or {}
	print("indent: "..tostring(indent))
	local indent = indent or 1
	local indentStr = string.rep("  ", indent)
	local s = string.rep("  ", indent-1)..'{'..NEWL
	for k,v in pairs(obj) do
		-- Discard function keys. If they're built in they'll be part of a superclass, if they're custom they'll be encoded in xxx_str
		if type(v) ~= "function" then				
			s = s .. indentStr
			if type(k) == "string" then
				-- Remove the "_str" from custom function keys
				if k:match("do_[^_]+_str") then
					k = k:match("(do_[^_]+)")
				end
				
				-- If the key is only alphanumeric, and doesn't start with a number, leave it as is. Otheriwse add ["key"] syntax
				if not k:match("^[%a_][%w_]*$") then
					k = '["'..k..'"]'
				end
			-- If the key is a number index add brackets. e.g. {[1]="foo", [2]="bar"}
			elseif type(k) == "number" then
				k = "["..k.."]"
			end
			
			s = s ..k..' = '
			
			if type(v) == "string" then
				v = '"'..v..'"'
			elseif type(v) == "table" then
				-- If it has an identifier, then encode that instead of the table
				-- TBD: in world_load load players, objects, and rooms with unique identifiers to support this
				if v.identifier then
					v = '"'..v.identifier..'"'
				-- If it's a table not yet seen, encode it
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