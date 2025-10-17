local responses = require("responses")
local requests = require("requests")

local client = {}

function client.new(o, modem)
	o = o or {}

	o.code = responses.code

	---@param message ccStore.Request
	---@param port? integer Port that the API is using.
	---@param timeout? integer Time in seconds to wait for a response.
	---@param timeoutCount? integer Count of messages to attempt before failing.
	---@return ccStore.Response | nil returns a response from the server if the server responds, nil if server doesn't respond
	function o.request(message, port, timeout, timeoutCount)
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
		
		if not keepOpen then modem.close(recvChannel) end
		return retval
	end

	---@param namespace? string
	---@param port? integer Port that the API is using.
	---@param timeout? integer Time in seconds to wait for a response.
	---@param timeoutCount? integer Count of messages to attempt before failing.
	function o.discover(namespace, port, timeout, timeoutCount)
		local function emptyIterator() return nil end
		
		local res = o.request({
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
	function o.push(namespace, fromInventory, slot, port, timeout, timeoutCount)
		return o.request({
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
	function o.pull(namespace, itemId, toInventory, count, port, timeout, timeoutCount)
		count = count or 1
		return o.request({
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
	function o.search(namespace, query, fuzzy, port, timeout, timeoutCount)
		fuzzy = fuzzy or false
		return o.request({
			namespace = namespace,
			operation = "search",
			query = query,
			fuzzy = fuzzy
		}, port, timeout, timeoutCount)
	end
	
	return o
end

return client