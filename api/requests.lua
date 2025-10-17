local Request = {}

---@param length? integer Default: `16`
---@return string
function Request.genMsgID(length)
	length = length or 16
	local bucket = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	local retval = ""
	local bucketLength = bucket:len()
	for i = 1, length do
		local r = math.random(bucketLength)
		retval = retval .. string.sub(bucket, r, r)
	end
	return retval
end

---@param data string
---@return ccStore.Request | nil
function Request.fromString(data)
	---@class ccStore.RequestMessageFormat
	---@field namespace string
	---@field msgid string
	---@field operation string
	---@field raw string

	---@class ccStore.RequestMessage.nil: ccStore.RequestMessageFormat
	---@field operation ""

	---@class ccStore.RequestMessage: ccStore.RequestMessage.nil | ccStore.RequestMessage.Discover | ccStore.RequestMessage.Free | ccStore.RequestMessage.Push | ccStore.RequestMessage.Pull | ccStore.RequestMessage.Search

	local packet = string.gmatch(data, "[^ ]+")

	---@class ccStore.Request
	local message = {
		raw = data,
		namespace = packet(),
		msgid = packet(),
		operation = packet(),
	}
	---@class ccStore.RequestMessage.Discover: ccStore.RequestMessageFormat
	---@field operation "discover"
	
	---@class ccStore.RequestMessage.Free: ccStore.RequestMessageFormat
	---@field operation "free"

	if message.operation == "discover" or message.operation == "free" then
		return message
	elseif message.operation == "push" then
		---@class ccStore.RequestMessage.Push: ccStore.RequestMessageFormat
		---@field operation "push"
		---@field fromInventory string
		---@field slot integer 1st indexed slot number of the inventory which holds the item
		---@field count integer *Optional* count of items to push, if unset or set to `0` it is assumed that the whole stack is to be pushed

		local next = packet():gmatch("[^;]+")

		message.fromInventory = next()
		if message.fromInventory == nil then return nil end
		---@type integer
		---@diagnostic disable-next-line
		message.slot = tonumber(next())
		if message.slot == nil then return nil end
		
		message.count = tonumber(packet() or "0")
		if message.count == nil then
			message.count = 0
		end
	elseif message.operation == "pull" then
		---@class ccStore.RequestMessage.Pull: ccStore.RequestMessageFormat
		---@field operation "pull"
		---@field toInventory string Formatted as "<inventory>" 
		---@field item string item_id of item to pull from storage
		---@field count integer count of items to pull

		message.toInventory = packet()
		message.item = packet()
		message.count = tonumber(packet())
	elseif message.operation == "search" then
		---@class ccStore.RequestMessage.Search: ccStore.RequestMessageFormat
		---@field operation "search"
		---@field query string Search query, can be an itemID or an item name
		---@field fuzzy boolean Describes whether the search will be inexact and will try to return similar items (name-wise)
		
		local query = nil
		for word in packet do
			if query == nil then
				query = word
			else
				query = query.." "..word
			end
		end
		if query == nil then
			message.query = ""
		else
			message.fuzzy = query[1] == "~"
			if message.fuzzy then
				query = string.sub(query, 2)
			end
			message.query = query
		end
	end
	return message
end

---@param req ccStore.RequestMessage<any>
---@return string 
function Request.toString(req)
	if req.operation == "" then
		return ""
	end
	local requestLine = string.format("%s %s %s", req.namespace, req.msgid, req.operation)
	if req.operation == "discover" or req.operation == "ping" then
		return requestLine
	end
	local bodyLine = ""
	if req.operation == "pull" then
		---@type ccStore.RequestMessage.Pull
		---@diagnostic disable-next-line
		local op = req
		bodyLine = string.format("%s %s %d", op.toInventory, op.item, op.count)
	elseif req.operation == "push" then
		---@type ccStore.RequestMessage.Push
		---@diagnostic disable-next-line
		local op = req
		bodyLine = string.format("%s;%d", op.fromInventory, op.slot)
	elseif req.operation == "search" then
		---@type ccStore.RequestMessage.Search
		---@diagnostic disable-next-line
		local op = req
		if op.fuzzy then
			bodyLine = "~"
		end
		bodyLine = string.format("%s%s", op.fuzzy and "~" or "", op.query)
	end
	return string.format("%s %s", requestLine, bodyLine)
end

return Request