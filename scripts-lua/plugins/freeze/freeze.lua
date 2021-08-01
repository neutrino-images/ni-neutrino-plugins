--[[
	freeze - Freezes screen

	Copyright (C) 2021 Jacek Jendrzej 'satbaby'
	Copyright (C) 2021 Sven Hoefer 'vanhofen'

	License: WTFPLv2
]]

local n = neutrino()

local freeze = false
if APIVERSION ~= nil and (APIVERSION.MAJOR > 1 or ( APIVERSION.MAJOR == 1 and APIVERSION.MINOR > 91 )) then
	local v = video.new()
	if v then
		v:Screenshot{}
		freeze = true
	end
else
	if _curl == nil then
		_curl = curl.new()
	end

	local ret, data = _curl:download {url = "http://127.0.0.1/control/screenshot", A = "Mozilla/5.0;", maxRedirs = 5, followRedir = true}
	if ret == CURL.OK and data == "ok" then
		freeze = true
	end
end

if freeze then
	local fh = filehelpers.new()
	local ss = "/tmp/screenshot.png"
	local sf = "/tmp/screenfreeze.png"
	if fh:exist(ss, "f") then
		n:PaintBox(-1, -1, -1, -1, COL.WHITE)
		local sw, sh = n:GetSize(ss)
		n:DisplayImage(ss, 0, 0, sw, sh)
		fh:cp(ss, sf, "a")
		os.remove(ss)
		local msg, data = nil, nil
		repeat
			msg, data = n:GetInput(500)
		until msg == RC.ok or msg == RC.home or msg == RC.setup
		n:PaintBox(-1, -1, -1, -1, COL.BACKGROUND)
	end
end
