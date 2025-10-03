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
end
if not publicModem.isPresentRemote(config.publicIntermediate) then
	print("FAILED: publicIntermediate is not present on publicNetwork")
end

---@type ccTweaked.peripheral.Inventory[]
local inventories = {}

local function discoverInventories()
	inventories = {}
	local devices = localModem.getNamesRemote()
	if #devices == 0 then
		print("no devices on localModem")
	end
	local function discoverInventory(deviceName)
		if deviceName == config.localIntermediate then
			return
		end
		local deviceType = localModem.hasTypeRemote(deviceName, "inventory")
		if deviceType == nil then
			print("ERR: A device has shown up but is not present on localModem")
			print("Please check hardware and try again")
			return
		end
		if deviceType then
			---@type ccTweaked.peripheral.Inventory
			---@diagnostic disable-next-line
			local device = peripheral.wrap(deviceName)
			inventories[deviceName] = device
		else
			print("Found", deviceName, "but device is not an inventory (could be erroneous)")
		end
	end
	for _, deviceName in pairs(devices) do
		discoverInventory(deviceName)
	end
	print("Discovered", #inventories, "inventories")
end

---@type table<string, itemIdx>
local itemIndex = {}
---@type table<string, table> | table<'*', table<string | integer>>
local freeIndex = {}

local function indexStorage()
	itemIndex = {}
	freeIndex = {}
	for invName, inventory in pairs(inventories) do
		local storage = inventory.list()
		local freeSlots = inventory.size() - #storage
		if freeSlots > 0 then
			if freeIndex['*'] == nil then
				freeIndex['*'] = {}
			end
			freeIndex['*'][invName] = freeSlots
		end
		for slot, item in pairs(storage) do
			print(slot, item.name, item.count)
			if itemIndex[item.name] == nil then
				---@type ccTweaked.peripheral.itemDetails | nil
				local itemDetails = inventory.getItemDetail(slot)
				if itemDetails == nil then
					print("there was a problem accessing an item")
					return
				end
				---@class itemIdx
				local itemIdx = {
					details = {
						maxCount = itemDetails.maxCount
					},
					---@type invIdx[]
					stored = {}
				}
				itemIndex[item.name] = itemIdx
			end
			---@class invIdx
			local invIdx = {
				inventory = inventory,
				count = item.count
			}
			table.insert(
				itemIndex[item.name].stored,
				invIdx
			)
		end
	end
	print(textutils.serialize(itemIndex))
end

discoverInventories()
indexStorage()

local api = require("api")

local publicAPI = api.wrap(publicModem)
local server = publicAPI.listen()

while true do
	local request = server.recv()
end