local media = {}

function media.getAddonMedia(url,extraUrl)
	local video_url = nil
	local video_url_iso = nil

	if url == nil then
		url = extraUrl
	end
	if url then
		local data = getdata(url)
		if data then
			local playdata = data:match('<div class="videoplayerjw"(.-)</div>' )
			if playdata==nil  then
				local ytdata = data:match('<div class="yt%-video%-container">(.-)</div>')
				if ytdata then
					local id=ytdata:match('/([%w%-]+)?')
					if id == nil then
						id=ytdata:match('embed/(.*)?')
					end
					if id then
						local hasaddon,b = pcall(require,"yt_video_url")
						if hasaddon then
							b.getVideoUrl('https://youtube.com/watch?v=' .. id)
							video_url = b.VideoUrl
						end
					end
				end
			end
			data = nil
			if playdata then
				local sequenz = playdata:match('sequenz="(%d+)"')
				local container = playdata:match('container="(%d+)"')
				local videourls='http://www.heise.de/videout/feed?container=' .. container ..';sequenz=' .. sequenz
				data = getdata(videourls)
			end

			if data then
				local res_tmp = 0
				local iso_tmp = 0
				local res = 0
				for item in data:gmatch('<jwplayer:source(.-)>' ) do
					local typ = item:match('type="(.-)"')
					local quali = item:match('label="(%d+)p"')
					local file = item:match('file="(.-)"')
					if quali then
						res=tonumber(quali)
					end
					if typ=="video/mp4" and res > res_tmp then
						video_url= file
						res_tmp = res
					elseif typ=="video/ios" and res > iso_tmp then
						video_url_iso = file
						iso_tmp = res
					end
					res = 0
				end
			end
		end
	end

	if video_url and #video_url > 8 then
		media.VideoUrl=video_url
	elseif video_url_iso and #video_url_iso > 8 then
		media.VideoUrl=video_url_iso
	end
end

return media
