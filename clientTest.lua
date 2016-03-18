-- config
NUM = 100
minterval = 0.1
maxterval = 0.2

socket = require "socket"
verbs = require "verbs"
config = require "config"

words = {}

for k,v in pairs(verbs) do
	if k ~= "stop" then
		for _,a in ipairs(v.aliases) do
			table.insert(words, a)
		end
	end
end

clients = {}

for i = 1, NUM do
	local client = socket.tcp()
	client:settimeout(0.001)
	client:connect("localhost", config.port)
	table.insert(clients, client)
end

while #clients > 0 do
	for i,v in ipairs(clients) do
		socket.select(nil, nil, math.random(minterval, maxterval))
		local s = ""
		for i = 1, math.random(5) do
			if math.random(100) > 20 then
				s = s .. words[math.random(#words)]
			else
				for i = 1, math.random(10) do
					s = s .. string.char(math.random(32, 126))
				end
			end
			s = s.." "
		end
		v:send(s.."\r\n")
		local _, err = v:receive()
		if err == "closed" then
			for i = 1,#clients do
				if clients[i] == v then
					table.remove(clients, i)
					break
				end
			end
		end
	end
end