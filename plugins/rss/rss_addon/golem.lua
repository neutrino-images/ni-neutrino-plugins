local media = {}

function media.getAddonMedia(url,extraUrl)
	if url == nil then
		url = extraUrl
	end
	if url then
		local data = getdata(url)
		if data then
			local id = data:match('rmpPlayer(%d+)')
			if id then
				media.VideoUrl= 'http://video.golem.de/download/' .. id .. '?q=high'
			end
		end
	end
end

return media
