local imui = require("imui")

local interface = {}

---@param db database
function interface.wrap(db)
	local function log(text)
		print(text)
		imui.print(text)
	end
	
	function o.splash()
		imui.background()

		log("Sending wakeup...")
		db.wakeLAN()

		log("Discovering storage systems...")
		if not db.discover() then
			return imui.error("local namespace discovery failed")
		end
		log("Storage System is ready")
		os.sleep(1)
		imui.backgroundColor = colors.pink
		imui.textColor = colors.white
		o.draw = o.refresh
	end
	
	function o.refresh()
		imui.background()
		imui.print("STORAGE SYSTEM")
		os.halt()
	end
	
	o.draw = o.splash
	
	---@class interface
	o = {}
end

return interface
