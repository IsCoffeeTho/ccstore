local imui = require("imui")

local modem = peripheral.wrap("back")

local ccstore = require("api")

---@diagnostic disable-next-line
local api = ccstore.wrap(modem)

local interface = {}

function interface.splash()
	imui.text(1,1, "Loading storage system")
end

interface.draw = interface.splash

return interface