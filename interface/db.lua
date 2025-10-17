local ccStore = require("api")

local dbServer = {}

function dbServer.new(namespace)
	---@class database.server
	local o = {
		namespace=namespace
	}
	
	function o.index()
		
	end
	
	return o
end

local db = {
	---@type table<string, database.server>
	servers = {}
}

function db.wrap(modem)
	db.api = ccStore.wrapClient(modem)
end

function db.discover()
	local foundNames = {}
	for namespace in db.api.discover("*", 1000, 0.5, 3) do
		foundNames[namespace] = db.servers[namespace] or false
	end
	for serverName, server in pairs(db.servers) do
		local found = false
		for foundName, foundServer in pairs(foundNames) do
			if foundName == serverName then
				found = true
				break
			end
		end
		if not found then
			db.servers[serverName] = nil
		end
	end
	for foundName, foundServer in pairs(foundNames) do
		local found = false
		for serverName, server in pairs(db.servers) do
			if foundName == serverName then
				found = true
				break
			end
		end
		if not found then
			db.servers[foundName] = dbServer.new(foundName)
		end
	end
end



return db
