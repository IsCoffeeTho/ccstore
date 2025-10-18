local responses = require("responses")
local requests = require("requests")

local client = {}

---@param modem ccTweaked.peripheral.WiredModem
---@param port? integer Port that the API is using
---@param requestTimeout? integer Time in seconds to wait for a response
---@param responseTimeout? integer Time in seconds to wait after an acknowledgement for a response
function client.new(modem, port, requestTimeout, responseTimeout)
	port = port or 1000
	requestTimeout = requestTimeout or 2.5
	responseTimeout = responseTimeout or 60

	---@class ccStore.client
	local o = {
		code = responses.code
	}

	---@type ccStore.QueuedRequest[]
	local waitingQueue = {}
	---@type ccStore.QueuedRequest[]
	local acknowledgedQueue = {}
	---@type ccStore.Response[]
	local responseQueue = {}

	---@async
	function o.eventLoop()
		while true do
			local event = { os.pullEvent("modem_message") }
			---@diagnostic disable-next-line
			local _, side, channel, replyPort, message, distance = table.unpack(event)
			if replyPort == port then
				local response = responses.fromString(message)
				if response ~= nil then
					if waitingQueue[response.msgid] ~= nil then
						waitingQueue[response.msgid] = nil
						responseQueue[response.msgid] = response
					end
				end
			end
			os.sleep(0.05)
		end
	end

	---@async
	---@param message ccStore.Request
	function o.request(message)
		---@cast message ccStore.QueuedRequest
		---@class ccStore.QueuedRequest: ccStore.Request
		---@field port integer

		message.port = math.random(10000, 19999)
		message.msgid = requests.genMsgID()
		modem.open(message.port)

		---@type ccStore.Response
		local response = {
			status = responses.code.ERROR,
			msgid = message.msgid,
			body = "CLIENT ERROR",
		}

		waitingQueue[message.msgid] = message

		parallel.waitForAny(
			function()
				modem.transmit(port, message.port, requests.toString(message))
				while not responseQueue[message.msgid] do
					os.sleep(0.05)
				end
				response = responseQueue[message.msgid]
				responseQueue[message.msgid] = nil
				if response.status ~= responses.code.ACK then return end
				acknowledgedQueue[message.msgid] = message
			end,
			function()
				os.sleep(requestTimeout)
				response = {
					status = responses.code.REQUEST_TIMEOUT,
					msgid = message.msgid,
					body = "REQUEST TIMEOUT",
				}
			end
		)
		if acknowledgedQueue[message.msgid] then
			parallel.waitForAny(
				function()
					while not responseQueue[message.msgid] do
						os.sleep(0.05)
					end
					response = responseQueue[message.msgid]
					responseQueue[message.msgid] = nil
				end,
				function()
					os.sleep(responseTimeout)
					response = {
						status = responses.code.REQUEST_TIMEOUT,
						msgid = message.msgid,
						body = "REQUEST TIMEOUT",
					}
				end
			)
		end
		
		modem.close(message.port)
		return response
	end

	---@param namespace? string
	function o.discover(namespace)
		local function emptyIterator() return nil end

		local res = o.request({
			namespace = namespace,
			operation = "discover"
		})
		if res == nil then return emptyIterator end
		if res.status ~= responses.code.SERVER_PRESENT then return emptyIterator end
		print(textutils.serialise(res))
		return string.gmatch(res.body, "[^,]+")
	end

	---@param namespace string
	---@param fromInventory string
	---@param slot integer
	function o.push(namespace, fromInventory, slot)
		return o.request({
			namespace = namespace,
			operation = "push",
			fromInventory = fromInventory,
			slot = slot
		})
	end

	---@param namespace string
	---@param itemId string
	---@param toInventory string
	---@param count? integer
	function o.pull(namespace, itemId, toInventory, count)
		count = count or 1
		return o.request({
			namespace = namespace,
			operation = "pull",
			item = itemId,
			count = count,
			toInventory = toInventory
		})
	end

	---@param namespace string
	---@param query string
	---@param fuzzy? boolean
	function o.search(namespace, query, fuzzy)
		fuzzy = fuzzy or false
		return o.request({
			namespace = namespace,
			operation = "search",
			query = query,
			fuzzy = fuzzy
		})
	end

	return o
end

return client
