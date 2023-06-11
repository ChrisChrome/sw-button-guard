-- g_savedata table that persists between game sessions
g_savedata = {}
local steam_ids = {}
local rusr = nil
local port = 9008
local auth = "1234567890" -- You should change this to something random, make sure to update the addon too
local debug = true        -- All this does is disable the admin check for the hangar command, so you can test it while being admin
local tick = 0
local server_identity = "Server"

function onCreate()
	server.command("ident")
	for i, e in pairs(server.getPlayers()) do
		steam_ids[e.id] = e.steam_id
	end
end

function onTick()
	if (rusr) then
		tick = tick + 1
		if (tick == 60) then
			server.httpGet(port, "/request?auth=" .. auth .. "&steamid=" .. steam_ids[rusr])
		end
		if (tick > 65) then
			tick = 65 -- Keep it in a loop until
		end
	end
end

function onPlayerJoin(steam_id, name, peer_id, is_admin, is_auth)
	steam_ids[peer_id] = steam_id
end

function onPlayerLeave(steam_id, name, peer_id, is_admin, is_auth)
	steam_ids[peer_id] = nil
end

function onVehicleSpawn(vehicle_id, peer_id, x, y, z, cost)
	if (peer_id ~= -1) then return end
	data = server.getVehicleData(vehicle_id)
	if (data.tags[1] == "hangar") then
		g_savedata[vehicle_id] = true
	end
end

function httpReply(iport, request, reply)
	if iport ~= port then return end
	if reply == "open" then -- Accepted
		server.announce("Door Controls", "Server staff have triggered the panels to open, please open the hangar doors!",
			rusr)
		rusr = nil
		for i, e in pairs(g_savedata) do
			server.pressVehicleButton(i, "door")
		end
		server.setPlayerPos(user_peer_id, server.getZones()[1].transform)
	elseif reply == "deny" then -- Denied
		server.announce("Door Controls", "Server staff have denied access to the panels.", rusr)
		rusr = nil
	elseif reply == "busy" then -- Server Busy
		server.announce("Door Controls", "The system is busy, please try again in a few seconds!", rusr)
		rusr = nil
	elseif reply == "auth" then -- Auth Error
		server.announce("Door Controls",
			"There appears to be a misconfiguration with the addon, please contact the server owner!", rusr)
		rusr = nil
	elseif reply == "to" then -- Timed Out
		server.announce("Door Controls", "Nobody responded to the request, sorry!", rusr)
		rusr = nil
	elseif reply == "rl" then -- Rate Limit
		server.announce("Door Controls", "You are being rate limited, please wait a few seconds!", rusr)
		rusr = nil
	elseif reply == "wait" then -- Waiting on a response from a staff member, set the tick counter to 0 and wait for it to try again, dont clear rusr or respond
		if debug then server.announce("Door Controls", "Waiting for a response from a staff member...", rusr) end
		tick = 0
	else
		server.announce("Door Controls", "An unknown error has occured, please contact the server owner!", rusr)
		if debug then server.announce("Door Controls", "Error: " .. reply, rusr) end
		rusr = nil
	end
end

function onCustomCommand(full_message, user_peer_id, is_admin, is_auth, command, ...)
	args = { ... }
	if debug then is_admin = false end
	if command == "?hangar" then
		if is_admin then
			for i, e in pairs(g_savedata) do
				server.pressVehicleButton(i, "door")
			end
			server.setPlayerPos(user_peer_id, server.getZones()[1].transform)
		else
			if ((rusr ~= user_peer_id) and (rusr ~= nil)) then return end
			server.httpGet(port, "/request?auth=" .. auth .. "&steamid=" .. steam_ids[user_peer_id] .. "&name=" .. encode(server.getPlayerName(user_peer_id)) .. "&server=" .. encode(server_identity))
			rusr = user_peer_id
			server.announce("Door Controls", "A request has been sent to server staff, please wait...", user_peer_id)
		end
	end
	if command == "identresp" and user_peer_id == -1 then -- This is a response to the ident from and identity provider
		local ident = ""
		for i,v in ipairs(args) do
			ident = ident .. v .. " "
		end
		ident = string.sub(ident, 1, -2)
		server_identity = ident
	end
end

function encode(str)
	if str == nil then
		return ""
	end
	str = string.gsub(str, "([^%w _ %- . ~])", cth)
	str = str:gsub(" ", "%%20")
	return str
end

function cth(c)
	return string.format("%%%02X", string.byte(c))
end