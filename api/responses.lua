local Response = {
	---@enum ccStore.Response.statusCode
	--- Some what stolen from geminiprotocol
	--- however severly simplified
	code = {
		-- Request is being handled
		ACK = 05,
		[05] = "ACK",

		-- Request was handled
		OK = 20,
		[20] = "OK",
		-- Request was handled but not fully
		PARTIAL_OK = 21,
		[21] = "PARTIAL_OK",
		-- Discover was successful
		SERVER_PRESENT = 29,
		[29] = "SERVER_PRESENT",

		-- Server had an error and cannot process your request
		ERROR = 40,
		[40] = "ERROR",
		-- Server could collect the item but is not doing so due to policies set in place.
		-- Could be that the server is configured to accept specific items
		NOT_ACCEPTED = 41,
		[41] = "NOT_ACCEPTED",
		-- Describes that the inventory passed into the request is not visible to the server
		INVENTORY_INACCESSIBLE = 42,
		[42] = "INVENTORY_INACCESSIBLE",
		-- Alerts that an item is missing from the request inventory
		ITEM_INACCESSIBLE = 43,
		[43] = "ITEM_INACCESSIBLE",
		-- Inventory passed is not an inventory
		NOT_INVENTORY = 44,
		[44] = "NOT_INVENTORY",
		-- Discover was unsuccessful
		EMPTY_NAMESPACE = 49,
		[49] = "EMTPY_NAMESPACE",

		-- Suggests that the request has bad data or operation
		BAD_REQUEST = 50,
		[50] = "BAD_REQUEST",
		-- Requested item cannot be pushed to storage
		STORAGE_FULL = 51,
		[51] = "STORAGE_FULL",
		-- Requested item cannot be pulled to storage
		ITEM_EMPTY = 52,
		[52] = "ITEM_EMPTY",
		-- Request needs data block
		MISSING_INFO = 53,
		[53] = "MISSING_INFO",
		-- Server was hit but request was bad
		MALFORMED_REQUEST = 54,
		[54] = "MALFORMED_REQUEST",
		-- Server has not implemented something to do with this request
		NOT_IMPLEMENTED = 55,
		[55] = "NOT_IMPLEMENTED",
		-- Server(s) did not respond in time
		REQUEST_TIMEOUT = 59,
		[59] = "REQUEST_TIMEOUT"
	}
}

---@param data string
---@return ccStore.Response | nil
function Response.fromString(data)
	---@class ccStore.Response
	---@field msgid string
	---@field status ccStore.Response.statusCode
	---@field body? string

	local packet = string.gmatch(data, "[^ ]+")

	---@type ccStore.Response
	local message = {
		msgid = packet(),
		status = tonumber(packet() or "40") or Response.code.ERROR
	}

	local body = nil
	for word in packet do
		if body == nil then
			body = word
		else
			body = body .. " " .. word
		end
	end
	if body ~= nil then
		message.body = body
	end
	return message
end

---@param res ccStore.Response
---@return string
function Response.toString(res)
	local msg = string.format("%s %02d", res.msgid or "", res.status or Response.code.ERROR)
	if res.body == nil then
		return msg
	end
	return string.format("%s %s", msg, res.body)
end

return Response
