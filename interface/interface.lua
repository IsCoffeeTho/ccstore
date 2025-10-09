local imui = require("imui")

---@type ccTweaked.peripheral.WiredModem
---@diagnostic disable-next-line
local modem = peripheral.wrap("back")

local ccstore = require("api")

local api = ccstore.wrapClient(modem)

local interface = {
	namespaces = {}
}

local errorMessage = "Unknown; Check console"
function interface.criticalError()
	print("ERROR:",errorMessage)
	imui.backgroundColor = colors.blue
	imui.textColor = colors.white
	imui.background()
	imui.text(1,1,"CRITICAL ERROR:")
	imui.text(1,2, errorMessage)
	os.exit(1)
end

function interface.splash()
	imui.background()
	print("Sending wakeup...")
	imui.text(1,1, "Sending wakeup...")
	for _,name in ipairs(modem.getNamesRemote()) do
		if modem.hasTypeRemote(name, "computer") then
			peripheral.wrap(name).turnOn()
		end
	end
	print("Loading storage system...")
	imui.text(1,2, "Loading storage system...")
	
	local nsdr = api.request({
		operation="discover",
		namespace="*",
	}, 1000, 0.5, 5)
	
	if nsdr == nil then
		errorMessage = "local namespace discovery failed"
		interface.draw = interface.criticalError
		return
	end
	local namespaces = nsdr.body:gmatch("[^,]+")
end

-- interface.draw = interface.splash
interface.draw = interface.criticalError

return interface