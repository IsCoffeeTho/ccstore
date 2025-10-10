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

local function main()
	local interface = require("interface")
	
	print("Running interface daemon")
	
	while true do
		interface.draw()
		imui.await()
	end
end

local worked, error = pcall(main)
if not worked then
	imui.error(error, "Unhandled exception; check console")
end