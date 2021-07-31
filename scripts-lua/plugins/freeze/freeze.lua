--[[
	freeze - Freezes screen

	Copyright (C) 2021 Jacek Jendrzej 'satbaby'

	License: WTFPLv2
]]

function getdata(Url,outputfile)
	if Url == nil then return nil end
	if Curl == nil then
		Curl = curl.new()
	end
	local ret, data = Curl:download{url=Url,A="Mozilla/5.0;",maxRedirs=5,followRedir=true,o=outputfile }
	if ret == CURL.OK then
		if outputfile then
			return 1
		end
		return data
	else
		return nil
	end
end

	local n = neutrino()
	local ok = getdata("http://127.0.0.1/control/screenshot")
	if ok == "ok" then
		local fh = filehelpers.new()
		local namepic = "/tmp/screenshot"
		local fpic = namepic .. ".png"
		local hpic = false
		if fh:exist(fpic, "f") then
			hpic = true
		else
			fpic = namepic .. ".jpg"
			if fh:exist(fpic, "f") then
				hpic = true
			end
		end
		if fpic then
			local cp = cpicture.new{parent=nill, x=0, y=0, dx=0, dy=0, image=fpic}
			cp:paint()
			local msg, data = nil,nil
			repeat
			msg, data = n:GetInput(500)
			until msg == RC.home or msg == RC.setup
			os.remove(fpic)
		end
	end
