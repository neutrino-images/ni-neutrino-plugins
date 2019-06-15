local media = {}
function media.getAddonMedia(url)
	local domain = 'http://www.3sat.de/mediathek/xmlservice/web/beitragsDetails?ak=web&id='
	local id = url:match('/?obj=(%d+)$?')
	local video_url = nil
	media.PicUrl={}
	if id then
		local data = getdata(domain .. id)
		if data then
			local image = data:match('key="485x273">(.-)<')
			if image then
				media.PicUrl[#media.PicUrl+1] = image
			end
			local res = 0
			for item in data:gmatch('<formitaet(.-)</formitaet>') do
				local basetype = item:match('basetype="(.-)"')
				local width = item:match('<width>(%d+)</width>')
				local url = item:match('<url>(.-%.mp4)</url>')
				if url and width then
					local nr = tonumber(width)
					if nr < 2000 and nr > res then
						res=nr
						video_url = url
					end
				end
			end
		end
	end
	if video_url and #video_url > 8 then
		media.VideoUrl=video_url
	end
end
return media
