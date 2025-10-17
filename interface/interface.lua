local imui = require("imui")

function os.halt()
	print("HALTED")
	while true do
		os.sleep(0.05)
	end
end

local interface = {}

local function log(text)
	print(text)
	imui.print(text)
end

function interface.splash()
	imui.background()

	log("Sending wakeup...")
	for _, name in ipairs(modem.getNamesRemote()) do
		if modem.hasTypeRemote(name, "computer") then
			peripheral.wrap(name).turnOn()
		end
	end

	log("Discovering storage systems...")
	if not db.discover() then
		
		return imui.error("local namespace discovery failed")
	end
	log("Storage System is ready")
	os.sleep(1)
	imui.backgroundColor = colors.pink
	imui.textColor = colors.white
	interface.draw = interface.refresh
end

function interface.refresh()
	imui.background()
	imui.print("STORAGE SYSTEM")
	os.halt()
end

interface.draw = interface.splash

return interface
