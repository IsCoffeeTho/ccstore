---@diagnostic disable-next-line
if periphemu then
	---@diagnostic disable-next-line
	periphemu.create("top", "monitor")
end

local imui = require("imui")
local interface = require("interface")

term.clear()
term.setCursorPos(1,1)

if not imui.init() then
	print("No monitor is attached, exiting...")
	return
end

print("Running interface daemon")

while true do
	imui.background()
	interface.draw()
	imui.await()
end
