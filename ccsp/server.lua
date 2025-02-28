local function checkServername(servername)
	return string.match(servername, "^%a%w%w+.%a%w%w+(.%a%w%w+)$") ~= nil
end

local server = {
	create = function(o, servername)
		if not checkServername(servername) then
			return nil
		end
		o = o or {}
		o.servername = servername
		o.handleModemMessage = function(ev)
			local event, side, channel, replyChannel, message, distance = table.unpack(ev)
			if channel ~= 100 then return end
		end
		return o
	end,
	discover = function(name) --Helps with detecting server name collisions
		local discoverTimeoutTimerId = os.startTimer(5)
		local reply = math.random(90,99)
		local discoverString = "CCSP DISCOVER NAME="..name
		local matchString = "CCSP MATCH "..name
		local modem = peripheral.find("modem")
		modem.open(reply)
		modem.transmit(100, reply, discoverString)
		while true do
			local event, side, channel, replyChannel, message, distance = os.pullEvent()
			if event == "timer" and side == discoverTimeoutTimerId then
				modem.close(reply)
				return false
			end
			if event == "modem_message" and channel == reply then
				if message == matchString then
					modem.close(reply)
					return true
				end
			end
		end
		modem.close(reply)
		return false
	end
}

return server
