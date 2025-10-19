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

local database = {}

---@param modem ccTweaked.peripheral.WiredModem
function database.wrap(modem)
	---@class database
	local o = {
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
			table.insert(foundNames, namespace)
		end

		if #foundNames == 0 then
			print("No servers responded in time.")
			o.servers = {}
			return false
		end

		for knownServer, _ in pairs(o.servers) do -- remove servers known that aren't found
			local known = false
			for _, foundServer in ipairs(foundNames) do
				if foundServer == knownServer then
					known = true
					break
				end
			end
			if not known then
				o.servers[knownServer] = nil
			end
		end

		for _, foundServer in ipairs(foundNames) do -- add servers aren't known that are found
			local serverUnknown = false
			for knownServer, server in pairs(o.servers) do
				if foundServer == knownServer then
					serverUnknown = true
					break
				end
			end
			if not serverUnknown then
				o.servers[foundName] = storageServer.new(foundName)
			end
		end
		return true
	end

	return o
end

return database
