local media = {}

function media.getAddonMedia(url,extraUrl)
	local video_url = nil

	if url == nil then
		url = extraUrl
	end
	if url then
-- 		http://winfuture.de/videos/Spiele/Top-5-Diese-kaputten-Spiele-haben-Suchtpotenzial-18969.html
		local id = url:match('%-(%d+)%.html')
		video_url = "http://videos.winfuture.de/" .. id .. ".mp4"

	end

	if video_url and #video_url > 8 then
		media.VideoUrl=video_url
	end
end

return media
