local retval = {
	---@param modem ccTweaked.peripheral.WiredModem
	---@param intermediate ccTweaked.peripheral.Inventory
	wrap = function(modem, intermediate)
		local storage = {
			---@type ccTweaked.peripheral.Inventory
			intermediate = nil,
			---@type table<string, ccTweaked.peripheral.Inventory>
			inventories = {},
			---@type table<string, itemIdx>
			itemIndex = {},
			---@type table<string, itemFreeDescriptor> | table<'*', table<string, inventoryFreeDescriptor>>
			freeIndex = {
				["*"] = {}
			}
		}

		function storage.discoverInventories()
			storage.inventories = {}
			local devices = modem.getNamesRemote()
			if #devices == 0 then
				print("No devices on storage network")
			end
			local function discoverInventory(deviceName)
				if deviceName == intermediate then
					return
				end
				local deviceType = modem.hasTypeRemote(deviceName, "inventory")
				if deviceType == nil then
					print("ERR: A device has shown up on the storage network but is not present ")
					print("Please check hardware and try again")
					return
				end
				if deviceType then
					---@type ccTweaked.peripheral.Inventory
					---@diagnostic disable-next-line
					local device = peripheral.wrap(deviceName)
					storage.inventories[deviceName] = device
				else
					print("Found", deviceName, "but device is not an inventory (could be erroneous)")
				end
			end
			for _, deviceName in pairs(devices) do
				discoverInventory(deviceName)
			end
			print("Discovered", #storage.inventories, "inventories")
		end

		function storage.indexStorage()
			storage.itemIndex = {}
			storage.freeIndex = {
				['*'] = {}
			}
			for invName, inventory in pairs(storage.inventories) do
				local items = inventory.list()
				local size = inventory.size()
				local freeSlots = size - #items
				if freeSlots > 0 then
					if storage.freeIndex['*'] == nil then
						storage.freeIndex['*'] = {}
					end
					---@class inventoryFreeDescriptor
					---@field inv ccTweaked.peripheral.Inventory
					---@field slots integer[]
					local invDesc = {
						inv = inventory,
						slots = {}
					}
					storage.freeIndex['*'][invName] = invDesc
					for i = 1, size do
						if items[i] == nil then
							table.insert(invDesc.slots, i)
						end
					end
				end
				for slot, item in pairs(items) do
					---@type ccTweaked.peripheral.itemDetails | nil
					local itemDetails = inventory.getItemDetail(slot)
					if itemDetails == nil then
						print("there was a problem accessing an item")
						return
					end
					if storage.itemIndex[item.name] == nil then
						---@class itemIdx
						local __itemidx = {
							details = {
								maxCount = itemDetails.maxCount
							},
							---@type table<string, storedDescriptor>
							stored = {}
						}
						storage.itemIndex[item.name] = __itemidx
					end
					local itemidx = storage.itemIndex[item.name]
					if itemidx.stored[invName] == nil then
						---@class storedDescriptor
						---@field inv ccTweaked.peripheral.Inventory
						---@fiels slots integer[]
						local storedDescriptor = {
							inv = inventory,
							slots = {}
						}
						itemidx.stored[invName] = storedDescriptor
					end
					local stored = itemidx.stored[invName]
					table.insert(stored.slots, slot)
					if itemDetails.count < itemDetails.maxCount then
						if storage.freeIndex[item.name] == nil then
							---@class itemFreeDescriptor
							---@field inv ccTweaked.peripheral.Inventory
							---@field slot integer
							---@field free integer
							local itemFreeDescriptor = {
								inv = inventory,
								slot = slot,
								free = itemDetails.maxCount - itemDetails.count
							}
							storage.freeIndex[item.name] = itemFreeDescriptor
						end
					end
				end
			end
		end

		---@return itemFreeDescriptor | nil
		function storage.getNextFree()
			local freeindex = storage.freeIndex['*']
			if freeindex == nil then
				return nil
			end
			if #freeindex ~= 0 then
				return nil
			end
			local inventoryName = pairs(freeindex)(freeindex)
			local freeDesc = freeindex[inventoryName]
			local inventory = freeDesc.inv
			local freeSlot = freeDesc.slots[1]
			return {
				inv=inventory,
				slot=freeSlot,
				free=1024
			}
		end

		---@param itemid string
		---@return itemFreeDescriptor | nil
		function storage.determineFree(itemid)
			---@type itemFreeDescriptor
			local freeindex = storage.freeIndex[itemid]
			if freeindex == nil then
				return storage.getNextFree()
			end
			return freeindex
		end

		function storage.pushIntermediate()
			for slot, item in pairs(intermediate.list()) do
				local freeSlot = storage.determineFree(item.name)
				
			end
		end

		return storage
	end
}

return retval
