---@diagnostic disable-next-line
if periphemu then
	---@diagnostic disable-next-line
	periphemu.create("top", "monitor")
end

local imui = require("imui")

term.clear()
term.setCursorPos(1,1)

if not imui.init() then
	print("No monitor is attached, exiting...")
	return
end

---@type ccTweaked.peripheral.WiredModem
---@diagnostic disable-next-line
local modem = peripheral.wrap("back")

local db = require("db")

db.wrap(modem)

local function main()
	local function interface_main()
		local interface = require("interface")
		print("Running interface daemon")
		while true do
			interface.draw()
			imui.await()
		end
	end
	
	local worked, error = pcall(interface_main)
	if not worked then
		imui.error(error, "Unhandled exception; check console")
	end
end

parallel.waitForAny(main, db.api.eventLoop)