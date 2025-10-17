term.clear()
term.setCursorPos(1, 1)
redstone.setOutput("top", false)
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

local server = ccstoreAPI.wrapServer(publicModem)
server.listen()

print("Discovering inventories")
storage.discoverInventories()
print("Flushing intermediate...")
if storage.flush() then
	print("Flushed intermediate")
else
	print("FAILED: Couldn't flush intermediate")
	return
end

---@param req ccStore.Server.Request.Push
---@param res ccStore.Server.Response
local function handlePushRequest(req, res)
	local senderName = req.fromInventory
	local sender = peripheral.wrap(senderName)
	if not publicModem.isPresentRemote(senderName) or sender == nil then
		res.status = ccstoreAPI.code.INVENTORY_INACCESSIBLE
		res.send("Cannot see inventory")
		return
	end
	---@type ccTweaked.peripheral.itemDetails | nil
	local item = sender.getItemDetail(req.slot)
	if item == nil then
		res.status = ccstoreAPI.code.ITEM_INACCESSIBLE
		res.send("Cannot take item from slot from inventory")
		return
	end
	res.ack()
	storage.flush() -- just in case
	local count = req.count
	if count == 0 then
		count = item.maxCount
	end
	publicIntermediate.pullItems(senderName, req.slot, count)
	if not storage.flush() then
		publicIntermediate.pushItems(senderName, 1, count, req.slot)
		res.status = ccstoreAPI.code.PARTIAL_OK
		res.send("Storage System is full")
		return
	end
	res.status = ccstoreAPI.code.OK
	res.send("OK")
end

---@param req ccStore.Server.Request.Pull
---@param res ccStore.Server.Response
local function handlePullRequest(req, res)
	local recipientName = req.toInventory
	if not publicModem.isPresentRemote(recipientName) then
		res.status = ccstoreAPI.code.INVENTORY_INACCESSIBLE
		res.send("Cannot see \"" .. recipientName .. "\"")
		return
	end
	local recipient = peripheral.wrap(recipientName)
	if recipient == nil then
		res.status = ccstoreAPI.code.INVENTORY_INACCESSIBLE
		res.send("Cannot bind to \"" .. recipientName .. "\"")
		return
	end
	res.ack()
	local pulledCount = storage.pullItem(req.item, req.count)
	if pulledCount == 0 then
		res.status = ccstoreAPI.code.ITEM_EMPTY
		res.send("We do not have that :(")
		return
	end
	if pulledCount < req.count then
		res.status = ccstoreAPI.code.PARTIAL_OK
		res.send("PARTIAL OK")
	else
		res.status = ccstoreAPI.code.OK
		res.send("OK")
	end
end

---@param req ccStore.Server.Request.Search
---@param res ccStore.Server.Response
local function handleSearchRequest(req, res)
	res.status = ccstoreAPI.code.NOT_IMPLEMENTED
	res.send("NOT IMPLEMENTED")
end

---@param req ccStore.Server.Request
---@param res ccStore.Server.Response
local function handleRequest(req, res)
	if req.operation == "ping" then
		res.status = ccstoreAPI.code.PONG
		res.send("PONG")
	elseif req.operation == "push" then
		---@diagnostic disable-next-line
		handlePushRequest(req, res)
	elseif req.operation == "pull" then
		---@diagnostic disable-next-line
		handlePullRequest(req, res)
	elseif req.operation == "search" then
		---@diagnostic disable-next-line
		handleSearchRequest(req, res)
	end
end

---@param req ccStore.RequestMessage.Discover
---@param res ccStore.Server.Response
local function handleDiscover(req, res)
	if req.namespace == "*" or req.namespace == config.namespace then
		res.status = ccstoreAPI.code.SERVER_PRESENT
		res.send(config.namespace)
	end
end

print("Serving @", config.namespace)

redstone.setOutput("top", true)

local function main()
	while true do
		local req = server.recv()
		local res = req.response
		if req.operation == "discover" then
			local successful, err = pcall(handleDiscover, req, res)
			if not successful then
				if not res.sent then
					res.status = ccstoreAPI.code.ERROR
					res.send("Internal Server Error")
				end
				print(err)
			end
		elseif req.namespace == config.namespace then
			local successful, err = pcall(handleRequest, req, res)
			if not successful then
				if not res.sent then
					res.status = ccstoreAPI.code.ERROR
					res.send("Internal Server Error")
				end
				print(err)
			end
		end
	end
end

parallel.waitForAny(main, server.eventLoop)