-- url for rssreader.conf
-- 	{ name = "heise.de",		exec = "https://www.heise.de/newsticker/heise-atom.xml",addon="heise", submenu="TechNews"},

local media = {}

function heise_getVideoUrl(m3u8_url)
	if m3u8_url == nil then return nil end
	local videoUrl = nil
	local res = 0
	local data = getdata(m3u8_url)
	if data then
		local host = m3u8_url:match('([%a]+[:]?//[_%w%-%.]+)/')
		if m3u8_url:find('/master.m3u8') then
			local lastpos = (m3u8_url:reverse()):find("/")
			local hosttmp = m3u8_url:sub(1,#m3u8_url-lastpos)
			if hosttmp then
				host = hosttmp .."/"
			end
		end
		for band, res1, res2, url in data:gmatch('BANDWIDTH=(%d+).-RESOLUTION=(%d+)x(%d+).-\n(.-)\n') do
			if url and res1 then
				local nr = tonumber(res1)
				if nr < 2000 and nr > res then
					res=nr
					if host and url:sub(1,4) ~= "http" then
						url = host .. url
					end
					videoUrl = url
				end
			end
		end
	end
	return videoUrl,res
end

function media.getAddonMedia(url,extraUrl)
	local video_url = nil

	if url == nil then
		url = extraUrl
	end
	if url then
		local data = getdata(url)
			local a = data:match('<script src="(https:.-%d+/.-/%d+)/embedIframeJs')
			local jsakwaurl = data:match('src="(/%w+/akwa/[%w%d]+/js/akwa.js%?%w+)"')
			local entry_id = data:match('entry%-id%s-=%s-"(.-)"')
			if a == nil and jsakwaurl and  entry_id then
				local host = url:match('([%a]+[:]?//[_%w%-%.]+)/')
				data = getdata(host .. jsakwaurl)
				if data then
					local kultura = data:match('"(//[%w%.]+/%w/.-)/embedIframeJs')
					local partnerId = data:match('partner%-id%"%)||(%d+)')
					if kultura and partnerId then
						a = "https:" .. kultura:gsub('"[%w%+%.]+"',partnerId)
					end
				end
			end
		if a then
			a = a .. "/playManifest/entryId"
			if entry_id then
				a = a .. "/" .. entry_id .. "/flavorIds/" .. entry_id .. "/format/applehttp/protocol/https/?callback="
				video_url = heise_getVideoUrl(a)
				if video_url == nil then video_url = a end
			end
		end
		if video_url == nil then
			local ytid = data:match('youtube%.%w+/watch%?v=([_%w%-]+)') or data:match('youtube%.%w+/embed/([_%w%-]+)') or data:match('"youtube"%s+video%-id="([_%w%-]+)"')
			if ytid then
				local hasaddon,b = pcall(require,"yt_video_url")
				if hasaddon then
					b.getVideoUrl('https://youtube.com/watch?v=' .. ytid)
					video_url = b.VideoUrl
				end
			end
		end
	end

	if video_url and #video_url > 8 then
		media.VideoUrl=video_url
	end
end

return media
