local imui = require("imui")

local interface = {}

function interface.splash()
	local w, h = imui.getSize()
	local splashText = "Loading storage system"
	imui.text((w - splashText:len() + 1) / 2, h / 2, splashText)
end

interface.draw = interface.splash

return interface