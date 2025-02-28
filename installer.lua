print("CCSTORE Install Tool")
print("q to exit")
print("")

local versions = {
	["Standalone"] = {
		
	},
	["Image"] = {
		
	},
	["Server"] = {
		
	},
	["Proxy"] = {
		
	}
}

local versionKeys = {}
local i = 1
for version,_ in pairs(versions) do
	versionKeys[i] = version
	i = i + 1
end

function askWhichVersion()
	print("Which installation:")
	for idx,version in ipairs(versionKeys) do
		print(tostring(idx)..". "..version)
	end
	print("[1-"..#versionKeys.."] ")
end

function install()
	local version = nil
	local versionName = nil
	repeat
		askWhichVersion()
		local response = io.stdin:read()
		if response == "q" then
			return
		end
		local select = tonumber(response)
		if versionKeys[select] ~= nil then
			versionName = versionKeys[select]
			version = versions[versionKeys[select]]
		end
	until version ~= nil
	print("Installing "..versionName)
end

install()