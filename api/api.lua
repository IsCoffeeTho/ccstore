local responses = require("responses")
local requests = require("requests")

local api = {
	---@param modem ccTweaked.peripheral.Modem
	wrap = function(modem)
		return {
			---@param port? integer
			---@return Server
			listen = function(port)
				port = port or 1000
				---@class Server
				server = {
					port = port
				}
				---@return ccStore.Server.Request
				function server.recv()
					while true do
						---@type ["modem_message", string, string, integer, boolean|string|number|table, number|nil]
						---@diagnostic disable-next-line
						local event = { os.pullEvent("modem_message") }
						---@diagnostic disable-next-line
						local _, side, channel, replyPort, message, distance = table.unpack(event)
						if channel ~= port then
							os.queueEvent(table.unpack(event))
							break
						end
						---@class ccStore.Server.Request: ccStore.Request
						---@diagnostic disable-next-line
						local request = requests.fromString(message)
						if request ~= nil then
							---@class ccStore.Server.Response: ccStore.Response
							response = {
								msgid = request.msgid
							}
							function response.send()
								response.msgid = request.msgid
								---@diagnostic disable-next-line
								modem.transmit(replyPort, port, responses.toString(response))
							end
							request.response = response
							function request.ack()
								---@diagnostic disable-next-line
								modem.transmit(replyPort, port, responses.toString({
									status = responses.code.ACK,
									msgid = request.msgid
								}))
							end
							request.event = event
							return request
						else
							---@diagnostic disable-next-line
							modem.transmit(replyPort, port, responses.toString({
								status = responses.code.MALFORMED_REQUEST,
								msgid = "",
							}))
						end
					end
				end
				if not modem.isOpen(port) then
					modem.open(port)
				end
				return server
			end,
			---@param message ccStore.Request
			---@param port? integer Port that the API is using.
			---@param timeout? integer Time in seconds to wait for a response.
			---@param timeoutCount? integer Count of messages to attempt before failing.
			---@return ccStore.Response | nil returns a response from the server if the server responds, nil if server doesn't respond
			request = function(message, port, timeout, timeoutCount)
				port = port or 1000
				timeout = timeout or 10
				timeoutCount = timeoutCount or 3
				local recvChannel = math.random(10000, 19999)
				while modem.isOpen(recvChannel) do
					recvChannel = math.random(10000, 19999)
				end
				modem.open(recvChannel)
				modem.transmit(port, recvChannel, requests.toString(message))
				local timeoutId = os.startTimer(10)
				while timeoutCount > 0 do
					---@type ["modem_message", string, string, integer, boolean|string|number|table, number|nil]
					---@diagnostic disable-next-line
					local event = { os.pullEvent() }
					local eventName = event[1]
					if eventName == "modem_message" and event[3] == recvChannel then
						---@diagnostic disable-next-line
						local _, side, channel, replyPort, data, distance = table.unpack(event)
						---@diagnostic disable-next-line
						potential = responses.fromString(data)
						if potential.msgid == message.msgid then
							if potential.status == responses.code.ACK then
								while true do
									---@type ["modem_message", string, string, integer, boolean|string|number|table, number|nil]
									---@diagnostic disable-next-line
									local event = { os.pullEvent("modem_message") }
									---@diagnostic disable-next-line
									_, side, channel, replyPort, data, distance = table.unpack(event)
									if channel == recvChannel then
										---@diagnostic disable-next-line
										return responses.fromString(data)
									else
										os.queueEvent(table.unpack(event))
									end
								end
							else
								---@diagnostic disable-next-line
								return potential
							end
						end
					elseif eventName == "timer" and event[2] == timeoutId then
						timeoutCount = timeoutCount - 1
					end
					os.queueEvent(table.unpack(event))
				end
				return nil
			end
		}
	end
}

return api
