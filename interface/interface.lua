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
	local function log(text)
		print(text)
		imui.print(text)
	end
	
	log("Sending wakeup...")
	imui.text(1, 1, "Sending wakeup...")
	for _, name in ipairs(modem.getNamesRemote()) do
		if modem.hasTypeRemote(name, "computer") then
			peripheral.wrap(name).turnOn()
		end
	end
	log("Discovering storage systems...")

	local nsdr = api.discover("*", 1000, 0.5, 3)

	if nsdr == nil then
		return imui.error("local namespace discovery failed")
	end
	log("Indexing...")
	for namespace in nsdr do
		print(namespace)
	end
	log("HALTED; check console")
	while true do
		os.sleep(1)
	end
end

interface.draw = interface.splash

return interface
