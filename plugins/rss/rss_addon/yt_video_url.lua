json = require "json"
local media = {}

function pop(cmd)
	local f = assert(io.popen(cmd, 'r'))
	local s = assert(f:read('*a'))
	f:close()
	return s
end

function media.getVideoUrl(yurl)
	if yurl == nil then return 0 end

	local h = hintbox.new{caption="Please Wait ...", text="I'm Thinking."}
	if h then
		h:paint()
	end
	local data = getdata(yurl)
	if data then
		local m3u_url = data:match('hlsManifestUrl.:.(https:.-m3u8)') or data:match('hlsManifestUrl..:..(https:\\.-m3u8)') or data:match('hlsvp.:.(https:\\.-m3u8)')
		if m3u_url == nil then
			m3u_url = data:match('hlsManifestUrl.:.(https%%3A%.-m3u8)') or data:match('hlsManifestUrl..:..(https%%3A%%2F%%2F.-m3u8)') or data:match('hlsvp=(https%%3A%%2F%%2F.-m3u8)')
			if m3u_url then
				m3u_url = unescape_uri(m3u_url)
			end
		end
		if m3u_url then
			m3u_url = m3u_url:gsub("\\", "")
			video_url = getVideoUrlM3U8(m3u_url)
			if video_url and #video_url > 8 then
				media.VideoUrl=video_url
			end
			if video_url then
				if h then
					h:hide()
				end
				return
			end
		end
	end
	data = pop("python /usr/bin/yt-dlp --dump-single-json " .. yurl)
	local itagnum = 0
	local urls = {}
	media.VideoUrl = nil

	if data then
		local jnTab = json:decode(data)
		if jnTab ~= nil then
			for k,v in pairs(jnTab.formats) do
				if v and v.format and v.quality and v.url then
					itagnum = tonumber(v.format_id)
					if itagnum then
						urls[itagnum] = v.url
					end
				end
			end
		end
		local audio = urls[140] or urls[251] or urls[250] or urls[249]
		local maxRes = getMaxVideoRes()
		local video = urls[628]
		if maxRes < 2561 or video == nil then
			video = urls[623] or video
		end
		if maxRes < 1981 or video == nil then
			video = urls[270] or urls[137] or urls[617] or urls[614] or urls[248] or urls[616] or video
		end
		if maxRes < 1281 or video == nil then
			video = urls[22] or urls[232] or urls[136] or urls[612] or urls[609] or urls[247] or video
		end
		if maxRes < 855 or video == nil then
			video = urls[231] or urls[135] or urls[606] or urls[244] or video
		end
		if maxRes < 641 or video == nil then
			video = urls[230] or urls[134] or urls[18] or urls[605] or urls[243] or video
		end
		if audio then
			media.UrlVideoAudio = audio
		end
		if video then
			media.VideoUrl = video
		end
	end

	if h then
		h:hide()
	end
end

return media
