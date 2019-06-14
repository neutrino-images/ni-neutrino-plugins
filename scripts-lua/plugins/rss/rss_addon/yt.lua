local media = {}

function media.getAddonMedia(url,extraUrl)
	local video_url = nil
	local newText = nil
	local json = require "json"
	media.PicUrl={}
	if extraUrl == nil then
		extraUrl = url
	end
	if extraUrl then
		local json_url = 'http://www.youtube.com/oembed?url=' .. extraUrl .. '&format=json'
		local data = getdata(json_url)
		if data then
			local jnTab = json:decode(data)
			if jnTab == nil then return end
			newText = jnTab.title
			if jnTab.thumbnail_url then
				media.PicUrl[#media.PicUrl+1] = jnTab.thumbnail_url
			end
		end
		if newText and #newText > 1 then
			media.newText = newText
		end
	end
	local hasaddon,b = pcall(require,"yt_video_url")
	if hasaddon then
		b.getVideoUrl(extraUrl)
		video_url = b.VideoUrl
	end
	if video_url and #video_url > 8 then
		media.VideoUrl=video_url
	end
end
return media
