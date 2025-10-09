---@diagnostic disable-next-line
if preiphemu then
	local _ = require("debug")
end

term.clear()
term.setCursorPos(1, 1)
print("Starting storage node")
print("Importing config.lua")

local config = require("config")

if config.localModem == nil then
	print("FAILED: localModem is not set")
	return
end
---@type ccTweaked.peripheral.WiredModem
---@diagnostic disable-next-line
local localModem = peripheral.wrap(config.localModem)
if localModem == nil then
	print("FAILED: localModem is invalid")
	return
elseif localModem.isWireless() then
	print("FAILED: localModem cannot be wireless")
	return
end

if config.publicModem == nil then
	print("FAILED: publicModem is not set")
	return
end
---@type ccTweaked.peripheral.WiredModem
---@diagnostic disable-next-line
local publicModem = peripheral.wrap(config.publicModem)
if publicModem == nil then
	print("FAILED: publicModem is invalid")
	return
elseif publicModem.isWireless() then
	print("FAILED: publicModem cannot be wireless")
	return
end

print("Modems passed checks")

print("Checking intermediate inventories")
if not localModem.isPresentRemote(config.localIntermediate) then
	print("FAILED: localIntermediate is not present on localNetwork")
	return
end
local localIntermediate = peripheral.wrap(config.localIntermediate)
if localIntermediate == nil then
	print("FAILED: publicIntermediate failed to bind")
	return
end

if not publicModem.isPresentRemote(config.publicIntermediate) then
	print("FAILED: publicIntermediate is not present on publicNetwork")
	return
end
local publicIntermediate = peripheral.wrap(config.publicIntermediate)
if publicIntermediate == nil then
	print("FAILED: publicIntermediate failed to bind")
	return
end

local storageSystem = require("storage")

---@diagnostic disable-next-line
local storage = storageSystem.wrap(localModem, localIntermediate)

local ccstoreAPI = require("api")

local api = ccstoreAPI.wrapServer(publicModem)
local server = api.listen()

print("Discovering inventories")
storage.discoverInventories()
print("Flushing intermediate...")
if storage.flush() then
	print("Flushed intermediate")
else
	print("FAILED: Couldn't flush intermediate")
	return
end

---@param req ccStore.Server.Request
---@param res ccStore.Server.Response
local function handlePushRequest(req, res)
	local senderName = req.fromInventory
	local sender = peripheral.wrap(senderName)
	if not publicModem.isPresentRemote(senderName) or sender == nil then
		res.status = api.code.INVENTORY_INACCESSIBLE
		res.send("Cannot see inventory")
		return
	end
	---@type ccTweaked.peripheral.itemDetails | nil
	local item = sender.getItemDetail(req.slot)
	if item == nil then
		res.status = api.code.ITEM_INACCESSIBLE
		res.send("Cannot take item from slot from inventory")
		return
	end
	res.ack()
	storage.flush() -- just in case
	local count = req.count
	if count == 0 then
		count = item.maxCount
	end
	print("Pushing item to storage")
	publicIntermediate.pullItems(senderName, req.slot, count)
	if not storage.flush() then
		publicIntermediate.pushItems(senderName, 1, count, req.slot)
		res.status = api.code.PARTIAL_OK
		res.send("Storage System is full")
		return
	end
	res.status = api.code.OK
	res.send("OK")
end

---@param req ccStore.Server.Request
---@param res ccStore.Server.Response
local function handlePullRequest(req, res)
	local recipientName = req.toInventory
	local recipient = peripheral.wrap(recipientName)
	if not publicModem.isPresentRemote(recipientName) or recipient == nil then
		res.status = api.code.INVENTORY_INACCESSIBLE
		res.send("Cannot see inventory")
		return
	end
	res.ack()
	local pulledCount = storage.pullItem(req.item, req.count)
	if pulledCount == 0 then
		res.status = api.code.ITEM_EMPTY
		res.send("We do not have that :(")
		return
	end
	print("Pulled item from storage")
	if pulledCount < req.count then
		res.status = api.code.PARTIAL_OK
		res.send("PARTIAL OK")
	else
		res.status = api.code.OK
		res.send("OK")
	end
end

---@param req ccStore.Server.Request
local function handleRequest(req)
	local res = req.response
	if req.operation == "push" then
		handlePushRequest(req, res)
	elseif req.operation == "pull" then
		handlePullRequest(req, res)
	end
end

print("Serving @", config.namespace)

while true do
	local req = server.recv()
	local res = req.response
	if req.operation == "discover" then
		if req.namespace == "*" or req.namespace == config.namespace then
			res.status = api.code.SERVER_PRESENT
			res.send(config.name)
		end
	elseif req.namespace == config.namespace then
	local successful, err = pcall(handleRequest, req)
		if not successful then
			if not res.sent then
				res.status = api.code.ERROR
				res.send("Internal Server Error")
			end
			print(err)
		end
	end
end