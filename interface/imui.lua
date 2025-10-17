local mons = { peripheral.find("monitor") }
---@type ccTweaked.peripheral.Monitor
local mon = mons[1]

local lastTouch = {
	x = 0,
	y = 0,
}

local imui = {
	awaitingButtons = false,
	backgroundColor = colors.black,
	textColor = colors.white,
	buttonColor = colors.gray,
	buttonTextColor = colors.white,
	buttonTextAlign = "left",
}

function imui.background()
	mon.setBackgroundColor(imui.backgroundColor)
	mon.setCursorPos(1,1)
	mon.clear()
end

---@param x integer
---@param y integer
---@param size integer
---@param text string
function imui.button(x, y, size, text)
	imui.awaitingButtons = true
	local w, h = mon.getSize()
	if x < 0 then
		x = w - x - size
	end
	if y < 0 then
		y = h - y
	end
	mon.setBackgroundColor(imui.buttonColor)
	mon.setTextColor(imui.buttonTextColor)
	mon.setCursorPos(x, y)
	if imui.buttonTextAlign == "left" then
		mon.write(text:sub(1, size))
		mon.write((" "):rep(size - text:len()))
	elseif imui.buttonTextAlign == "center" then
		local padding = size - text:len()
		if padding < 0 then
			padding = 0
		end
		local leftPad = padding / 2
		mon.write((" "):rep(leftPad))
		mon.write(text:sub(1, size))
		mon.write((" "):rep(padding - leftPad))
	elseif imui.buttonTextAlign == "right" then
		mon.write((" "):rep(size - text:len()))
		mon.write(text:sub(1, size))
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
	return mon.getSize()
end

---@param x integer
---@param y integer
---@param text string
function imui.text(x, y, text)
	local w, h = mon.getSize()
	if x < 0 then
		x = w - x
	end
	if y < 0 then
		y = h - y
	end
	mon.setBackgroundColor(imui.backgroundColor)
	mon.setTextColor(imui.textColor)
	mon.setCursorPos(x, y)
	mon.write(text)
end

---@param text string
function imui.print(text)
	mon.write(text.."\n")
end

function imui.await()
	local timeout = os.startTimer(0.05)
	while true do
		local ev = { os.pullEvent() }
		local evName = ev[1]
		if evName == "monitor_touch" and imui.awaitingButtons then
			local _, _, x, y = table.unpack(ev)
			lastTouch = { x = x, y = y }
			break
		elseif evName == "timer" then
			local _, timerId = table.unpack(ev)
			if timerId == timeout then
				break
			end
		end
		os.queueEvent(table.unpack(ev))
	end
	imui.awaitingButtons = false
end

---Function doesn't return but there is no @noreturn
---@param err any
---@param errorMessage? string
function imui.error(err, errorMessage)
	if type(err) == "string" then
		errorMessage = errorMessage or err
	end
	errorMessage = errorMessage or "Unknown; Check console"
	print("ERROR:", err)
	imui.backgroundColor = colors.blue
	imui.textColor = colors.white
	imui.background()
	imui.text(1, 1, "CRITICAL ERROR:")
	imui.text(1, 2, errorMessage)
	os.halt()
end

function imui.init()
	if mon == nil then
		return false
	end
	return true
end

return imui
