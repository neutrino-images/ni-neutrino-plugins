-- url for rssreader.conf
--	{ name = "ComputerBase",	exec = "https://www.computerbase.de/rss/news.xml",addon="ComputerBase", submenu="TechNews"},

local media = {}
function media.getAddonMedia(url)
	local data = getdata(url)
	local video_url = nil
	if data then
		local videos = data:match("<video.->(.-)</video>")
		if videos then
			for video in videos:gmatch('src="(.-)"') do
				local res = video:match("%-(%d+)p")
				local best = 0
				if res then
					local resb = tonumber(res)
					if resb > best then
						video_url = video
						best = resb
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
