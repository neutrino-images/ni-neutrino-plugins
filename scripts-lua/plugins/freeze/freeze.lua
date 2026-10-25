--[[
	freeze - Freezes screen

	Copyright (C) 2021 Jacek Jendrzej 'satbaby'
	Copyright (C) 2021 Sven Hoefer 'vanhofen'

	License: WTFPLv2
]]

local n = neutrino()

-- video:Screenshot() exists since Lua API 1.92 and only where Neutrino is
-- built with screenshot support; without it there is nothing to freeze.
local freeze = false
local v = video.new()
if v and v.Screenshot then
	v:Screenshot{}
	freeze = true
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
