-- I know, I know, this file may as well  be named "RandomCodeThatHasNoHome.lua"

function keys(t)
	local rt = {}
	for k,_ in pairs(t) do table.insert(rt, k) end
	return rt
end

function string.compare(s1, s2)
	assert(s1 and s2, "string.compare takes two arguments!")
	
	local len = math.min(#s1, #s2)
	
	for i = 1, len do
		local num1 = s1:sub(i,i):byte()
		local num2 = s2:sub(i,i):byte()
		if num1 ~= num2 then
			return num1 < num2 and 1 or -1
		end
	end
	return 0
end

function split(s, sep)
	local t = {}
	local sep = sep or " "..NEWL
	
	-- For every substring made up of non separator characters, add to t
	for i in string.gmatch(s, "[^"..sep.."]+") do table.insert(t, i) end
	return t
end