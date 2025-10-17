local imui = require("imui")

function os.halt()
	::halt_loop::
	goto halt_loop
end

term.clear()
term.setCursorPos(1,1)

if not imui.init() then
	print("No monitor is attached, exiting...")
	return
end

---@type ccTweaked.peripheral.WiredModem
---@diagnostic disable-next-line
local modem = peripheral.wrap("back")

local databaseAPI = require("db")

local db = databaseAPI.wrap(modem)

local function main()
	local function interface_main()
		local interfaceSys = require("interface")
		local interface = interfaceSys.wrap(db)
		if interface == nil then
			error("Failed to start interface")
			return
		end
		print("Running interface daemon")
		while true do
			if interface.draw == nil then
				error("interface.draw was set to a nil value")
				return
			end
			interface.draw()
			imui.await()
		end
	end
	
	local worked, error = pcall(interface_main)
	if not worked then
		imui.error(error, "Unhandled exception; check console")
		os.halt()
	end
end

parallel.waitForAny(main, db.api.eventLoop)