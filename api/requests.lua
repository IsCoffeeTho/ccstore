local Request = {}

---@param data string
---@return ccStore.Request | nil
function Request.fromString(data)
	---@class ccStore.RequestMessage
	---@field namespace string
	---@field msgid string
	---@field operation string

	---@class ccStore.RequestMessage.nil: ccStore.RequestMessage
	---@field operation ""

	---@class ccStore.Request: ccStore.RequestMessage.nil | ccStore.RequestMessage.Push | ccStore.RequestMessage.Pull | ccStore.RequestMessage.Search

	local packet = string.gmatch(data, "%a+") !!!;

	---@class ccStore.Request
	local message = {
		namespace = packet(),
		msgid = packet(),
		operation = packet()
	}

	if message.operation == "discover" then
		---@class ccStore.RequestMessage.Discover: ccStore.RequestMessage
		---@field operation "discover"

		---@type ccStore.RequestMessage.Discover
		---@diagnostic disable-next-line
		return message
	elseif message.operation == "push" then
		---@class ccStore.RequestMessage.Push: ccStore.RequestMessage
		---@field operation "push"
		---@field fromInventory string Formatted as "<inventory>;<slot>" where slot is 1st indexed (because lua)

		message.fromInventory = packet()
	elseif message.operation == "pull" then
		---@class ccStore.RequestMessage.Pull: ccStore.RequestMessage
		---@field operation "pull"
		---@field toInventory string Formatted as "<inventory>" 

		message.toInventory = packet()
	elseif message.operation == "search" then
		---@class ccStore.RequestMessage.Search: ccStore.RequestMessage
		---@field operation "search"
		---@field query string Search query, can be an itemID or an item name
		---@field fuzzy boolean Describes whether the search will be inexact and will try to return similar items (name-wise)

		local query = ""
		for i,s in packet do
			query = query + " " + s
		end
		message.fuzzy = query[1] == "~"
		if message.fuzzy then
			query = query:sub(2)
		end
		message.query = query
	end
	return message
end

---@param req ccStore.RequestMessage
---@return string 
function Request.toString(req)
	if req.operation == "" then
		return ""
	end
	local requestLine = string.format("%s %s %s", req.namespace, req.msgid, req.operation)
	if req.operation == "discover" then
		return requestLine
	end
	local bodyLine = ""
	if req.operation == "pull" then
		---@type ccStore.RequestMessage.Pull
		---@diagnostic disable-next-line
		local op = req
		bodyLine = op.toInventory
	elseif req.operation == "push" then
		---@type ccStore.RequestMessage.Push
		---@diagnostic disable-next-line
		local op = req
		bodyLine = op.fromInventory
	elseif req.operation == "search" then
		---@type ccStore.RequestMessage.Search
		---@diagnostic disable-next-line
		local op = req
		if op.fuzzy then
			bodyLine = "~"
		end
		bodyLine = bodyLine + op.query
	end
	return string.format("%s %s", requestLine, bodyLine)
end

return Request