-- g_savedata table that persists between game sessions
g_savedata = {}
local steam_ids = {}
local rusr = nil
local port = 9008
local auth = "1234567890" -- You should change this to something random, make sure to update the addon too
local debug = false -- All this does is disable the admin check for the hangar command, so you can test it while being admin

function onCreate()
	x = 0
	while x ~= 50 do
		server.announce(".","")
		x=x+1
	end
	for i,e in pairs(server.getPlayers()) do
		steam_ids[e.id] = e.steam_id
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
	if request ~= "/request" then return end
	if reply == "true" then -- Accepted
		server.announce("Door Controls", "Server staff have triggered the panels to open, please open the hangar doors!", rusr)
		rusr = nil
		for i,e in pairs(g_savedata) do
			server.pressVehicleButton(i, "door")
		end
	elseif reply == "false" then -- Denied
		server.announce("Door Controls", "Server staff have denied access to the panels.", rusr)
		rusr = nil
	elseif reply == "busy" then -- Server Busy
		server.announce("Door Controls", "The system is busy, please try again in a few seconds!", rusr)
		rusr = nil
	elseif reply == "auth" then -- Auth Error
		server.announce("Door Controls", "There appears to be a misconfiguration with the addon, please contact the server owner!", rusr)
		rusr = nil
	elseif reply == "to" then -- Timed Out
		server.announce("Door Controls", "Nobody responded to the request, sorry!", rusr)
		rusr = nil
	elseif reply == "rl" then -- Rate Limit
		server.announce("Door Controls", "You are being rate limited, please wait a few seconds!", rusr)
		rusr = nil
	else
		server.announce("Door Controls", "An unknown error has occured, please contact the server owner!", rusr)
		rusr = nil
	end
end

function onCustomCommand(full_message, user_peer_id, is_admin, is_auth, command, ...)
	args = {...}
	if debug then is_admin = false end
	if command == "?hangar" then
		if is_admin then
			for i,e in pairs(g_savedata) do
				server.pressVehicleButton(i, "door")
			end
		else
			if (rusr) then
				server.announce("Door Controls", "A request has already been sent, please wait...", user_peer_id)
				return
			else
				server.httpGet(port, "/request?auth=" .. auth)
				rusr = user_peer_id
				server.announce("Door Controls", "A request has been sent to server staff, please wait...", user_peer_id)
			end
		end
	end
end