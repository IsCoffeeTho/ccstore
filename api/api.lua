local responses = require("responses")
local requests = require("requests")

local api = {
	code = responses.code,
	server = require("server"),
	client = require("client")
}

---@param modem ccTweaked.peripheral.Modem
function api.wrapServer(modem)
	local server = {
		port = -1
	}
	---@return ccStore.Server.Request
	function server.recv()
		while true do
			::continue::
			---@type ["modem_message", string, string, integer, boolean|string|number|table, number|nil]
			---@diagnostic disable-next-line
			local event = { os.pullEvent("modem_message") }
			---@diagnostic disable-next-line
			local _, side, channel, replyPort, message, distance = table.unpack(event)
			if channel ~= server.port then
				os.queueEvent(table.unpack(event))
				goto continue
			end

			---@class ccStore.Server.Request: ccStore.RequestMessageFormat
			---@diagnostic disable-next-line
			local request = requests.fromString(message)
			if request == nil then
				---@diagnostic disable-next-line
				modem.transmit(replyPort, server.port, responses.toString({
					status = responses.code.MALFORMED_REQUEST,
					msgid = "",
				}))
				goto continue
			end
			---@class ccStore.Server.Request.Discover: ccStore.Request, ccStore.RequestMessage.Discover
			---@class ccStore.Server.Request.Search: ccStore.Request, ccStore.RequestMessage.Search
			---@class ccStore.Server.Request.Pull: ccStore.Request, ccStore.RequestMessage.Pull
			---@class ccStore.Server.Request.Push: ccStore.Request, ccStore.RequestMessage.Push

			---@class ccStore.Server.Response: ccStore.Response
			response = {
				acknowledged = false,
				sent = false,
				msgid = request.msgid
			}

			---@param body? string
			function response.send(body)
				if body ~= nil then
					response.body = body
				end
				response.msgid = request.msgid
				---@diagnostic disable-next-line
				modem.transmit(replyPort, server.port, responses.toString(response))
				response.acknowledged = true
				response.sent = true
			end

			function response.ack()
				---@diagnostic disable-next-line
				modem.transmit(replyPort, server.port, responses.toString({
					status = responses.code.ACK,
					msgid = request.msgid
				}))
				response.acknowledged = true
			end

			request.response = response
			request.event = event

			return request
		end
	end

	---@param port? integer
	function server.listen(port)
		if server.port ~= -1 then error("Server is already listening") end
		port = port or 1000
		server.port = port
		
		if not modem.isOpen(server.port) then
			modem.open(server.port)
		end
	end

	return server
end

---@param modem ccTweaked.peripheral.WiredModem
function api.wrapClient(modem)
	local client = {
		code = responses.code
	}

	---@param message ccStore.Request
	---@param port? integer Port that the API is using.
	---@param timeout? integer Time in seconds to wait for a response.
	---@param timeoutCount? integer Count of messages to attempt before failing.
	---@return ccStore.Response | nil returns a response from the server if the server responds, nil if server doesn't respond
	function client.request(message, port, timeout, timeoutCount)
		port = port or 1000
		timeout = timeout or 2.5
		timeoutCount = timeoutCount or 3
		local recvChannel = math.random(10000, 19999)
		local keepOpen = modem.isOpen(recvChannel)
		message.msgid = requests.genMsgID()
		---@type ccStore.Response
		local retval = {
			msgid = message.msgid,
			status = responses.code.REQUEST_TIMEOUT,
		}
		if message.operation == "discover" then
			retval.status = responses.code.EMPTY_NAMESPACE
		end
		modem.open(recvChannel)
		modem.transmit(port, recvChannel, requests.toString(message))
		local timeoutId = os.startTimer(timeout)
		while timeoutCount > 0 do
			---@type ["modem_message", string, string, integer, boolean|string|number|table, number|nil]
			---@diagnostic disable-next-line
			local event = { os.pullEvent() }
			local eventName = event[1]
			if eventName == "modem_message" and event[3] == recvChannel then
				---@diagnostic disable-next-line
				local _, side, channel, replyPort, data, distance = table.unpack(event)
				---@diagnostic disable-next-line
				potential = responses.fromString(data)
				if potential ~= nil then
					if potential.msgid == message.msgid then
						if message.operation == "discover" then
							if potential.status == responses.code.SERVER_PRESENT then
								retval.status = responses.code.SERVER_PRESENT
								print(string.format("Recieved %s", textutils.serialise(potential)))
								if retval.body == nil then
									retval.body = potential.body
								else
									retval.body = retval.body .. ',' .. potential.body
								end
							end
						elseif potential.status == responses.code.ACK then
							while true do
								---@type ["modem_message", string, string, integer, boolean|string|number|table, number|nil]
								---@diagnostic disable-next-line
								local event = { os.pullEvent("modem_message") }
								---@diagnostic disable-next-line
								_, side, channel, replyPort, data, distance = table.unpack(event)
								if channel == recvChannel then
									if not keepOpen then modem.close(recvChannel) end
									---@diagnostic disable-next-line
									return responses.fromString(data)
								else
									os.queueEvent(table.unpack(event))
								end
							end
						else
							if not keepOpen then modem.close(recvChannel) end
							---@diagnostic disable-next-line
							return potential
						end
					end
				end
			elseif eventName == "timer" and event[2] == timeoutId then
				timeoutCount = timeoutCount - 1
			else	
				os.queueEvent(table.unpack(event))
			end
		end
		if not keepOpen then modem.close(recvChannel) end
		return retval
	end

	---@param namespace? string
	---@param port? integer Port that the API is using.
	---@param timeout? integer Time in seconds to wait for a response.
	---@param timeoutCount? integer Count of messages to attempt before failing.
	function client.discover(namespace, port, timeout, timeoutCount)
		local function emptyIterator() return nil end

		local res = client.request({
			namespace = namespace,
			operation = "discover"
		}, port, timeout, timeoutCount)
		if res == nil then return emptyIterator end
		if res.status ~= responses.code.SERVER_PRESENT then return emptyIterator end
		print(textutils.serialise(res))
		return string.gmatch(res.body, "[^,]+")
	end

	---@param namespace string
	---@param fromInventory string
	---@param slot integer
	---@param port? integer Port that the API is using.
	---@param timeout? integer Time in seconds to wait for a response.
	---@param timeoutCount? integer Count of messages to attempt before failing.
	function client.push(namespace, fromInventory, slot, port, timeout, timeoutCount)
		return client.request({
			namespace = namespace,
			operation = "push",
			fromInventory = fromInventory,
			slot = slot
		}, port, timeout, timeoutCount)
	end

	---@param namespace string
	---@param itemId string
	---@param toInventory string
	---@param count? integer
	---@param port? integer Port that the API is using.
	---@param timeout? integer Time in seconds to wait for a response.
	---@param timeoutCount? integer Count of messages to attempt before failing.
	function client.pull(namespace, itemId, toInventory, count, port, timeout, timeoutCount)
		count = count or 1
		return client.request({
			namespace = namespace,
			operation = "pull",
			item = itemId,
			count = count,
			toInventory = toInventory
		}, port, timeout, timeoutCount)
	end

	---@param namespace string
	---@param query string
	---@param fuzzy? boolean
	---@param port? integer Port that the API is using.
	---@param timeout? integer Time in seconds to wait for a response.
	---@param timeoutCount? integer Count of messages to attempt before failing.
	function client.search(namespace, query, fuzzy, port, timeout, timeoutCount)
		fuzzy = fuzzy or false
		return client.request({
			namespace = namespace,
			operation = "search",
			query = query,
			fuzzy = fuzzy
		}, port, timeout, timeoutCount)
	end

	return client
end

return api
