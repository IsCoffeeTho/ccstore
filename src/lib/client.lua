local discoverTimeout = 5

local channelUsed = {
	[90] = false,
	[91] = false,
	[92] = false,
	[93] = false,
	[94] = false,
	[95] = false,
	[96] = false,
	[97] = false,
	[98] = false,
	[99] = false,
}

local function allocChannel()
	local channel = math.random(0,9) + 90
	local i = 0
	while channelUsed[channel] and i < 10 do
		channel = channel + 1
		channel = channel % 10
		channel = channel + 90
		i = i + 1
	end
	if i == 10 then return nil end
	channelUsed[channel] = true
	return channel
end

local function freeChannel(channel)
	channelUsed[channel] = false
end

local client = {
	discover = function(predicates) --Helps with detecting server name collisions
		local discoverTimeoutTimerId = os.startTimer(discoverTimeout)
		local results = {}
		local reply = allocChannel()
		local discoverString = "CCSP DISCOVER "
		local matchString = "CCSP MATCH "
		local modem = peripheral.find("modem") ---@type modem
		modem.open(reply)
		modem.transmit(100, reply, discoverString)
		while true do
			local event, side, channel, replyChannel, message, distance = os.pullEvent()
			if event == "timer" and side == discoverTimeoutTimerId then
				freeChannel(reply)
				return results
			end
			if event == "modem_message" and channel == reply then
				if string.match(message, matchString) ~= nil then
					results[results.getn() + 1] = string.sub(message, string.len(matchString))
				end
			end
		end
	end
}

return client