local serverVersion = "0.0.1"

local discoverTimeout = 5

local function checkServername(servername)
	return string.match(servername, "^%a%w%w+.%a%w%w+(.%a%w%w+)$") ~= nil
end

local function isServernameTaken(name)
	local discoverTimeoutTimerId = os.startTimer(discoverTimeout)
	local reply = math.random(90,99)
	local discoverString = "CCSP DISCOVER NAME="..name
	local matchString = "CCSP MATCH "..name
	local modem = peripheral.find("modem") ---@type modem
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
end

local server = {
	create = function(o, servername, ...)
		if not checkServername(servername) then
			return nil
		end
		if isServernameTaken() then
			return nil
		end
		o = o or {}
		o.servername = servername
		o.modem = peripheral.find("modem") ---@type modem
		o.modem.open(100)
		o.waitForEvent = function(ev)
			local event, side, channel, replyChannel, message, distance = os.pullEvent()
			if channel ~= 100 then return end
			if string.match(message, "^CCSP DISCOVER") then
				
			end
		end
		return o
	end,
}

return server
