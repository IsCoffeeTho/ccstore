local Response = {
	---@enum ccStore.Response.statusCode
	--- Some what stolen from geminiprotocol
	--- however severly simplified
	code = {
		-- Request is being handled
		ACK = 05,
		
		-- Request needs data block
		MISSING_INFO = 10,
		
		-- Request was handled
		OK = 20,
		-- Discover was successful
		SERVER_PRESENT = 29,
		
		-- Server had an error and cannot process your request
		ERROR = 40,
		-- Server could collect the item but is not doing so due to policies set in place.
		-- Could be that the server is configured to accept specific items
		NOT_ACCEPTED = 41,
		-- Describes that the inventory passed into the request is not visible to the server
		INVENTORY_INACCESSIBLE = 42,
		-- Alerts that an item is missing from the request inventory
		ITEM_INACCESSIBLE = 43,

		-- Suggests that the request has bad data or operation
		BAD_REQUEST = 50,
		-- Requested item cannot be pushed to storage
		STORAGE_FULL = 51,
		-- Requested item cannot be pulled to storage
		ITEM_EMPTY = 52,
		-- Server was hit but request was bad
		MALFORMED_REQUEST = 55,
		-- Server didn't respond in time
		REQUEST_TIMEOUT = 59
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

	local body = ""
	for i,s in packet do
		body = body + " " + s
	end
	if body ~= "" then
		message.body = body
	end
	return message
end

---@param res ccStore.Response
---@return string
function Response.toString(res)
	local responseLine = string.format("%s %02d", res.msgid or "", res.status or Response.code.ERROR)
	if res.body == nil then
		return responseLine
	end
	return string.format("%s %s", responseLine, res.body)
end

return Response
