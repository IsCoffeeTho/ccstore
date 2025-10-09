--[[

ccstore <operation> [operation arguments]

]]--

local args = {...}

local ccstore = require("api")

local modem = peripheral.find(
	"modem",
	function(_, v)
		return not v.isWireless()
	end
)

local api = ccstore.wrapClient(modem)

local operation = args[1]

if operation == "discover" then
	print("searching namespace...")
	local namespaces = api.discover(args[2])
	if #namespaces == 0 then
		print("namespace is empty")
		return
	end
	print("found", #namespaces)
	for namespace in namespaces do
		print("-", namespace)
	end
	return
end

print("discovering servers")
local namespaces = api.discover("*")

for namespace in namespaces do
	print("requesting", namespace)
	local query = nil
	local fuzzy = false
	if operation == "search" then
		for i,arg in ipairs(args) do
			if query == nil then
				query = arg
			else
				query = query.." "..arg
			end
		end
		if query[1] == "~" then
			fuzzy = true
			query = string.sub(query, 2)
		end
	end
	api.request({
		namespace = namespace,
		operation = operation,
		fromInventory = args[2] or "",
		slot = args[3] or "",
		item = args[2] or "",
		toInventory = args[3] or "",
		count = tonumber(args[4] or ""),
		query=query,
		fuzzy=fuzzy
	})
end