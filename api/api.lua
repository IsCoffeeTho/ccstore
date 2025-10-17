local api = {
	code = require("responses").code,
	server = require("server"),
	client = require("client")
}

---@param modem ccTweaked.peripheral.WiredModem
function api.wrapServer(modem)
	return api.server.new({}, modem)
end

---@param modem ccTweaked.peripheral.WiredModem
function api.wrapClient(modem)
	return api.client.new({}, modem)
end

return api
