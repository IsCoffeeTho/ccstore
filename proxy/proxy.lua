local ccstoreAPI = require("api")

local proxy = {}

---@param modem ccTweaked.peripheral.WiredModem
---@param intermediate ccTweaked.peripheral.Inventory
function proxy.wrap(modem, intermediate)
	local client = ccstoreAPI.wrapClient(modem)
	
	local o = {}
	
	function o.discover()
		local namespaces = client.discover("*")
		for namespace in namespaces do
			print(namespace)
		end
	end
	
	return o
end

return proxy