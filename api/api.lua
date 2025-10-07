local responses = require("responses")
local requests = require("requests")

---@param length? integer
---@return string
local function newMsgID(length)
	length = length or 16
	local bucket = ""
	local retval = ""
	local bucketLength = bucket:len()
	for i = 1, length do
		local r = math.random(bucketLength)
		retval = retval + bucket[r]
	end
	return retval
end

local api = {
	newMsgID = newMsgID,
	---@param modem ccTweaked.peripheral.Modem
	wrapServer = function(modem)
		return {
			code = responses.code,
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
								modem.transmit(replyPort, port, responses.toString(response))
								response.acknowledged = true
								response.sent = true
							end

							function response.ack()
								---@diagnostic disable-next-line
								modem.transmit(replyPort, port, responses.toString({
									status = responses.code.ACK,
									msgid = request.msgid
								}))
								response.acknowledged = true
							end

							request.response = response
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
			end
		}
	end,
	wrapClient = function(modem)
		---@param message ccStore.Request
		---@param port? integer Port that the API is using.
		---@param timeout? integer Time in seconds to wait for a response.
		---@param timeoutCount? integer Count of messages to attempt before failing.
		---@return ccStore.Response | nil returns a response from the server if the server responds, nil if server doesn't respond
		local function request(message, port, timeout, timeoutCount)
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
			return {
				msgid=message.msgid,
				status=responses.code.REQUEST_TIMEOUT,
				body="Request Timeout; Server did not respond in time"
			}
		end

		return {
			code = responses.code,
			request = request,
			---@param namespace string
			discover = function(namespace)

			end,
			---@param namespace string
			---@param fromInventory string
			---@param slot integer
			push = function(namespace, fromInventory, slot)
				local req = request({
					namespace = namespace,
					msgid = newMsgID(),
					fromInventory = fromInventory,
					slot = slot
				})
				if req == nil then return false end
				if 20 < req.status or req.status >= 30 then return false end
				return true
			end,
			---@param namespace string
			---@param itemId string
			---@param toInventory string
			---@param count? integer
			pull = function(namespace, itemId, toInventory, count)
				count = count or 1
				local req = request({
					namespace = namespace,
					msgid = newMsgID(),
					item = itemId,
					count = count,
					toInventory = toInventory
				})
				if req == nil then return false end
				if 20 < req.status or req.status >= 30 then return false end
				return true
			end,
			---@param namespace string
			---@param query string
			---@param fuzzy? boolean
			search = function(namespace, query, fuzzy)
				fuzzy = fuzzy or false
				local req = request({
					namespace = namespace,
					msgid = newMsgID(),
					query = query,
					fuzzy = fuzzy
				})
				if req == nil then return false end
				if 20 < req.status or req.status >= 30 then return false end
				return true
			end,
		}
	end
}

api.code = responses.code

return api
