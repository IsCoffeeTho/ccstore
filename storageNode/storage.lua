local retval = {
	---@param modem ccTweaked.peripheral.WiredModem
	---@param intermediate ccTweaked.peripheral.Inventory
	wrap = function(modem, intermediate)
		local intermediateName = peripheral.getName(intermediate)

		local storage = {
			---@type ccTweaked.peripheral.Inventory
			intermediate = nil,
			---@type table<string, storage.inventory>
			inventories = {},
			---@type table<string, storage.inventory>
			uncached = {}
		}

		local slot_t = {}
		---@param inventory storage.inventory
		---@param slot_n integer
		---@return storage.slot | nil
		function slot_t.new(inventory, slot_n)
			---@class storage.slot
			---@field inventory storage.inventory
			---@field slot_n integer
			---@field itemId string
			---@field count integer
			---@field maxCount integer
			---@field free integer
			local o = {
				inventory = inventory,
				slot_n = slot_n
			}

			local function markAsFree()
				o.itemId = ""
				o.used = 0
				o.maxCount = 64
				o.free = o.maxCount - o.used
				for i, slot in ipairs(o.inventory.slots) do -- delete from slot index
					if slot == o then
						table.remove(o.inventory.slots, i)
						o.inventory.free = o.inventory.free + 1
						return
					end
				end
			end

			local function markAsUsed()
				for i, slot in ipairs(o.inventory.slots) do
					if slot == o then
						return
					end
				end
				table.insert(o.inventory.slots, o)
				o.inventory.free = o.inventory.free - 1
			end

			table.insert(o.inventory.slots, o)

			---Updates the slot info with real data
			function o.update()
				---@type ccTweaked.peripheral.itemDetails | nil
				local itemDetails = o.inventory.peripheral.getItemDetail(o.slot_n)
				if itemDetails == nil then
					markAsFree()
					return
				end
				o.itemId = itemDetails.name
				o.used = itemDetails.count
				o.maxCount = itemDetails.maxCount
				o.free = o.maxCount - o.used
				markAsUsed()
			end

			o.update()

			---Push items to slot
			---@param inv ccTweaked.peripheral.Inventory The inventory from which the item resides
			---@param slot integer The slot of the inventory from which the item resides
			---@return integer Amount of items pushed to slot
			function o.push(inv, slot)
				local pushed = inv.pushItems(o.inventory.id, slot, o.free, o.slot_n)
				o.update()
				return pushed
			end

			---Pull items from slot
			---@param inv ccTweaked.peripheral.Inventory The inventory to pull the item to
			---@param slot? integer The slot of the inventory from which the item resides
			---@return integer Amount of items pulled from slot
			function o.pull(inv, slot)
				local pulled = inv.pullItems(o.inventory.id, o.slot_n, o.free, slot)
				o.update()
				return pulled
			end

			---@return string
			function o.toString()
				return string.format("slot {\n  itemId: \"%s\",\n  count: %d,\n  free: %d,\n  total: %d\n}", o.itemId,
					o.count, o.free, o.maxCount)
			end

			return o
		end

		---@class storage.inventory.static
		local inventory_t = {}
		---@param invName string
		---@return storage.inventory | nil
		function inventory_t.new(invName)
			---@class storage.inventory
			---@field peripheral ccTweaked.peripheral.Inventory wrap of peripheral
			---@field id string Identifier on the network
			---@field size integer Number of slots in peripheral
			---@field free integer Number of slots that are empty in peripheral
			---@field slots storage.slot[] Slot descriptors of slots with items in peripheral
			local o = {
				---@diagnostic disable-next-line
				peripheral = peripheral.wrap(invName),
				id = invName,
			}
			if o.peripheral == nil then return nil end
			o.size = o.peripheral.size()

			function o.update()
				local itemList = o.peripheral.list()
				o.free = o.size - #itemList

				local freeSlots = {}
				for i = 1, o.size do
					table.insert(freeSlots, true)
				end

				for _, slot in pairs(o.slots) do
					slot.update()
					if slot.itemId ~= "" then
						freeSlots[slot.slot_n] = false
					end
				end
				for slot, item in pairs(itemList) do
					if freeSlots[slot] then
						slot_t.new(o, slot)
					end
				end
			end

			o.update()

			---@return storage.slot | nil
			function o.getNextFree()
				---@type boolean[]
				local freeSlots = {}
				for i = 1, o.size do
					table.insert(freeSlots, true)
				end
				for _, slot in pairs(o.slots) do
					freeSlots[slot.slot_n] = false
				end
				for slot_n, free in ipairs(freeSlots) do
					if free then
						return slot_t.new(o, slot_n)
					end
				end
				return nil
			end

			---@return storage.slot | nil
			function o.find(itemId)
				---@type storage.slot | nil
				local lowestCountSlot = nil
				for i, slot in ipairs(o.slots) do
					if slot.itemId == itemId then
						if lowestCountSlot == nil or lowestCountSlot.count < slot.count then
							lowestCountSlot = slot
						end
					end
				end
				return lowestCountSlot
			end

			---@return string
			function o.toString()
				return string.format("inventory {\n  id: \"%s\",\n  used: %d,\n  free: %d,\n  total: %d\n}", o.id,
					#o.slots, o.free, o.size)
			end

			return o
		end

		function storage.discoverInventories()
			storage.inventories = {}
			local devices = modem.getNamesRemote()
			for _, deviceName in pairs(devices) do
				if modem.getTypeRemote("inventory") then
					if deviceName ~= intermediateName then
						storage.inventories[deviceName] = inventory_t.new(deviceName)
					end
				end
			end
		end

		function storage.index()
			for _, o in pairs(storage.inventories) do
				o.update()
			end
		end

		---@return storage.slot | nil
		function storage.find(itemId)
			---@type storage.slot | nil
			local lowestCountSlot = nil
			for name, o in pairs(storage.inventories) do
				local found = o.find(itemId)
				if found ~= nil then
					if lowestCountSlot == nil or lowestCountSlot.count < found.count then
						lowestCountSlot = found
					end
				end
			end
			return lowestCountSlot
		end

		function storage.count(itemId)
			local accumulative = 0
			for name, o in pairs(storage.inventories) do
				local found = o.find(itemId)
				if found ~= nil then
					accumulative = accumulative + found.count
				end
			end
			return accumulative
		end

		---@return storage.slot | nil
		function storage.getNextFree()
			for name, o in pairs(storage.inventories) do
				local free = o.getNextFree()
				if free ~= nil then
					return free
				end
			end
			return nil
		end

		---@param slot integer
		---@param item? ccTweaked.peripheral.item
		---@return integer Amount of items pushed into system
		function storage.push(slot, item)
			item = item or intermediate.getItemDetail(slot) or { count = 0 }
			local prePushCount = item.count
			while item.count > 0 do
				local pushSlot = storage.find(item.name)
				if pushSlot == nil or pushSlot.free == 0 then
					local freeSlot = storage.getNextFree()
					if freeSlot == nil then return prePushCount - item.count end
					pushSlot = freeSlot
				end
				local pushed = pushSlot.push(intermediate, slot)
				item.count = item.count - pushed
			end
			return prePushCount - item.count
		end

		function storage.flush()
			for slot, item in pairs(intermediate.list()) do
				local needsToPush = item.count
				if storage.push(slot, item) ~= needsToPush then return false end
			end
			return true
		end

		---@param itemId string
		---@param count? integer
		---@return integer Amount of items pulled from system
		function storage.pull(itemId, count)
			count = count or 0
			local pulled = 0
			for name, o in pairs(storage.inventories) do
				local found = o.find(itemId)
				while found ~= nil do
					if count == 0 then count = found.maxCount end
					local pullCount = found.count < count and count or found.count
					pullCount = intermediate.pullItems(o.id, found.slot_n, pullCount)
					pulled = pulled + pullCount
					if pulled >= count then
						return pulled
					end
				end
			end
			return pulled
		end

		return storage
	end
}

return retval
