local media = {}

function pos_html_reader(text)
 	text = text:match("<body.->(.-)</body>")
	text = text:gsub('<!%-%-.-%-%->',"")
	text = text:gsub('<style.-</style>',"")
	text = text:gsub('<script.-</script>',"")
 	text = text:gsub('<title>.-</title>',"")
	text = text:gsub('<header.-</header>',"")
	text = text:gsub('<span.-</span>',"")
	text = text:gsub('<li.-</li>',"")
	text = text:gsub('<a href .->',"")
	text = text:gsub('<li>.-</li>',"")
	text = text:gsub('<img .->',"")
	text = text:gsub('<h2.-</h2>',"")
	text = text:gsub('<.->', "")
	text = text:gsub('%-%->', "")
	text = text:gsub('[ ]+\n', "")
	text = text:gsub('^\n*', "")
	text = text:gsub('[\r]+', "\n")
	text = text:gsub('[\n\n\n]+', "\n")
	text = text:gsub('\n*$', "")
	return text
end

function media.getAddonMedia(url)
	local data = getdata(url)
	if data then
		local video_url = nil
		media.VideoUrl = nil
		local ytid = data:match('youtube%.com/watch%?v=([_%w%-]+)') or data:match('youtube%.com/embed/([_%w%-]+)')
		data = pos_html_reader(data)
		media.newText = data
		if ytid then
			local hasaddon,b = pcall(require,"yt_video_url")
			if hasaddon then
				b.getVideoUrl('https://youtube.com/watch?v=' .. ytid)
				video_url = b.VideoUrl
			end
		end
		if video_url and #video_url > 8 then
			media.VideoUrl=video_url
		end
	end
end
return media
