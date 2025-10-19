local mons = { peripheral.find("monitor") }
---@type ccTweaked.peripheral.Monitor
local mon = mons[1]

local lastTouch = {
	x = 0,
	y = 0,
}

local imui = {
	mon = mon,
	backgroundColor = colors.black,
	textColor = colors.white,
	buttonColor = colors.gray,
	buttonTextColor = colors.white,
	buttonTextAlign = "left",
}

function imui.background()
	imui.mon.setBackgroundColor(imui.backgroundColor)
	imui.mon.setCursorPos(1, 1)
	imui.mon.clear()
end

---@param x integer
---@param y integer
---@param size integer
---@param text string
function imui.button(x, y, size, text)
	imui.awaitingButtons = true
	local w, h = imui.mon.getSize()
	if x < 0 then
		x = w - x - size
	end
	if y < 0 then
		y = h - y
	end
	imui.mon.setBackgroundColor(imui.buttonColor)
	imui.mon.setTextColor(imui.buttonTextColor)
	imui.mon.setCursorPos(x, y)
	if imui.buttonTextAlign == "left" then
		imui.mon.write(text:sub(1, size))
		imui.mon.write((" "):rep(size - text:len()))
	elseif imui.buttonTextAlign == "center" then
		local padding = size - text:len()
		if padding < 0 then
			padding = 0
		end
		local leftPad = padding / 2
		imui.mon.write((" "):rep(leftPad))
		imui.mon.write(text:sub(1, size))
		imui.mon.write((" "):rep(padding - leftPad))
	elseif imui.buttonTextAlign == "right" then
		imui.mon.write((" "):rep(size - text:len()))
		imui.mon.write(text:sub(1, size))
	end
	if lastTouch.y == y then
		if lastTouch.x >= x and lastTouch.x <= x + size then
			return true
		end
	end
	return false
end

---@return 1 integer
---@return 2 integer
function imui.getSize()
	return imui.mon.getSize()
end

---@param x integer
---@param y integer
---@param text string
function imui.text(x, y, text)
	local w, h = imui.mon.getSize()
	if x < 0 then
		x = w - x
	end
	if y < 0 then
		y = h - y
	end
	imui.mon.setBackgroundColor(imui.backgroundColor)
	imui.mon.setTextColor(imui.textColor)
	imui.mon.setCursorPos(x, y)
	imui.mon.write(text)
end

---@param text string
function imui.print(text)
	for line in string.gmatch(text, "[^\n]+") do
		imui.mon.write(line)
		local _, y = imui.mon.getCursorPos()
		imui.mon.setCursorPos(1, y + 1)
	end
end

---Function doesn't return but there is no @noreturn
---@param err any
function imui.error(err)
	err = err or "Unknown; Check console"
	print("ERR:", err)
	imui.backgroundColor = colors.blue
	imui.textColor = colors.white
	imui.background()
	imui.text(1, 1, "CRITICAL ERROR:")
	imui.text(1, 2, err)
	os.exit(1)
end

function imui.eventLoop()
	while true do
		local event, side, x, y = os.pullEvent("monitor_touch")
		lastTouch = { x = x, y = y }
	end
end

return imui
