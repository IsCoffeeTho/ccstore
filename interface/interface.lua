local imui = require("imui")

function os.halt()
	print("HALTED")
	while true do
		os.sleep(0.05)
	end
end

---@type ccTweaked.peripheral.WiredModem
---@diagnostic disable-next-line
local modem = peripheral.wrap("back")

local ccstore = require("api")
local api = ccstore.wrapClient(modem)

local interface = {
	namespaces = {}
}

function interface.splash()
	imui.background()
	print("Sending wakeup...")
	imui.text(1, 1, "Sending wakeup...")
	for _, name in ipairs(modem.getNamesRemote()) do
		if modem.hasTypeRemote(name, "computer") then
			peripheral.wrap(name).turnOn()
		end
	end
	print("Loading storage system...")
	imui.text(1, 2, "Loading storage system...")

	local nsdr = api.request({
		operation = "discover",
		namespace = "*",
	}, 1000, 0.5, 5)

	if nsdr == nil then
		return imui.error("local namespace discovery failed")
	end
	local namespaces = nsdr.body:gmatch("[^,]+")
end

-- interface.draw = interface.splash
interface.draw = interface.criticalError

return interface
