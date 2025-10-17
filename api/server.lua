local responses = require("responses")
local requests = require("requests")

local server = {}

---@param modem ccTweaked.peripheral.Modem
function server.new(modem)
	
	---@class ccStore.server
	local o = {
		port = -1
	}
	
	local requestQueue = {}
	
	function o.eventLoop()
		while true do
			::continue::
			os.sleep(0.05)
			---@type ["modem_message", string, string, integer, boolean|string|number|table, number|nil]
			---@diagnostic disable-next-line
			local event = { os.pullEvent("modem_message") }
			---@diagnostic disable-next-line
			local _, side, channel, replyPort, message, distance = table.unpack(event)
			if channel ~= o.port then
				os.queueEvent(table.unpack(event))
				goto continue
			end
	
			---@class ccStore.Server.Request: ccStore.RequestMessageFormat
			---@diagnostic disable-next-line
			local request = requests.fromString(message)
			if request == nil then
				---@diagnostic disable-next-line
				modem.transmit(replyPort, o.port, responses.toString({
					status = responses.code.MALFORMED_REQUEST,
					msgid = "",
				}))
				goto continue
			end
			---@class ccStore.Server.Request.Discover: ccStore.Request, ccStore.RequestMessage.Discover
			---@class ccStore.Server.Request.Search: ccStore.Request, ccStore.RequestMessage.Search
			---@class ccStore.Server.Request.Pull: ccStore.Request, ccStore.RequestMessage.Pull
			---@class ccStore.Server.Request.Push: ccStore.Request, ccStore.RequestMessage.Push
	
			---@class ccStore.Server.Response: ccStore.Response
			response = {
				acknowledged = false,
				sent = false,
				msgid = request.msgid
			}
	
			---@param body? string
			function response.send(body)
				if body ~= nil then
					response.body = body
				end
				response.msgid = request.msgid
				---@diagnostic disable-next-line
				modem.transmit(replyPort, o.port, responses.toString(response))
				response.acknowledged = true
				response.sent = true
			end
	
			function response.ack()
				---@diagnostic disable-next-line
				modem.transmit(replyPort, o.port, responses.toString({
					status = responses.code.ACK,
					msgid = request.msgid
				}))
				response.acknowledged = true
			end
	
			request.response = response
			request.event = event
			
			table.insert(requestQueue, request)
		end
	end
	
	---@return ccStore.Server.Request
	function o.recv()
		while #requestQueue == 0 do
			os.sleep(0.05)
		end
		return table.remove(requestQueue, 1)
	end

	---@param port? integer
	function o.listen(port)
		if o.port ~= -1 then error("Server is already listening") end
		port = port or 1000
		o.port = port
		
		if not modem.isOpen(o.port) then
			modem.open(o.port)
		end
	end
	
	return o
end

return server