local imui = require("imui")

local interface = {}

---@param db database
function interface.wrap(db)
	---@class interface
	o = {}
	
	function o.log(text)
		print(text)
		imui.print(text)
	end
	
	function o.boot()
		imui.background()

		o.log("Sending wakeup...")
		db.wakeLAN()

		o.log("Discovering storage systems...")
		if not db.discover() then
			return imui.error("local namespace discovery failed")
		end
		o.log("Storage System is ready")
		os.sleep(1)
		o.draw = o.splash
	end
	
	function o.splash()
		imui.backgroundColor = colors.pink
		imui.textColor = colors.white
		imui.background()
		imui.print("STORAGE SYSTEM")
		os.exit()
	end
	
	o.draw = o.boot
	
	return o
end

return interface
