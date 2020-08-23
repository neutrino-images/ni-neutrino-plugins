-- url for rssreader.conf
-- 	{ name = "heise.de",		exec = "https://www.heise.de/newsticker/heise-atom.xml",addon="heise", submenu="TechNews"},

local media = {}

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
					local kultura = data:match('https:(//[%w%.]+/%w/.-)/embedPlaykitJs') or data:match('"(//[%w%.]+/%w/.-)/embedIframeJs')
					local partnerId = data:match('"partnerId":(%d+)') or data:match('partner%-id%"%)||(%d+)')
					if kultura and partnerId then
						a = "https:" .. kultura:gsub('"[%w%+%.]+"',partnerId)
					end
				end
			end
		if a then
			a = a .. "/playManifest/entryId"
			if entry_id then
				a = a .. "/" .. entry_id .. "/flavorIds/" .. entry_id .. "/format/applehttp/protocol/https/?callback="
				video_url,_ = getVideoUrlM3U8(a)
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
					if b.UrlVideoAudio then
						media.UrlVideoAudio = b.UrlVideoAudio
						b.UrlVideoAudio = nil
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
