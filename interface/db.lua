local ccStore = require("api")

local storageServer = {}

function storageServer.new(namespace)
	---@class database.storageServer
	local o = {
		namespace = namespace
	}

	function o.index()

	end

	return o
end

local database = {
}

function database.wrap(modem)
	---@class database
	o = {
		---@type table<string, database.storageServer>
		servers = {},
		api = ccStore.wrapClient(modem)
	}

	function o.wakeLAN()
		for _, name in ipairs(modem.getNamesRemote()) do
			if modem.hasTypeRemote(name, "computer") then
				peripheral.wrap(name).turnOn()
			end
		end
	end

	function o.discover()
		local foundNames = {}

		print("API.Discover >> \"*\"")
		for namespace in o.api.discover("*") do
			print(string.format("found namespace \"%s\"", namespace))
			foundNames[namespace] = o.servers[namespace] or false
		end

		if #foundNames == 0 then
			print("No servers responded in time.")
			o.servers = {}
			return false
		end

		for serverName, server in pairs(o.servers) do -- remove servers known that aren't found
			local found = false
			for foundName, foundServer in pairs(foundNames) do
				if foundName == serverName then
					found = true
					break
				end
			end
			if not found then
				o.servers[serverName] = nil
			end
		end

		for foundName, foundServer in pairs(foundNames) do -- add servers aren't known that are found
			local found = false
			for serverName, server in pairs(o.servers) do
				if foundName == serverName then
					found = true
					break
				end
			end
			if not found then
				o.servers[foundName] = storageServer.new(foundName)
			end
		end
		return true
	end
end

return database
