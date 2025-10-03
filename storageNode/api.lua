---@param data string
---@return Server.Request.request
local function parseRequest(data)
	---@class Server.Request.Message
	---@field namespace string
	---@field msgid string 

	---@class Server.Request.NullMessage: Server.Request.Message
	---@field operation string

	---@class Server.Request.PushMessage: Server.Request.Message
	---@field operation "push"
	---@field from string "<inventory:slot>"

	---@class Server.Request.PullMessage: Server.Request.Message
	---@field operation "pull"
	---@field to string "<inventory>"

	---@class Server.Request.SearchMessage: Server.Request.Message
	---@field operation "search"
	---@field id ""
	---@field fuzzy boolean Describes wether the search will be inexact and will try to return similar items (name-wise)

	---@class Server.Request.request: Server.Request.NullMessage | Server.Request.PushMessage | Server.Request.PullMessage | Server.Request.SearchMessage

	---@type Server.Request.request
	local message = {
		namespace="",
		msgid="",
		operation=""
	}
	return message
end

---@param req Server.Request.Message
---@return string
local function constructRequest(req)
	return ""
end

---@enum responseCode
--- Some what stolen from geminiprotocol
--- however severly simplified
local responseCode = {
	MISSING_INFO = 10,
	OK = 20,
	ERROR = 40,
	BAD_REQUEST = 50
}

---@param data string
---@return Server.Response.response
local function parseResponse(data)
	---@class Server.Response.response
	---@field msgid string
	---@field status responseCode
	---@field body any

	---@type Server.Response.response
	local message = {
		msgid="",
		status=responseCode.ERROR
	}
	return message
end

---@param res Server.Response.response
---@return string
local function constructResponse(res)
	return ""
end

local api = {
	---@param modem ccTweaked.peripheral.Modem
	wrap = function (modem)
		return {
			---@param port? integer
			---@return Server
			listen = function(port)
				port = port or 1000
				---@class Server
				server = {
					port = port
				}
				---@return Server.Request
				function server.recv()
					while true do
						---@type ["modem_message", string, string, integer, boolean|string|number|table, number|nil]
						---@diagnostic disable-next-line
						local event = {os.pullEvent("modem_message")}
						---@diagnostic disable-next-line
						local _, side, channel, replyPort, message, distance = table.unpack(event)
						if channel ~= port then
							os.queueEvent(table.unpack(event))
							break
						end
						---@class Server.Request
						local request = {
							---@param res Server.Response.Message
							reply = function(res)
								---@diagnostic disable-next-line
								modem.transmit(replyPort, port, constructResponse(res))
							end,
							event = event,
						}
						return request
					end
				end
				if not modem.isOpen(port) then
					modem.open(port)
				end
				return server
			end,
			---@param message Server.Request.Message
			---@param port integer
			request = function(message, port)
				port = port or 1000
				local recvChannel = math.random(1001, 9999)
				while modem.isOpen(recvChannel) do
					recvChannel = math.random(1001, 9999)
				end
				modem.open(recvChannel)
				modem.transmit(port, recvChannel, constructRequest(message))
				while true do
					local event, side, channel, replyPort, data, distance = os.pullEvent("modem_message")
					if channel == recvChannel then
						return parseResponse(data)
					end
					os.queueEvent("modem_message", side, channel, replyPort, data, distance)
				end
			end
		}
	end
}

return api
