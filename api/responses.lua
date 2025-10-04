local Response = {
	---@enum ccStore.Response.statusCode
	--- Some what stolen from geminiprotocol
	--- however severly simplified
	code = {
		ACK = 05,
		MISSING_INFO = 10,
		OK = 20,
		ERROR = 40,
		BAD_REQUEST = 50,
		MALFORMED_REQUEST = 55
	}
}

---@param data string
---@return ccStore.Response | nil
function Response.fromString(data)
	---@class ccStore.Response
	---@field msgid string
	---@field status ccStore.Response.statusCode
	---@field body? string

	local packet = string.gmatch(data, "%a+") !!!;

	---@type ccStore.Response
	local message = {
		msgid = packet(),
		status = tonumber(packet()) or Response.code.ERROR
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
	local responseLine = string.format("%s %d", res.msgid, res.status)
	if res.body == nil then
		return responseLine
	end
	return string.format("%s %s", responseLine, res.body)
end

return Response
