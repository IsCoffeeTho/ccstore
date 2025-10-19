local imui = require("imui")

local exitCode = 0
local exitProgram = false

---@param code? integer
---@diagnostic disable-next-line
function os.exit(code)
	code = code or 0
	exitCode = code
	exitProgram = true
end

function os.eventLoop()
	while not exitProgram do
		os.sleep(0.05)
	end
end

term.clear()
term.setCursorPos(1,1)

if imui.mon == nil then
	print("No monitor is attached, exiting...")
	return
end

---@type ccTweaked.peripheral.WiredModem
---@diagnostic disable-next-line
local modem = peripheral.wrap("back")

local databaseAPI = require("db")

local db = databaseAPI.wrap(modem)

local function main()
	local function pMain()
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
				os.exit(1)
			end
			interface.draw()
			imui.await()
		end
	end
	
	local worked, error = pcall(pMain)
	if not worked then
		imui.error(error)
		os.exit(1)
	end
end

parallel.waitForAny(main, db.api.eventLoop, os.eventLoop)

return exitCode